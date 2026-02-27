import 'dart:math';
import '../models/word_memory.dart';
import 'database_service.dart';

/// The core memory prediction engine.
///
/// Implements Ebbinghaus-inspired forgetting curve, retrieval strength,
/// and difficulty signals to predict which words need revision.
class MemoryEngine {
  static final MemoryEngine _instance = MemoryEngine._internal();
  final DatabaseService _db = DatabaseService();

  factory MemoryEngine() => _instance;
  MemoryEngine._internal();

  // ─────────────────────────────────────────────
  // Core Prediction Methods
  // ─────────────────────────────────────────────

  /// Computes memory strength for a word.
  /// Higher = stronger memory retention.
  double computeMemoryStrength(WordMemory word) => word.memoryStrength;

  /// Sigmoid-based forget probability [0.0 – 1.0].
  double computeForgetProbability(WordMemory word) => word.forgetProbability;

  /// Final revision priority score (higher = revise sooner).
  double computeRevisionPriority(WordMemory word) => word.revisionPriority;

  // ─────────────────────────────────────────────
  // Adaptive Quiz Selection
  // ─────────────────────────────────────────────

  /// Selects quiz words using the 50/30/20 adaptive composition:
  ///   50% → high-priority (forgetProbability ≥ 0.6)
  ///   30% → medium-priority (0.3 ≤ forgetProbability < 0.6)
  ///   20% → strong words (forgetProbability < 0.3) — retention check
  ///
  /// Falls back gracefully if any tier has fewer words than needed.
  Future<List<WordMemory>> selectQuizWords({int count = 10}) async {
    final allWords = await _db.getWordsByRevisionPriority();

    if (allWords.isEmpty) return [];

    // Partition into tiers
    final highPriority = allWords
        .where((w) => w.forgetProbability >= 0.6)
        .toList();
    final mediumPriority = allWords
        .where((w) => w.forgetProbability >= 0.3 && w.forgetProbability < 0.6)
        .toList();
    final strongWords = allWords
        .where((w) => w.forgetProbability < 0.3)
        .toList();

    // Target counts per tier
    final highTarget = (count * 0.5).ceil();
    final medTarget = (count * 0.3).ceil();
    final strongTarget = count - highTarget - medTarget;

    final selected = <WordMemory>[];
    final rng = Random();

    void pickFrom(List<WordMemory> pool, int n) {
      pool.shuffle(rng);
      selected.addAll(pool.take(n));
    }

    pickFrom(highPriority, highTarget.clamp(0, highPriority.length));
    pickFrom(mediumPriority, medTarget.clamp(0, mediumPriority.length));
    pickFrom(strongWords, strongTarget.clamp(0, strongWords.length));

    // If we still don't have enough, fill from remaining words
    if (selected.length < count) {
      final usedIds = selected.map((w) => w.id).toSet();
      final remaining = allWords
          .where((w) => !usedIds.contains(w.id))
          .toList()
        ..shuffle(rng);
      selected.addAll(remaining.take(count - selected.length));
    }

    selected.shuffle(rng); // Final shuffle so tiers aren't obvious
    return selected;
  }

  // ─────────────────────────────────────────────
  // Revision List
  // ─────────────────────────────────────────────

  /// Returns all words sorted by revision priority (most urgent first).
  Future<List<WordMemory>> getRevisionList() async {
    return _db.getWordsByRevisionPriority();
  }

  // ─────────────────────────────────────────────
  // Word Insight
  // ─────────────────────────────────────────────

  /// Returns a human-readable insight map for a single word.
  Map<String, dynamic> getWordInsight(WordMemory word) {
    final strength = word.memoryStrength;
    final forgetP = word.forgetProbability;
    final priority = word.revisionPriority;

    // Estimate days until the word is "likely forgotten" (forgetP > 0.7)
    // Solve: 0.7 = 1/(1+e^(strength - 0.3*d)) → d = (strength - ln(1/0.7 - 1)) / 0.3
    double? daysUntilForgotten;
    if (forgetP < 0.7) {
      final threshold = (strength - log(1 / 0.7 - 1)) / 0.3;
      daysUntilForgotten = threshold > 0 ? threshold : 0;
    }

    return {
      'memoryStrength': double.parse(strength.toStringAsFixed(2)),
      'forgetProbability': double.parse((forgetP * 100).toStringAsFixed(1)),
      'revisionPriority': double.parse(priority.toStringAsFixed(3)),
      'memoryTier': word.memoryTier,
      'daysUntilForgotten': daysUntilForgotten != null
          ? double.parse(daysUntilForgotten.toStringAsFixed(1))
          : null,
      'correctCount': word.correctCount,
      'wrongCount': word.wrongCount,
      'totalAttempts': word.totalAttempts,
      'searchCount': word.searchCount,
      'daysSinceLastSeen': double.parse(word.daysSinceLastSeen.toStringAsFixed(1)),
    };
  }

  // ─────────────────────────────────────────────
  // Stats
  // ─────────────────────────────────────────────

  /// Returns aggregate memory stats across all words.
  Future<Map<String, dynamic>> getMemoryStats() async {
    final words = await _db.getAllWords();
    if (words.isEmpty) {
      return {
        'totalWords': 0,
        'weakWords': 0,
        'fadingWords': 0,
        'strongWords': 0,
        'averageForgetProbability': 0.0,
        'wordsNeedingRevision': 0,
      };
    }

    final weak = words.where((w) => w.forgetProbability >= 0.6).length;
    final fading = words.where((w) => w.forgetProbability >= 0.3 && w.forgetProbability < 0.6).length;
    final strong = words.where((w) => w.forgetProbability < 0.3).length;
    final avgForget = words.map((w) => w.forgetProbability).reduce((a, b) => a + b) / words.length;

    return {
      'totalWords': words.length,
      'weakWords': weak,
      'fadingWords': fading,
      'strongWords': strong,
      'averageForgetProbability': double.parse((avgForget * 100).toStringAsFixed(1)),
      'wordsNeedingRevision': weak + fading,
    };
  }
}
