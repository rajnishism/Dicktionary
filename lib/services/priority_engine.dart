import '../models/word_memory.dart';
import 'database_service.dart';

/// Service for calculating and managing word priority scores
class PriorityEngine {
  final DatabaseService _databaseService = DatabaseService();

  /// Calculate priority score for a given word
  /// Formula: (search_count × 0.7) + (recency_score × 0.3)
  /// recency_score = 1 / (hours_since_last_search + 1)
  double calculatePriorityScore(WordMemory word) {
    return word.priorityScore;
  }

  /// Get words sorted by priority score (highest first)
  Future<List<WordMemory>> getPrioritizedWords({int? limit}) async {
    return await _databaseService.getPrioritizedWords(limit: limit);
  }

  /// Get the next word to show in notification
  /// Returns the word with highest priority score
  Future<WordMemory?> getNextWordForNotification() async {
    final words = await getPrioritizedWords(limit: 1);

    if (words.isEmpty) return null;
    return words.first;
  }

  /// Get top N words by priority
  Future<List<WordMemory>> getTopWords(int count) async {
    return await getPrioritizedWords(limit: count);
  }

  /// Get words that need reinforcement (high search count but not searched recently)
  Future<List<WordMemory>> getWordsNeedingReinforcement() async {
    final allWords = await _databaseService.getAllWords();

    // Filter words that have been searched multiple times but not recently
    final needReinforcement = allWords.where((word) {
      final daysSinceLastSearch = DateTime.now().difference(word.lastSearchedAt).inDays;
      return word.searchCount >= 2 && daysSinceLastSearch >= 3;
    }).toList();

    // Sort by priority score
    needReinforcement.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));

    return needReinforcement;
  }

  /// Get statistics about the vocabulary
  Future<Map<String, dynamic>> getVocabularyStats() async {
    final allWords = await _databaseService.getAllWords();

    if (allWords.isEmpty) {
      return {
        'totalWords': 0,
        'averageSearchCount': 0.0,
        'mostSearchedWord': null,
        'recentlyAddedCount': 0,
      };
    }

    final totalSearches = allWords.fold<int>(0, (sum, word) => sum + word.searchCount);
    final averageSearchCount = totalSearches / allWords.length;

    // Find most searched word
    allWords.sort((a, b) => b.searchCount.compareTo(a.searchCount));
    final mostSearchedWord = allWords.first;

    // Count words added in last 7 days
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final recentlyAddedCount = allWords.where((word) {
      return word.createdAt.isAfter(sevenDaysAgo);
    }).length;

    return {
      'totalWords': allWords.length,
      'averageSearchCount': averageSearchCount,
      'mostSearchedWord': mostSearchedWord,
      'recentlyAddedCount': recentlyAddedCount,
    };
  }
}
