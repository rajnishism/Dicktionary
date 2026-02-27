/// Represents a quiz word from frequently asked word lists (CAT, GRE, GMAT, etc.)
class QuizWord {
  final int? id;
  final String word;
  final String meaning;
  final String example;
  final String category; // CAT, GRE, GMAT, SSC, Banking
  final String difficulty; // Easy, Medium, Hard
  final List<String> options; // 4 MCQ options
  final int correctOption; // Index of correct answer (0-3)

  QuizWord({
    this.id,
    required this.word,
    required this.meaning,
    required this.example,
    required this.category,
    this.difficulty = 'Medium',
    required this.options,
    required this.correctOption,
  });

  /// Convert QuizWord object to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': word,
      'meaning': meaning,
      'example': example,
      'category': category,
      'difficulty': difficulty,
      'options': options.join('|'), // Store as pipe-separated string
      'correct_option': correctOption,
    };
  }

  /// Create QuizWord object from database Map
  factory QuizWord.fromMap(Map<String, dynamic> map) {
    return QuizWord(
      id: map['id'] as int?,
      word: map['word'] as String,
      meaning: map['meaning'] as String,
      example: map['example'] as String,
      category: map['category'] as String,
      difficulty: map['difficulty'] as String? ?? 'Medium',
      options: (map['options'] as String).split('|'),
      correctOption: map['correct_option'] as int,
    );
  }

  /// Create QuizWord from JSON (for loading from assets)
  factory QuizWord.fromJson(Map<String, dynamic> json, String category) {
    return QuizWord(
      word: json['word'] as String,
      meaning: json['meaning'] as String,
      example: json['example'] as String,
      category: category,
      difficulty: json['difficulty'] as String? ?? 'Medium',
      options: (json['options'] as List<dynamic>).cast<String>(),
      correctOption: json['correctOption'] as int,
    );
  }

  @override
  String toString() {
    return 'QuizWord(word: $word, category: $category, difficulty: $difficulty)';
  }
}
