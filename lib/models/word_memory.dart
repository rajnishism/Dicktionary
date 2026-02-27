import 'dart:math';
import 'package:intl/intl.dart';

/// Represents a word entry in the user's personal vocabulary memory.
/// Includes Ebbinghaus-inspired memory strength and forget probability.
class WordMemory {
  final int? id;
  final String word;
  final String meaning;
  final int searchCount;
  final DateTime lastSearchedAt;
  final DateTime createdAt;
  final bool isDifficult;
  final bool isImportant;
  final bool addedToQuiz;

  // --- Quiz performance tracking ---
  final int correctCount;
  final int wrongCount;
  final int totalAttempts;
  final DateTime firstSeenAt;

  WordMemory({
    this.id,
    required this.word,
    required this.meaning,
    this.searchCount = 1,
    DateTime? lastSearchedAt,
    DateTime? createdAt,
    this.isDifficult = false,
    this.isImportant = false,
    this.addedToQuiz = false,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.totalAttempts = 0,
    DateTime? firstSeenAt,
  })  : lastSearchedAt = lastSearchedAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        firstSeenAt = firstSeenAt ?? createdAt ?? DateTime.now();

  // ─────────────────────────────────────────────
  // Memory Prediction Computed Properties
  // ─────────────────────────────────────────────

  /// Days since this word was last seen/searched.
  double get daysSinceLastSeen {
    return DateTime.now().difference(lastSearchedAt).inMinutes / 1440.0;
  }

  /// Ebbinghaus-inspired memory strength score.
  /// Higher = stronger memory, Lower = likely forgotten.
  ///
  /// Formula:
  ///   (2 × correct) - (1.5 × wrong) - (0.3 × days_since_seen) + (0.2 × total_attempts)
  double get memoryStrength {
    return (2.0 * correctCount)
        - (1.5 * wrongCount)
        - (0.3 * daysSinceLastSeen)
        + (0.2 * totalAttempts);
  }

  /// Sigmoid-based forget probability [0.0 – 1.0].
  /// 1.0 = almost certainly forgotten, 0.0 = strongly remembered.
  double get forgetProbability {
    return 1.0 / (1.0 + exp(memoryStrength));
  }

  /// Difficulty weight amplified by how often the user searched this word.
  double get difficultyWeight {
    return 1.0 + (searchCount * 0.2);
  }

  /// Final revision priority score — higher means revise sooner.
  double get revisionPriority {
    return forgetProbability * difficultyWeight;
  }

  /// Human-readable memory tier label.
  String get memoryTier {
    if (forgetProbability < 0.3) return 'Strong';
    if (forgetProbability < 0.6) return 'Fading';
    return 'Weak';
  }

  // ─────────────────────────────────────────────
  // Legacy priority score (kept for compatibility)
  // ─────────────────────────────────────────────

  /// Legacy priority score used by PriorityEngine.
  double get priorityScore {
    final hoursSinceLastSearch = DateTime.now().difference(lastSearchedAt).inHours;
    final recencyScore = 1.0 / (hoursSinceLastSearch + 1);
    return (searchCount * 0.7) + (recencyScore * 0.3);
  }

  // ─────────────────────────────────────────────
  // Serialization
  // ─────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': word,
      'meaning': meaning,
      'search_count': searchCount,
      'last_searched_at': lastSearchedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'is_difficult': isDifficult ? 1 : 0,
      'is_important': isImportant ? 1 : 0,
      'added_to_quiz': addedToQuiz ? 1 : 0,
      'correct_count': correctCount,
      'wrong_count': wrongCount,
      'total_attempts': totalAttempts,
      'first_seen_at': firstSeenAt.toIso8601String(),
    };
  }

  factory WordMemory.fromMap(Map<String, dynamic> map) {
    final createdAt = DateTime.parse(map['created_at'] as String);
    return WordMemory(
      id: map['id'] as int?,
      word: map['word'] as String,
      meaning: map['meaning'] as String,
      searchCount: map['search_count'] as int,
      lastSearchedAt: DateTime.parse(map['last_searched_at'] as String),
      createdAt: createdAt,
      isDifficult: (map['is_difficult'] as int? ?? 0) == 1,
      isImportant: (map['is_important'] as int? ?? 0) == 1,
      addedToQuiz: (map['added_to_quiz'] as int? ?? 0) == 1,
      correctCount: map['correct_count'] as int? ?? 0,
      wrongCount: map['wrong_count'] as int? ?? 0,
      totalAttempts: map['total_attempts'] as int? ?? 0,
      firstSeenAt: map['first_seen_at'] != null
          ? DateTime.parse(map['first_seen_at'] as String)
          : createdAt,
    );
  }

  // ─────────────────────────────────────────────
  // Copy helpers
  // ─────────────────────────────────────────────

  WordMemory copyWith({
    int? id,
    String? word,
    String? meaning,
    int? searchCount,
    DateTime? lastSearchedAt,
    DateTime? createdAt,
    bool? isDifficult,
    bool? isImportant,
    bool? addedToQuiz,
    int? correctCount,
    int? wrongCount,
    int? totalAttempts,
    DateTime? firstSeenAt,
  }) {
    return WordMemory(
      id: id ?? this.id,
      word: word ?? this.word,
      meaning: meaning ?? this.meaning,
      searchCount: searchCount ?? this.searchCount,
      lastSearchedAt: lastSearchedAt ?? this.lastSearchedAt,
      createdAt: createdAt ?? this.createdAt,
      isDifficult: isDifficult ?? this.isDifficult,
      isImportant: isImportant ?? this.isImportant,
      addedToQuiz: addedToQuiz ?? this.addedToQuiz,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
    );
  }

  WordMemory copyWithIncrementedSearch() {
    return WordMemory(
      id: id,
      word: word,
      meaning: meaning,
      searchCount: searchCount + 1,
      lastSearchedAt: DateTime.now(),
      createdAt: createdAt,
      isDifficult: isDifficult,
      isImportant: isImportant,
      addedToQuiz: addedToQuiz,
      correctCount: correctCount,
      wrongCount: wrongCount,
      totalAttempts: totalAttempts,
      firstSeenAt: firstSeenAt,
    );
  }

  // ─────────────────────────────────────────────
  // Formatting helpers
  // ─────────────────────────────────────────────

  String get formattedLastSearched {
    final now = DateTime.now();
    final difference = now.difference(lastSearchedAt);

    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return DateFormat('MMM d, yyyy').format(lastSearchedAt);
  }

  @override
  String toString() {
    return 'WordMemory(word: $word, memoryTier: $memoryTier, '
        'forgetP: ${(forgetProbability * 100).toStringAsFixed(0)}%, '
        'priority: ${revisionPriority.toStringAsFixed(2)})';
  }
}
