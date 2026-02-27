import 'package:flutter/material.dart';
import '../services/fifo_quiz_service.dart';

/// Which quiz mode is active.
enum QuizMode { personal, exam, mixed }

/// Adaptive quiz screen — supports two modes:
/// [QuizMode.personal] uses the memory engine on self-searched words.
/// [QuizMode.exam] uses JSON word lists for CAT / GRE / GMAT.
class QuizScreen extends StatefulWidget {
  final QuizMode mode;
  final String? examCategory;

  const QuizScreen({
    super.key,
    this.mode = QuizMode.personal,
    this.examCategory,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  final FifoQuizService _fifoService = FifoQuizService();

  List<Map<String, dynamic>> _quizQuestions = [];
  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  bool _isLoading = true;
  bool _showFeedback = false;
  int? _selectedOption;
  bool _quizCompleted = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _loadQuiz();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    setState(() => _isLoading = true);
    List<Map<String, dynamic>> questions;

    switch (widget.mode) {
      case QuizMode.exam:
        questions = await _fifoService.getExamQuizBatch(count: 10);
        break;
      case QuizMode.mixed:
        questions = await _fifoService.getMixedQuizBatch(count: 10);
        break;
      case QuizMode.personal:
        questions = await _fifoService.getPersonalQuizBatch(count: 10);
    }

    setState(() {
      _quizQuestions = questions;
      _isLoading = false;
    });
    _fadeController.forward();
  }

  void _selectAnswer(int optionIndex) {
    if (_showFeedback) return;
    setState(() => _selectedOption = optionIndex);
  }

  Future<void> _submitAnswer() async {
    if (_selectedOption == null) return;

    final currentQuestion = _quizQuestions[_currentQuestionIndex];
    final isCorrect = _selectedOption! == (currentQuestion['correctOption'] as int);

    if (isCorrect) _correctAnswers++;

    // FIFO logic: correct → move to end, wrong → stay in place
    await _fifoService.recordAnswer(question: currentQuestion, isCorrect: isCorrect);

    setState(() => _showFeedback = true);
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _quizQuestions.length - 1) {
      _fadeController.reset();
      setState(() {
        _currentQuestionIndex++;
        _selectedOption = null;
        _showFeedback = false;
      });
      _fadeController.forward();
    } else {
      setState(() => _quizCompleted = true);
    }
  }

