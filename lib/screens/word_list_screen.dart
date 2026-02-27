import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/quiz_word.dart';
import '../services/database_service.dart';

/// Learn screen — browse exam word lists (CAT / GRE / GMAT),
/// swipe right to mark as Learned (adds to exam practice queue),
/// swipe left to skip.
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final DatabaseService _db = DatabaseService();

  String _selectedCategory = 'CAT';
  List<QuizWord> _words = [];
  List<QuizWord> _filteredWords = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // Words already in exam queue
  final Set<String> _learnedWords = {};

  static const _categories = ['CAT', 'GRE', 'GMAT'];

  @override
  void initState() {
    super.initState();
    _loadAll();
    _searchController.addListener(_filterWords);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    await _loadWords();
    await _loadLearnedWords();
    _filterWords();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadWords() async {
    try {
      final cat = _selectedCategory.toLowerCase();
      final jsonString = await rootBundle.loadString('assets/words/${cat}_vocabulary.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      final words = jsonData.map((item) => QuizWord.fromJson(item, _selectedCategory)).toList();
      _words = words;
      _filteredWords = words;
    } catch (e) {
      _words = [];
      _filteredWords = [];
    }
  }

  Future<void> _loadLearnedWords() async {
    final db = await _db.database;
    final rows = await db.query('exam_practice', columns: ['word']);
    _learnedWords.clear();
    for (final r in rows) {
      _learnedWords.add((r['word'] as String).toLowerCase());
    }
  }

  void _filterWords() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      final unlearned = _words.where((w) => !_learnedWords.contains(w.word.toLowerCase()));

      _filteredWords = query.isEmpty
          ? unlearned.toList()
          : unlearned.where((w) =>
              w.word.toLowerCase().contains(query) ||
              w.meaning.toLowerCase().contains(query)).toList();
    });
  }

  void _changeCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _searchController.clear();
    });
    _loadAll();
  }

  Future<void> _markAsLearned(QuizWord word) async {
    await _db.addToExamQueue(
      word: word.word,
      meaning: word.meaning,
      example: word.example,
      category: word.category,
    );
    // Note: We don't update state here anymore because onDismissed handles it.
    // If we updated it here, the list would change while Dismissible is animating.
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
              Colors.teal.shade100,
              Colors.cyan.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildCategoryTabs(),
              const SizedBox(height: 12),
              _buildSearchBar(),
              const SizedBox(height: 8),
              _buildWordCount(),
              const SizedBox(height: 4),
              Expanded(child: _buildWordList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.teal),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎓 Learn',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                Text(
                  'Swipe right on a word to mark it as Learned',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: _categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return Expanded(
              child: GestureDetector(
                onTap: () => _changeCategory(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.teal : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isSelected
                        ? [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))]
                        : null,
                  ),
                  child: Text(
                    cat,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.teal.shade700,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search words...',
          prefixIcon: const Icon(Icons.search, color: Colors.teal),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.teal.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.teal.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.teal, width: 2),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () => _searchController.clear(),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildWordCount() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            '${_filteredWords.length} words to learn',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            '← skip  ·  learn →',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildWordList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }
    if (_filteredWords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No words found', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: _filteredWords.length,
      itemBuilder: (context, index) => _buildSwipeableWordCard(_filteredWords[index]),
    );
  }

  Widget _buildSwipeableWordCard(QuizWord word) {
    // Only unlearned words are shown now, so isLearned is effectively false
    return Dismissible(
      key: ValueKey('${word.word}_${_selectedCategory}'),
      direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // Swipe right = Mark as Learned
            await _markAsLearned(word);
            return true;
          } else {
            // Swipe left = skip (move to end)
            return true;
          }
        },
        onDismissed: (direction) {
          if (direction == DismissDirection.startToEnd) {
            // Learned
            setState(() {
              _learnedWords.add(word.word.toLowerCase());
              _filterWords();
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).clearSnackBars();
            }
          } else {
            // Skipped - move to end
            setState(() {
              _words.remove(word);
              _words.add(word);
              _filterWords();
            });
          }
        },
        background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.teal.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text('Learned!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Skip', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward, color: Colors.grey.shade700, size: 28),
          ],
        ),
      ),
      child: _buildWordCard(word),
    );
  }

  Widget _buildWordCard(QuizWord word) {
    Color diffColor;
    switch (word.difficulty.toLowerCase()) {
      case 'easy':
        diffColor = Colors.green.shade600;
        break;
      case 'hard':
        diffColor = Colors.red.shade600;
        break;
      default:
        diffColor = Colors.orange.shade700;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Expanded(
              child: Text(
                word.word,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: diffColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: diffColor.withOpacity(0.3)),
              ),
              child: Text(
                word.difficulty,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: diffColor),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            word.meaning,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        children: [
          if (word.example.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.format_quote, color: Colors.teal.shade700, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Example:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    word.example,
                    style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey.shade800),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
