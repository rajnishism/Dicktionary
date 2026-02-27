import 'package:flutter/material.dart';
import '../models/quiz_word.dart';
import '../services/exam_quiz_service.dart';
import '../services/database_service.dart';

/// Browse exam word lists (CAT / GRE / GMAT) and add words to the
/// personal exam practice queue with a single tap.
class ExamLibraryScreen extends StatefulWidget {
  const ExamLibraryScreen({super.key});

  @override
  State<ExamLibraryScreen> createState() => _ExamLibraryScreenState();
}

class _ExamLibraryScreenState extends State<ExamLibraryScreen>
    with SingleTickerProviderStateMixin {
  final ExamQuizService _examService = ExamQuizService();
  final DatabaseService _db = DatabaseService();

  late TabController _tabController;
  final List<String> _categories = ExamQuizService.availableCategories;

  // Per-category word list cache
  final Map<String, List<QuizWord>> _wordCache = {};
  // Words already in exam queue
  final Set<String> _inQueue = {};

  bool _isLoading = true;
  String _searchQuery = '';

  static final _accent = Colors.deepPurple.shade700;
  static final _accentLight = Colors.deepPurple.shade50;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    // Load all categories in parallel
    await Future.wait(_categories.map((cat) async {
      _wordCache[cat] = await _examService.loadWords(cat);
    }));
    // Load which words are already queued
    final db = await _db.database;
    final rows = await db.query('exam_practice', columns: ['word']);
    for (final r in rows) {
      _inQueue.add((r['word'] as String).toLowerCase());
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _addToQueue(QuizWord word) async {
    await _db.addToExamQueue(
      word: word.word,
      meaning: word.meaning,
      example: word.example,
      category: word.category,
    );
    setState(() => _inQueue.add(word.word.toLowerCase()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '"${word.word}" added to exam practice queue',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.deepPurple.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
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
              Colors.deepPurple.shade100,
              Colors.indigo.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildTabBar(),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: _accent))
                    : TabBarView(
                        controller: _tabController,
                        children: _categories
                            .map((cat) => _buildWordList(cat))
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: _accent),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📚 Exam Library',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _accent,
                  ),
                ),
                Text(
                  'Tap + to add words to your practice queue',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Search words...',
          prefixIcon: Icon(Icons.search, color: _accent),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.deepPurple.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.deepPurple.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _accent, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(10),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: _accent,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: _categories.map((c) => Tab(text: c)).toList(),
        ),
      ),
    );
  }

  Widget _buildWordList(String category) {
    final words = (_wordCache[category] ?? []).where((w) {
      if (_searchQuery.isEmpty) return true;
      return w.word.toLowerCase().contains(_searchQuery) ||
          w.meaning.toLowerCase().contains(_searchQuery);
    }).toList();

    if (words.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty ? 'No words found' : 'No matches for "$_searchQuery"',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: words.length,
      itemBuilder: (context, i) => _buildWordCard(words[i]),
    );
  }

  Widget _buildWordCard(QuizWord word) {
    final inQueue = _inQueue.contains(word.word.toLowerCase());

    Color diffColor;
    switch (word.difficulty) {
      case 'Hard':
        diffColor = Colors.red.shade600;
        break;
      case 'Easy':
        diffColor = Colors.green.shade600;
        break;
      default:
        diffColor = Colors.orange.shade700;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        word.word,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _accent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: diffColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: diffColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          word.difficulty,
                          style: TextStyle(
                            fontSize: 10,
                            color: diffColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    word.meaning,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                  if (word.example.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '"${word.example}"',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Add / Already added button
            inQueue
                ? Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Icon(Icons.check, color: Colors.green.shade600, size: 18),
                  )
                : GestureDetector(
                    onTap: () => _addToQueue(word),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _accentLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.deepPurple.shade300),
                      ),
                      child: Icon(Icons.add, color: _accent, size: 18),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
