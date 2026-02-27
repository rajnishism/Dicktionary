/// Represents a single quiz attempt for tracking performance
class QuizAttempt {
  final int? id;
  final String word; // The word that was quizzed
  final bool isCorrect; // Whether the answer was correct
  final DateTime attemptedAt;
  final int timeTaken; // Time taken to answer in seconds

  QuizAttempt({
    this.id,
    required this.word,
    required this.isCorrect,
    DateTime? attemptedAt,
    this.timeTaken = 0,
  }) : attemptedAt = attemptedAt ?? DateTime.now();

  /// Convert QuizAttempt object to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': word,
      'is_correct': isCorrect ? 1 : 0,
      'attempted_at': attemptedAt.toIso8601String(),
      'time_taken': timeTaken,
    };
  }

  /// Create QuizAttempt object from database Map
  factory QuizAttempt.fromMap(Map<String, dynamic> map) {
    return QuizAttempt(
      id: map['id'] as int?,
      word: map['word'] as String,
      isCorrect: (map['is_correct'] as int) == 1,
      attemptedAt: DateTime.parse(map['attempted_at'] as String),
      timeTaken: map['time_taken'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'QuizAttempt(word: $word, isCorrect: $isCorrect, attemptedAt: $attemptedAt)';
  }
}
