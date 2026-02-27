import 'dart:math';
import '../models/word_memory.dart';
import '../services/database_service.dart';
import '../services/memory_engine.dart';

/// Service for managing quiz functionality.
/// Uses MemoryEngine for adaptive word selection.
class QuizService {
  final DatabaseService _databaseService = DatabaseService();
  final MemoryEngine _memoryEngine = MemoryEngine();
  final Random _random = Random();

  // ─────────────────────────────────────────────
  // Adaptive Quiz Generation
  // ─────────────────────────────────────────────

  /// Generates an adaptive quiz using the memory prediction engine.
  ///
  /// Composition: 50% high-priority · 30% medium · 20% strong (retention check).
  /// Each question is a MCQ with 4 options (1 correct + 3 distractors).
  Future<List<Map<String, dynamic>>> generateAdaptiveQuiz({int questionCount = 10}) async {
    final selectedWords = await _memoryEngine.selectQuizWords(count: questionCount);

    if (selectedWords.isEmpty) return [];

    // We need a pool of all words to generate distractors
    final allWords = await _databaseService.getAllWords();

    return _buildQuizQuestions(selectedWords, allWords);
  }

  /// Legacy fallback: generates quiz from words marked as difficult.
  Future<List<Map<String, dynamic>>> generateQuizFromDifficultWords({int questionCount = 10}) async {
    final difficultWords = await _databaseService.getDifficultWords();
    if (difficultWords.isEmpty) return [];

    final allWords = await _databaseService.getAllWords();
    difficultWords.shuffle(_random);
    final selected = difficultWords.take(questionCount).toList();
    return _buildQuizQuestions(selected, allWords);
  }

  /// Builds MCQ question maps from a list of selected words.
  List<Map<String, dynamic>> _buildQuizQuestions(
    List<WordMemory> selected,
    List<WordMemory> allWords,
  ) {
    final questions = <Map<String, dynamic>>[];

    for (final word in selected) {
      // Distractors: other words' meanings
      final distractors = allWords
          .where((w) => w.word != word.word)
          .map((w) => w.meaning)
          .toList()
        ..shuffle(_random);

      final options = [word.meaning, ...distractors.take(3)];
      options.shuffle(_random);
      final correctIndex = options.indexOf(word.meaning);

      final insight = _memoryEngine.getWordInsight(word);

      questions.add({
        'wordId': word.id,
        'word': word.word,
        'correctMeaning': word.meaning,
        'options': options,
        'correctOption': correctIndex,
        'memoryTier': word.memoryTier,
        'forgetProbability': insight['forgetProbability'],
        'memoryStrength': insight['memoryStrength'],
      });
    }

    return questions;
  }

  // ─────────────────────────────────────────────
  // Answer Checking & Result Persistence
  // ─────────────────────────────────────────────

  /// Checks if the selected answer is correct.
  bool checkAnswer(int selectedOption, int correctOption) {
    return selectedOption == correctOption;
  }

  /// Records a quiz attempt and updates the word's memory model in the DB.
  Future<void> recordQuizAttempt({
    required int? wordId,
    required String word,
    required bool isCorrect,
    int timeTaken = 0,
  }) async {
    // Persist result to update correct/wrong counts
    if (wordId != null) {
      await _databaseService.updateQuizResult(id: wordId, isCorrect: isCorrect);
    }
  }

  // ─────────────────────────────────────────────
  // Scoring
  // ─────────────────────────────────────────────

  Map<String, dynamic> calculateScore({
    required int totalQuestions,
    required int correctAnswers,
  }) {
    final percentage = (correctAnswers / totalQuestions * 100).round();

    String grade;
    String message;

    if (percentage >= 90) {
      grade = 'A+';
      message = 'Excellent! Your memory is strong! 🧠';
    } else if (percentage >= 80) {
      grade = 'A';
      message = 'Great job! Keep reinforcing these words!';
    } else if (percentage >= 70) {
      grade = 'B';
      message = 'Good effort! Review the missed words soon.';
    } else if (percentage >= 60) {
      grade = 'C';
      message = 'Not bad! More practice will strengthen memory.';
    } else {
      grade = 'D';
      message = 'Keep going! Repetition builds retention.';
    }

    return {
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'incorrectAnswers': totalQuestions - correctAnswers,
      'percentage': percentage,
      'grade': grade,
      'message': message,
    };
  }
}
