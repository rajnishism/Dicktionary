import 'package:flutter/material.dart';
import '../models/word_memory.dart';
import '../services/database_service.dart';
import '../widgets/word_card.dart';

/// History screen showing all searched words sorted by priority
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<WordMemory> _words = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final words = await _databaseService.getPrioritizedWords();
      setState(() {
        _words = words;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteWord(WordMemory word) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Word?'),
        content: Text('Remove "${word.word}" from your vocabulary? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && word.id != null) {
      await _databaseService.deleteWord(word.id!);
      setState(() => _words.remove(word));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${word.word}" deleted'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
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
              Colors.blue.shade100,
              Colors.purple.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.deepPurple),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Vocabulary',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          Text(
                            '${_words.length} words learned',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.deepPurple),
                      onPressed: _loadWords,
                    ),
                  ],
                ),
              ),

              // Words List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _words.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.library_books_outlined,
                                  size: 80,
                                  color: Colors.deepPurple.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No words yet',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start searching to build your vocabulary!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadWords,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: _words.length,
                              itemBuilder: (context, index) {
                                final word = _words[index];
                                return Dismissible(
                                  key: ValueKey(word.id ?? word.word),
                                  direction: DismissDirection.startToEnd,
                                  confirmDismiss: (_) async {
                                    await _deleteWord(word);
                                    return false;
                                  },
                                  background: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade400,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.only(left: 24),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Icon(Icons.delete, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                      ],
                                    ),
                                  ),
                                  child: WordCard(
                                    word: word.word,
                                    meaning: word.meaning,
                                    searchCount: word.searchCount,
                                    lastSearched: word.formattedLastSearched,
                                    priorityScore: word.priorityScore,
                                    showPriority: false,
                                    // onDelete: null (hidden)
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
