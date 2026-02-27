import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/word_memory.dart';

/// Mobile/Desktop database service using standard sqflite.
/// v4: adds queue_position to word_memory + new exam_practice table.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'vocabulary_memory.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ─────────────────────────────────────────────
  // Schema
  // ─────────────────────────────────────────────

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE word_memory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT UNIQUE NOT NULL,
        meaning TEXT NOT NULL,
        search_count INTEGER NOT NULL DEFAULT 1,
        last_searched_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_difficult INTEGER NOT NULL DEFAULT 0,
        is_important INTEGER NOT NULL DEFAULT 0,
        added_to_quiz INTEGER NOT NULL DEFAULT 0,
        correct_count INTEGER NOT NULL DEFAULT 0,
        wrong_count INTEGER NOT NULL DEFAULT 0,
        total_attempts INTEGER NOT NULL DEFAULT 0,
        first_seen_at TEXT,
        queue_position INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE exam_practice (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT UNIQUE NOT NULL,
        meaning TEXT NOT NULL,
        example TEXT NOT NULL,
        category TEXT NOT NULL,
        queue_position INTEGER NOT NULL DEFAULT 0,
        correct_count INTEGER NOT NULL DEFAULT 0,
        wrong_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE quiz_words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT UNIQUE NOT NULL,
        meaning TEXT NOT NULL,
        example TEXT NOT NULL,
        category TEXT NOT NULL,
        difficulty TEXT NOT NULL DEFAULT 'Medium',
        options TEXT NOT NULL,
        correct_option INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE quiz_attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT NOT NULL,
        is_correct INTEGER NOT NULL,
        attempted_at TEXT NOT NULL,
        time_taken INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE word_memory ADD COLUMN is_difficult INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE word_memory ADD COLUMN is_important INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE word_memory ADD COLUMN added_to_quiz INTEGER NOT NULL DEFAULT 0');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS quiz_words (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          word TEXT UNIQUE NOT NULL,
          meaning TEXT NOT NULL,
          example TEXT NOT NULL,
          category TEXT NOT NULL,
          difficulty TEXT NOT NULL DEFAULT 'Medium',
          options TEXT NOT NULL,
          correct_option INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS quiz_attempts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          word TEXT NOT NULL,
          is_correct INTEGER NOT NULL,
          attempted_at TEXT NOT NULL,
          time_taken INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE word_memory ADD COLUMN correct_count INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE word_memory ADD COLUMN wrong_count INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE word_memory ADD COLUMN total_attempts INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE word_memory ADD COLUMN first_seen_at TEXT');
    }
    if (oldVersion < 4) {
      // Add queue_position; seed from id so existing words keep insertion order
      await db.execute('ALTER TABLE word_memory ADD COLUMN queue_position INTEGER NOT NULL DEFAULT 0');
      await db.execute('UPDATE word_memory SET queue_position = id');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS exam_practice (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          word TEXT UNIQUE NOT NULL,
          meaning TEXT NOT NULL,
          example TEXT NOT NULL,
          category TEXT NOT NULL,
          queue_position INTEGER NOT NULL DEFAULT 0,
          correct_count INTEGER NOT NULL DEFAULT 0,
          wrong_count INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
  }

  // ─────────────────────────────────────────────
  // Personal Word Queue (Track 1)
  // ─────────────────────────────────────────────

  /// Insert new word at end of queue, or move existing word to end.
  Future<WordMemory> insertOrUpdateWordWithQueue(String word, String meaning) async {
    final db = await database;
    final lower = word.toLowerCase();

    final existing = await db.query('word_memory', where: 'word = ?', whereArgs: [lower]);

    // Get current max queue_position
    final maxResult = await db.rawQuery('SELECT MAX(queue_position) as m FROM word_memory');
    final maxPos = (maxResult.first['m'] as int?) ?? 0;

    if (existing.isNotEmpty) {
      final existingWord = WordMemory.fromMap(existing.first);
      final updatedMap = existingWord.copyWithIncrementedSearch().toMap();
      updatedMap['queue_position'] = maxPos + 1; // move to end
      await db.update('word_memory', updatedMap, where: 'id = ?', whereArgs: [existingWord.id]);
      return WordMemory.fromMap({...updatedMap, 'id': existingWord.id});
    } else {
      final newWord = WordMemory(word: lower, meaning: meaning, searchCount: 1);
      final map = newWord.toMap();
      map['queue_position'] = maxPos + 1;
      final id = await db.insert('word_memory', map, conflictAlgorithm: ConflictAlgorithm.replace);
      return WordMemory.fromMap({...map, 'id': id});
    }
  }

  /// Legacy insert (keeps backward compat for code not yet migrated).
  Future<WordMemory> insertOrUpdateWord(String word, String meaning) =>
      insertOrUpdateWordWithQueue(word, meaning);

  /// Returns up to [limit] personal words ordered by queue_position ASC (oldest first).
  Future<List<WordMemory>> getPersonalQueue({int limit = 20}) async {
    final db = await database;
    final maps = await db.query(
      'word_memory',
      orderBy: 'queue_position ASC',
      limit: limit,
    );
    return maps.map(WordMemory.fromMap).toList();
  }

  /// Move a personal word to the end of the queue (correct answer).
  Future<void> movePersonalToEnd(int id) async {
    final db = await database;
    final maxResult = await db.rawQuery('SELECT MAX(queue_position) as m FROM word_memory');
    final maxPos = (maxResult.first['m'] as int?) ?? 0;
    await db.rawUpdate(
      'UPDATE word_memory SET queue_position = ?, correct_count = correct_count + 1, total_attempts = total_attempts + 1 WHERE id = ?',
      [maxPos + 1, id],
    );
  }

  /// Record a wrong answer for a personal word (stays in place).
  Future<void> recordPersonalWrong(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE word_memory SET wrong_count = wrong_count + 1, total_attempts = total_attempts + 1 WHERE id = ?',
      [id],
    );
  }

  // ─────────────────────────────────────────────
  // Exam Practice Queue (Track 2)
  // ─────────────────────────────────────────────

  /// Add a word to the exam practice queue (or move to end if already present).
  Future<void> addToExamQueue({
    required String word,
    required String meaning,
    required String example,
    required String category,
  }) async {
    final db = await database;
    final maxResult = await db.rawQuery('SELECT MAX(queue_position) as m FROM exam_practice');
    final maxPos = (maxResult.first['m'] as int?) ?? 0;

    final existing = await db.query('exam_practice', where: 'word = ?', whereArgs: [word.toLowerCase()]);
    if (existing.isNotEmpty) {
      await db.rawUpdate(
        'UPDATE exam_practice SET queue_position = ? WHERE word = ?',
        [maxPos + 1, word.toLowerCase()],
      );
    } else {
      await db.insert('exam_practice', {
        'word': word.toLowerCase(),
        'meaning': meaning,
        'example': example,
        'category': category,
        'queue_position': maxPos + 1,
        'correct_count': 0,
        'wrong_count': 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  /// Returns up to [limit] exam words ordered by queue_position ASC.
  Future<List<Map<String, dynamic>>> getExamQueue({int limit = 20}) async {
    final db = await database;
    return db.query('exam_practice', orderBy: 'queue_position ASC', limit: limit);
  }

  /// Check if a word is already in the exam practice queue.
  Future<bool> isInExamQueue(String word) async {
    final db = await database;
    final result = await db.query('exam_practice', where: 'word = ?', whereArgs: [word.toLowerCase()]);
    return result.isNotEmpty;
  }

  /// Move an exam word to the end of the queue (correct answer).
  Future<void> moveExamToEnd(int id) async {
    final db = await database;
    final maxResult = await db.rawQuery('SELECT MAX(queue_position) as m FROM exam_practice');
    final maxPos = (maxResult.first['m'] as int?) ?? 0;
    await db.rawUpdate(
      'UPDATE exam_practice SET queue_position = ?, correct_count = correct_count + 1 WHERE id = ?',
      [maxPos + 1, id],
    );
  }

  /// Record a wrong answer for an exam word (stays in place).
  Future<void> recordExamWrong(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE exam_practice SET wrong_count = wrong_count + 1 WHERE id = ?',
      [id],
    );
  }

  /// Count words in exam practice queue.
  Future<int> getExamQueueCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM exam_practice');
    return (result.first['c'] as int?) ?? 0;
  }

  // ─────────────────────────────────────────────
  // Existing Methods (unchanged)
  // ─────────────────────────────────────────────

  Future<List<WordMemory>> getAllWords() async {
    final db = await database;
    final maps = await db.query('word_memory');
    return maps.map(WordMemory.fromMap).toList();
  }

  Future<List<WordMemory>> getPrioritizedWords({int? limit}) async {
    final words = await getAllWords();
    words.sort((a, b) {
      final c = b.priorityScore.compareTo(a.priorityScore);
      return c != 0 ? c : a.createdAt.compareTo(b.createdAt);
    });
    if (limit != null && limit < words.length) return words.sublist(0, limit);
    return words;
  }

  Future<WordMemory?> getWord(String word) async {
    final db = await database;
    final maps = await db.query('word_memory', where: 'word = ?', whereArgs: [word.toLowerCase()]);
    if (maps.isEmpty) return null;
    return WordMemory.fromMap(maps.first);
  }

  Future<int> getWordCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM word_memory');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> deleteWord(int id) async {
    final db = await database;
    await db.delete('word_memory', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllWords() async {
    final db = await database;
    await db.delete('word_memory');
  }

  Future<void> updateWordFlags({
    required int id,
    bool? isDifficult,
    bool? isImportant,
    bool? addedToQuiz,
  }) async {
    final db = await database;
    final updates = <String, dynamic>{};
    if (isDifficult != null) updates['is_difficult'] = isDifficult ? 1 : 0;
    if (isImportant != null) updates['is_important'] = isImportant ? 1 : 0;
    if (addedToQuiz != null) updates['added_to_quiz'] = addedToQuiz ? 1 : 0;
    if (updates.isNotEmpty) {
      await db.update('word_memory', updates, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<List<WordMemory>> getDifficultWords() async {
    final db = await database;
    final maps = await db.query('word_memory', where: 'is_difficult = ?', whereArgs: [1]);
    return maps.map(WordMemory.fromMap).toList();
  }

  Future<List<WordMemory>> getImportantWords() async {
    final db = await database;
    final maps = await db.query('word_memory', where: 'is_important = ?', whereArgs: [1]);
    return maps.map(WordMemory.fromMap).toList();
  }

  Future<List<WordMemory>> getQuizWords() async {
    final db = await database;
    final maps = await db.query('word_memory', where: 'added_to_quiz = ?', whereArgs: [1]);
    return maps.map(WordMemory.fromMap).toList();
  }

  Future<void> updateQuizResult({required int id, required bool isCorrect}) async {
    final db = await database;
    if (isCorrect) {
      await db.rawUpdate(
        'UPDATE word_memory SET correct_count = correct_count + 1, total_attempts = total_attempts + 1 WHERE id = ?',
        [id],
      );
    } else {
      await db.rawUpdate(
        'UPDATE word_memory SET wrong_count = wrong_count + 1, total_attempts = total_attempts + 1 WHERE id = ?',
        [id],
      );
    }
  }

  Future<List<WordMemory>> getWordsByRevisionPriority() async {
    final words = await getAllWords();
    words.sort((a, b) => b.revisionPriority.compareTo(a.revisionPriority));
    return words;
  }

  Future<void> markAsLearned(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE word_memory SET correct_count = correct_count + 5, total_attempts = total_attempts + 5 WHERE id = ?',
      [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
