import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/quiz_word.dart';

/// Loads exam word lists from JSON assets (CAT, GRE, GMAT).
/// Used by ExamLibraryScreen to browse and add words to the exam practice queue.
/// Quiz generation is now handled by FifoQuizService.
class ExamQuizService {
  final Random _random = Random();

  static const Map<String, String> _categoryFiles = {
    'CAT': 'assets/words/cat_vocabulary.json',
    'GRE': 'assets/words/gre_vocabulary.json',
    'GMAT': 'assets/words/gmat_vocabulary.json',
  };

  /// Loads all words for the given exam category from JSON assets.
  Future<List<QuizWord>> loadWords(String category) async {
    final path = _categoryFiles[category.toUpperCase()];
    if (path == null) return [];
    try {
      final jsonString = await rootBundle.loadString(path);
      final List<dynamic> jsonData = json.decode(jsonString);
      return jsonData
          .map((item) => QuizWord.fromJson(item as Map<String, dynamic>, category))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Returns the list of available exam categories.
  static List<String> get availableCategories => _categoryFiles.keys.toList();

  /// Generates a random exam quiz (used for quick Exam Quiz without library).
  Future<List<Map<String, dynamic>>> generateExamQuiz({
    required String category,
    int questionCount = 10,
  }) async {
    final words = await loadWords(category);
    if (words.isEmpty) return [];
    words.shuffle(_random);
    final selected = words.take(questionCount).toList();

    return selected.map((word) {
      final options = List<String>.from(word.options);
      final correctMeaning = options[word.correctOption];
      options.shuffle(_random);
      return {
        'wordId': null,
        'word': word.word,
        'correctMeaning': correctMeaning,
        'options': options,
        'correctOption': options.indexOf(correctMeaning),
        'memoryTier': word.difficulty,
        'example': word.example,
        'category': word.category,
        'source': 'exam_browse', // not from queue, no persistence
      };
    }).toList();
  }
}