  void _restartQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _correctAnswers = 0;
      _selectedOption = null;
      _showFeedback = false;
      _quizCompleted = false;
    });
    _loadQuiz();
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
              Colors.deepPurple.shade900,
              Colors.purple.shade700,
              Colors.indigo.shade800,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        widget.mode == QuizMode.exam
                            ? 'Loading ${widget.examCategory ?? 'Exam'} words...'
                            : widget.mode == QuizMode.mixed
                                ? 'Mixing exam & personal words...'
                                : 'Analyzing your memory...',
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : _quizQuestions.isEmpty
                  ? _buildEmptyState()
                  : _quizCompleted
                      ? _buildResultScreen()
                      : FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildQuizContent(),
                        ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Empty State
  // ─────────────────────────────────────────────

  Widget _buildEmptyState() {
    final isExam = widget.mode == QuizMode.exam;
    final isMixed = widget.mode == QuizMode.mixed;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology_outlined, size: 72, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Text(
              isExam ? 'Exam Queue is Empty!' : 'No Words to Quiz Yet!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isExam
                  ? 'Go to the Exam Library and tap + on words\nyou want to practice.'
                  : isMixed
                      ? 'Search some words first, or add exam words\nfrom the Exam Library.'
                      : 'Search and look up words first.\nThey will be added to your practice queue.',
              style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isExam ? 'Go to Exam Library' : 'Go Search Words',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Quiz Content
  // ─────────────────────────────────────────────

  Widget _buildQuizContent() {
    final currentQuestion = _quizQuestions[_currentQuestionIndex];
    final options = currentQuestion['options'] as List<dynamic>;
    final correctOption = currentQuestion['correctOption'] as int;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Question ${_currentQuestionIndex + 1} of ${_quizQuestions.length}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_currentQuestionIndex + 1) / _quizQuestions.length,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.withOpacity(0.5)),
                ),
                child: Text(
                  '✓ $_correctAnswers',
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'What does this word mean?',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentQuestion['word'] as String,
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                          letterSpacing: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Options
                ...List.generate(options.length, (index) {
                  return _buildOptionTile(
                    index: index,
                    text: options[index] as String,
                    correctOption: correctOption,
                  );
                }),

                const SizedBox(height: 16),

                // Feedback card
                if (_showFeedback) _buildFeedbackCard(currentQuestion),

                const SizedBox(height: 20),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _showFeedback ? _nextQuestion : (_selectedOption != null ? _submitAnswer : null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.deepPurple.shade900,
                      disabledBackgroundColor: Colors.white24,
                      disabledForegroundColor: Colors.white38,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                      _showFeedback
                          ? (_currentQuestionIndex < _quizQuestions.length - 1 ? 'Next Question →' : 'View Results')
                          : 'Submit Answer',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildOptionTile({
    required int index,
    required String text,
    required int correctOption,
  }) {
    final isSelected = _selectedOption == index;
    final isCorrect = index == correctOption;

    Color bgColor = Colors.white;
    Color borderColor = Colors.grey.shade200;
    Color textColor = Colors.grey.shade800;
    Widget? trailingIcon;

    if (_showFeedback) {
      if (isCorrect) {
        bgColor = Colors.green.shade50;
        borderColor = Colors.green;
        textColor = Colors.green.shade800;
        trailingIcon = const Icon(Icons.check_circle, color: Colors.green);
      } else if (isSelected && !isCorrect) {
        bgColor = Colors.red.shade50;
        borderColor = Colors.red;
        textColor = Colors.red.shade800;
        trailingIcon = const Icon(Icons.cancel, color: Colors.red);
      }
    } else if (isSelected) {
      bgColor = Colors.deepPurple.shade50;
      borderColor = Colors.deepPurple;
      textColor = Colors.deepPurple.shade800;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _selectAnswer(index),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: borderColor.withOpacity(0.15),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index),
                    style: TextStyle(fontWeight: FontWeight.bold, color: borderColor),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    color: textColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (trailingIcon != null) trailingIcon,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> question) {
    final isCorrect = _selectedOption! == (question['correctOption'] as int);
    final source = question['source'] as String? ?? 'personal';
    final feedbackNote = isCorrect
        ? (source == 'personal' || source == 'mixed')
            ? 'Word moved to end of your queue ✓'
            : 'Exam word moved to end of queue ✓'
        : 'Word stays in queue — you\'ll see it again next session';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCorrect ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCorrect ? Icons.emoji_events : Icons.lightbulb_outline,
            color: isCorrect ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCorrect ? 'Correct!' : 'Correct answer:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCorrect ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feedbackNote,
                  style: TextStyle(
                    fontSize: 11,
                    color: isCorrect ? Colors.green.shade600 : Colors.orange.shade600,
                  ),
                ),
                if (!isCorrect) ...[
                  const SizedBox(height: 4),
                  Text(
                    question['correctMeaning'] as String,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Results Screen
  // ─────────────────────────────────────────────

  Widget _buildResultScreen() {
    final score = _fifoService.calculateScore(
      totalQuestions: _quizQuestions.length,
      correctAnswers: _correctAnswers,
    );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.emoji_events, size: 72, color: Colors.amber),
                  const SizedBox(height: 16),
                  const Text(
                    'Quiz Complete!',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    score['message'] as String,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildScoreStat('Score', '${score['correctAnswers']}/${score['totalQuestions']}', Colors.green),
                      _buildScoreStat('Accuracy', '${score['percentage']}%', Colors.blue),
                      _buildScoreStat('Grade', score['grade'] as String, Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.psychology, color: Colors.deepPurple, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your answers updated the memory model. Wrong answers will be prioritized next time.',
                            style: TextStyle(fontSize: 12, color: Colors.deepPurple),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Go Back'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _restartQuiz,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Try Again'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      ],
    );
  }
}
