import 'dart:async';
import 'package:flutter/material.dart';
import '../models/word_memory.dart';
import '../services/priority_engine.dart';

/// Auto-rotating carousel displaying priority words for passive vocabulary reinforcement
class PriorityWordCarousel extends StatefulWidget {
  const PriorityWordCarousel({super.key});

  @override
  State<PriorityWordCarousel> createState() => _PriorityWordCarouselState();
}

class _PriorityWordCarouselState extends State<PriorityWordCarousel> {
  final PriorityEngine _priorityEngine = PriorityEngine();
  final PageController _pageController = PageController();
  
  List<WordMemory> _priorityWords = [];
  bool _isLoading = true;
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadPriorityWords();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPriorityWords() async {
    try {
      final words = await _priorityEngine.getTopWords(5);
      
      if (mounted) {
        setState(() {
          _priorityWords = words;
          _isLoading = false;
        });

        // Start auto-scroll if we have words
        if (words.isNotEmpty) {
          _startAutoScroll();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_priorityWords.isEmpty || !mounted) {
        timer.cancel();
        return;
      }

      final nextPage = (_currentPage + 1) % _priorityWords.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 140,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_priorityWords.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Priority Words',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple.shade700,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_currentPage + 1}/${_priorityWords.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Carousel
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _priorityWords.length,
              itemBuilder: (context, index) {
                return _buildWordCard(_priorityWords[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordCard(WordMemory word) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade400,
            Colors.purple.shade300,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Word and Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _capitalize(word.word),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${word.searchCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Meaning
            Expanded(
              child: Text(
                word.meaning,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.95),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Priority Score and Last Searched
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_up, color: Colors.amber.shade300, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Priority: ${word.priorityScore.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  word.formattedLastSearched,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
