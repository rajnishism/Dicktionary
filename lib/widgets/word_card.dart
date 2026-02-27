import 'package:flutter/material.dart';

/// Reusable widget for displaying word information in a card
class WordCard extends StatelessWidget {
  final String word;
  final String meaning;
  final int searchCount;
  final String lastSearched;
  final double priorityScore;
  final VoidCallback? onDelete;
  final bool showPriority;

  const WordCard({
    super.key,
    required this.word,
    required this.meaning,
    required this.searchCount,
    required this.lastSearched,
    required this.priorityScore,
    this.onDelete,
    this.showPriority = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade50,
            Colors.blue.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Could show more details or options
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _capitalize(word),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                    if (onDelete != null)
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
                        onPressed: onDelete,
                        tooltip: 'Delete word',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '×$searchCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  meaning,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          lastSearched,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    if (showPriority)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(priorityScore),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Priority: ${priorityScore.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Color _getPriorityColor(double score) {
    if (score > 5) return Colors.red.shade400;
    if (score > 3) return Colors.orange.shade400;
    if (score > 1) return Colors.blue.shade400;
    return Colors.green.shade400;
  }
}
