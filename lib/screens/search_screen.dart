import 'package:flutter/material.dart';
import '../services/dictionary_api.dart';
import '../services/database_service.dart';
import 'quiz_picker_screen.dart';
import 'word_list_screen.dart';
import 'history_screen.dart';

/// Main search screen for looking up word meanings
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DictionaryApiService _apiService = DictionaryApiService();
  final DatabaseService _databaseService = DatabaseService();

  bool _isLoading = false;
  String? _currentWord;
  String? _currentMeaning;
  String? _errorMessage;



  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchWord() async {
    final word = _searchController.text.trim();

    if (word.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a word';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentWord = null;
      _currentMeaning = null;
    });

    try {
      final meaning = await _apiService.getWordMeaning(word);

      // Save to database
      await _databaseService.insertOrUpdateWord(word, meaning);

      setState(() {
        _currentWord = word;
        _currentMeaning = meaning;


        _isLoading = false;
      });

      // Clear search field
      _searchController.clear();
      
      // Dismiss keyboard after search
      FocusScope.of(context).unfocus();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside text field
          FocusScope.of(context).unfocus();
        },
        child: Container(
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
                // Fixed Header and Search Bar
                Container(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '📚 Vocabulary',
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Build your personal dictionary',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.history_rounded, size: 28, color: Colors.deepPurple),
                                  tooltip: 'Your History',
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Search Box
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurple.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search for a word...',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(20),
                              suffixIcon: IconButton(
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.search, color: Colors.deepPurple),
                                onPressed: _isLoading ? null : _searchWord,
                              ),
                            ),
                            onSubmitted: (_) => _searchWord(),
                            textCapitalization: TextCapitalization.none,
                            autocorrect: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable Content Area
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Error Message
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade700),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        if (_errorMessage != null) const SizedBox(height: 16),

                        // Result Card
                        if (_currentWord != null && _currentMeaning != null)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white,
                                    Colors.deepPurple.shade50,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.deepPurple.withOpacity(0.3),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _capitalize(_currentWord!),
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        _currentMeaning!,
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey.shade800,
                                          height: 1.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.green.shade700),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Saved to your vocabulary!',
                                            style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Empty State
                        if (_currentWord == null && _errorMessage == null)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 80),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search,
                                  size: 80,
                                  color: Colors.deepPurple.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Search for a word to get started',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Fixed Bottom Navigation
                Container(
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildNavButton(
                              icon: Icons.quiz,
                              label: 'Quiz',
                              color: Colors.deepPurple,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const QuizPickerScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildNavButton(
                              icon: Icons.school,
                              label: 'Learn',
                              color: Colors.teal,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LearnScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        splashColor: color.withOpacity(0.3),
        highlightColor: color.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
