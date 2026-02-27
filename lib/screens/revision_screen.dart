import 'package:flutter/material.dart';
import '../models/word_memory.dart';
import '../services/memory_engine.dart';
import '../services/database_service.dart';
import 'quiz_screen.dart';

/// Revision Dashboard — orange theme, words sorted by forget probability.
/// Swipe RIGHT on a card to mark it as learned.
class RevisionScreen extends StatefulWidget {
  const RevisionScreen({super.key});

  @override
  State<RevisionScreen> createState() => _RevisionScreenState();
}

class _RevisionScreenState extends State<RevisionScreen> {
  final MemoryEngine _engine = MemoryEngine();
  final DatabaseService _db = DatabaseService();

  List<WordMemory> _words = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  // ── Orange palette (mirrors Words screen but orange) ──────────────────────
  static final _accent       = Colors.orange.shade700;
  static final _accentDark   = Colors.orange.shade800;
  static final _accentLight  = Colors.orange.shade50;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final words = await _engine.getRevisionList();
    final stats = await _engine.getMemoryStats();
    setState(() {
      _words = words;
      _stats = stats;
      _isLoading = false;
    });
  }

  Future<void> _markAsLearned(WordMemory word) async {
    if (word.id == null) return;
    setState(() => _words.removeWhere((w) => w.id == word.id));
    await _db.markAsLearned(word.id!);
    final stats = await _engine.getMemoryStats();
    if (mounted) {
      setState(() => _stats = stats);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '"${word.word}" marked as learned!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 1),
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.white,
            onPressed: _loadData,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.shade100,
              Colors.amber.shade100,
              Colors.yellow.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (!_isLoading && _stats.isNotEmpty) _buildStatsRow(),
              if (!_isLoading && _words.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Row(
                    children: [
                      Icon(Icons.swipe_right_alt, size: 14, color: Colors.green.shade600),
                      const SizedBox(width: 6),
                      Text(
                        'Swipe right on a word to mark it as learned',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: _accent))
                    : _words.isEmpty
                        ? _buildEmptyState()
                        : _buildWordList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Header
  // ─────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: _accentDark),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🧠 Revision Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _accentDark,
                  ),
                ),
                Text(
                  'Words sorted by forget probability',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuizScreen()),
              );
              _loadData();
            },
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Quiz Me'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Stats Row
  // ─────────────────────────────────────────────

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatChip(
                  '${_stats['weakWords']}',
                  'Weak',
                  Colors.red.shade600,
                  Icons.warning_amber_rounded,
                  Colors.red.shade50,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatChip(
                  '${_stats['fadingWords']}',
                  'Fading',
                  Colors.orange.shade700,
                  Icons.hourglass_bottom,
                  Colors.orange.shade50,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatChip(
                  '${_stats['strongWords']}',
                  'Strong',
                  Colors.green.shade700,
                  Icons.verified_rounded,
                  Colors.green.shade50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Avg forget risk: ${_stats['averageForgetProbability']}%',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    String count,
    String label,
    Color color,
    IconData icon,
    Color bgColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              '$count $label',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Word List with Swipe-to-Dismiss
  // ─────────────────────────────────────────────

  Widget _buildWordList() {
    return RefreshIndicator(
      color: _accent,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        itemCount: _words.length,
        itemBuilder: (context, index) {
          final word = _words[index];
          return Dismissible(
            key: ValueKey(word.id ?? word.word),
            direction: DismissDirection.startToEnd,
            confirmDismiss: (_) async {
              return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Mark as Learned?'),
                  content: Text(
                    '"${word.word}" will be moved to the bottom of your revision list.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Yes, I learned it!'),
                    ),
                  ],
                ),
              ) ?? false;
            },
            onDismissed: (_) => _markAsLearned(word),
            background: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade500,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Learned!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            child: _buildWordCard(word, index),
          );
        },
      ),
    );
  }

  Widget _buildWordCard(WordMemory word, int index) {
    final forgetP = word.forgetProbability;
    final tier = word.memoryTier;

    Color tierColor;
    IconData tierIcon;
    Color tierBg;
    Color barColor;

    switch (tier) {
      case 'Weak':
        tierColor = Colors.red.shade700;
        tierIcon = Icons.warning_amber_rounded;
        tierBg = Colors.red.shade50;
        barColor = Colors.red.shade400;
        break;
      case 'Fading':
        tierColor = Colors.orange.shade800;
        tierIcon = Icons.hourglass_bottom;
        tierBg = Colors.orange.shade50;
        barColor = Colors.orange.shade400;
        break;
      default:
        tierColor = Colors.green.shade700;
        tierIcon = Icons.verified_rounded;
        tierBg = Colors.green.shade50;
        barColor = Colors.green.shade400;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Rank badge — orange tint
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _accentLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: _accentDark,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    word.word,
                    style: TextStyle(
                      color: _accentDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Tier badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: tierBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: tierColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tierIcon, size: 12, color: tierColor),
                      const SizedBox(width: 4),
                      Text(
                        tier,
                        style: TextStyle(
                          color: tierColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              word.meaning,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Forget Risk',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
                Text(
                  '${(forgetP * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: tierColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: forgetP.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                minHeight: 6,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                _buildMiniStat(Icons.check_circle_outline, '${word.correctCount}', Colors.green.shade600),
                const SizedBox(width: 14),
                _buildMiniStat(Icons.cancel_outlined, '${word.wrongCount}', Colors.red.shade600),
                const SizedBox(width: 14),
                _buildMiniStat(Icons.search, '${word.searchCount}x', _accent),
                const Spacer(),
                Text(
                  word.formattedLastSearched,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Empty State
  // ─────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology_outlined, size: 80, color: Colors.orange.shade200),
            const SizedBox(height: 20),
            Text(
              'All Caught Up! 🎉',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _accentDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No words need revision right now.\nKeep searching and quizzing to build your vocabulary.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
