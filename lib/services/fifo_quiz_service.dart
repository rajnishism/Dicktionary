import 'dart:math';
import '../services/database_service.dart';
import '../models/word_memory.dart';

/// FIFO-based quiz service for both personal and exam practice tracks.
///
/// Personal Track: words from word_memory ordered by queue_position ASC.
/// Exam Track:     words from exam_practice ordered by queue_position ASC.
/// Mixed Track:    50% personal + 50% exam, interleaved.
///
/// Question map keys:
///   wordId, word, correctMeaning, options, correctOption,
///   source ('personal' | 'exam'), examId (exam only)
class FifoQuizService {
  static final FifoQuizService _instance = FifoQuizService._internal();
  factory FifoQuizService() => _instance;
  FifoQuizService._internal();

  final DatabaseService _db = DatabaseService();
  final Random _rng = Random();

  // ─────────────────────────────────────────────
  // Personal Queue Quiz
  // ─────────────────────────────────────────────

  /// Returns up to [count] questions from the personal FIFO queue.
  /// Oldest words (lowest queue_position) come first.
  Future<List<Map<String, dynamic>>> getPersonalQuizBatch({int count = 10}) async {
    final queueWords = await _db.getPersonalQueue(limit: count);
    if (queueWords.isEmpty) return [];

    // Build distractor pool from ALL personal words
    final allWords = await _db.getAllWords();
    return _buildPersonalQuestions(queueWords, allWords);
  }

  List<Map<String, dynamic>> _buildPersonalQuestions(
    List<WordMemory> selected,
    List<WordMemory> allWords,
  ) {
    final questions = <Map<String, dynamic>>[];
    for (final word in selected) {
      final distractors = allWords
          .where((w) => w.word != word.word)
          .map((w) => w.meaning)
          .toList()
        ..shuffle(_rng);

      final options = [word.meaning, ...distractors.take(3)];
      options.shuffle(_rng);

      questions.add({
        'wordId': word.id,
        'word': word.word,
        'correctMeaning': word.meaning,
        'options': options,
        'correctOption': options.indexOf(word.meaning),
        'source': 'personal',
        'memoryTier': word.memoryTier,
      });
    }
    return questions;
  }

  // ─────────────────────────────────────────────
  // Exam Queue Quiz
  // ─────────────────────────────────────────────

  /// Returns up to [count] questions from the exam practice FIFO queue.
  Future<List<Map<String, dynamic>>> getExamQuizBatch({int count = 10}) async {
    final rows = await _db.getExamQueue(limit: count);
    if (rows.isEmpty) return [];
    return _buildExamQuestions(rows);
  }

  List<Map<String, dynamic>> _buildExamQuestions(List<Map<String, dynamic>> rows) {
    final questions = <Map<String, dynamic>>[];
    // Collect all meanings for distractors
    final allMeanings = rows.map((r) => r['meaning'] as String).toList();

    for (final row in rows) {
      final meaning = row['meaning'] as String;
      final distractors = allMeanings.where((m) => m != meaning).toList()..shuffle(_rng);

      // If fewer than 3 distractors from exam pool, pad with generic ones
      final fallback = ['To increase rapidly', 'A state of confusion', 'To make worse'];
      while (distractors.length < 3) {
        distractors.add(fallback[distractors.length % fallback.length]);
      }

      final options = [meaning, ...distractors.take(3)];
      options.shuffle(_rng);

      questions.add({
        'wordId': null,
        'examId': row['id'] as int,
        'word': row['word'] as String,
        'correctMeaning': meaning,
        'example': row['example'] as String,
        'options': options,
        'correctOption': options.indexOf(meaning),
        'source': 'exam',
        'category': row['category'] as String,
      });
    }
    return questions;
  }

  // ─────────────────────────────────────────────
  // Mixed Queue Quiz
  // ─────────────────────────────────────────────

  /// Returns [count] questions: ~50% personal + ~50% exam, interleaved.
  Future<List<Map<String, dynamic>>> getMixedQuizBatch({int count = 10}) async {
    final half = (count / 2).ceil();

    final personalWords = await _db.getPersonalQueue(limit: half);
    final examRows = await _db.getExamQueue(limit: count - personalWords.length);

    final allPersonal = await _db.getAllWords();
    final personalQs = _buildPersonalQuestions(personalWords, allPersonal);
    final examQs = _buildExamQuestions(examRows);

    // Interleave: personal, exam, personal, exam ...
    final mixed = <Map<String, dynamic>>[];
    final maxLen = personalQs.length > examQs.length ? personalQs.length : examQs.length;
    for (int i = 0; i < maxLen; i++) {
      if (i < personalQs.length) mixed.add(personalQs[i]);
      if (i < examQs.length) mixed.add(examQs[i]);
    }
    return mixed.take(count).toList();
  }

  // ─────────────────────────────────────────────
  // Record Answer (FIFO logic)
  // ─────────────────────────────────────────────

  /// Records the answer and applies FIFO queue logic:
  ///   Correct → word moves to END of its queue.
  ///   Wrong   → word stays in place (will be asked again next session).
  Future<void> recordAnswer({
    required Map<String, dynamic> question,
    required bool isCorrect,
  }) async {
    final source = question['source'] as String;

    if (source == 'personal') {
      final id = question['wordId'] as int?;
      if (id == null) return;
      if (isCorrect) {
        await _db.movePersonalToEnd(id);
      } else {
        await _db.recordPersonalWrong(id);
      }
    } else if (source == 'exam') {
      final id = question['examId'] as int?;
      if (id == null) return;
      if (isCorrect) {
        await _db.moveExamToEnd(id);
      } else {
        await _db.recordExamWrong(id);
      }
    }
  }

  // ─────────────────────────────────────────────
  // Scoring (shared)
  // ─────────────────────────────────────────────

  Map<String, dynamic> calculateScore({
    required int totalQuestions,
    required int correctAnswers,
  }) {
    final pct = totalQuestions == 0 ? 0 : (correctAnswers / totalQuestions * 100).round();
    String grade, message;
    if (pct >= 90) { grade = 'A+'; message = 'Excellent! Your memory is strong! 🧠'; }
    else if (pct >= 80) { grade = 'A'; message = 'Great job! Keep reinforcing these words!'; }
    else if (pct >= 70) { grade = 'B'; message = 'Good effort! Review the missed words soon.'; }
    else if (pct >= 60) { grade = 'C'; message = 'Not bad! More practice will strengthen memory.'; }
    else { grade = 'D'; message = 'Keep going! Repetition builds retention.'; }

    return {
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'incorrectAnswers': totalQuestions - correctAnswers,
      'percentage': pct,
      'grade': grade,
      'message': message,
    };
  }
}
