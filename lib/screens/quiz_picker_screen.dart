import 'package:flutter/material.dart';
import 'quiz_screen.dart';

/// Mode selection screen — shown when user taps "Quiz" in the nav bar.
/// Lets the user choose between an exam-specific quiz or their personal adaptive quiz.
class QuizPickerScreen extends StatelessWidget {
  const QuizPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 24, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.deepPurple.shade700),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🎯 Choose Quiz Mode',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple.shade700,
                            ),
                          ),
                          Text(
                            'What would you like to practice?',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── My Words Quiz card ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _QuizModeCard(
                    emoji: '🧠',
                    title: 'My Words Quiz',
                    subtitle: 'Adaptive quiz on words you\'ve searched',
                    description:
                        'Uses the memory engine to pick words you\'re most likely to forget. '
                        'Correct answers strengthen your memory model.',
                    color: Colors.deepPurple,
                    lightColor: Colors.deepPurple.shade50,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const QuizScreen(mode: QuizMode.personal),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Mixed Quiz card ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _QuizModeCard(
                    emoji: '🔀',
                    title: 'Mixed Quiz',
                    subtitle: 'Exam words + your personal vocabulary',
                    description:
                        'Combines 50% frequently asked exam words with 50% of your '
                        'personal words. Best for overall vocabulary development.',
                    color: Colors.orange.shade800,
                    lightColor: Colors.orange.shade50,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const QuizScreen(mode: QuizMode.mixed),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Exam Quiz card ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _QuizModeCard(
                    emoji: '📚',
                    title: 'Exam Quiz',
                    subtitle: 'Practice words from your exam queue',
                    description:
                        'Browse CAT/GRE/GMAT words in the Learn tab, add them to your queue, '
                        'and quiz yourself in order (FIFO).',
                    color: Colors.teal,
                    lightColor: Colors.teal.shade50,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const QuizScreen(mode: QuizMode.exam),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic mode card
// ─────────────────────────────────────────────────────────────────────────────

class _QuizModeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String description;
  final Color color;
  final Color lightColor;

  final VoidCallback onTap;

  const _QuizModeCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
    required this.lightColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: lightColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              description,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5),
            ),

          ],
        ),
      ),
    );
  }
}




