import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:banksos/core/theme/app_theme.dart';
import 'package:banksos/features/kontribusi/models/question_model.dart';

/// Layar mengerjakan soal secara berurutan dalam satu topik.
class QuizScreen extends StatefulWidget {
  final String topicName;
  final String matkulName;
  final List<QuestionModel> questions;

  const QuizScreen({
    super.key,
    required this.topicName,
    required this.matkulName,
    required this.questions,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  bool _answered = false;
  bool _showResult = false;

  // Jawaban user: index soal → jawaban yang dipilih
  final Map<int, String> _userAnswers = {};

  QuestionModel get _current => widget.questions[_currentIndex];
  bool get _isLast => _currentIndex == widget.questions.length - 1;

  int get _correctCount {
    int count = 0;
    for (int i = 0; i < widget.questions.length; i++) {
      if (_userAnswers[i] == widget.questions[i].correctAnswer) count++;
    }
    return count;
  }

  void _selectAnswer(String answer) {
    if (_answered) return;
    setState(() {
      _userAnswers[_currentIndex] = answer;
      _answered = true;
    });
  }

  void _nextQuestion() {
    if (_isLast) {
      setState(() => _showResult = true);
    } else {
      setState(() {
        _currentIndex++;
        _answered = _userAnswers.containsKey(_currentIndex);
      });
    }
  }

  void _prevQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _answered = _userAnswers.containsKey(_currentIndex);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showResult) return _buildResultScreen();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => _showExitDialog(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.topicName,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              widget.matkulName,
              style: GoogleFonts.nunito(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / widget.questions.length,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 6,
          ),
        ),
      ),
      body: Column(
        children: [
          // --- Progress text & nomor soal ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Soal ${_currentIndex + 1} dari ${widget.questions.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    _DifficultyDot(difficulty: _current.difficulty),
                    const SizedBox(width: 6),
                    Text(
                      _current.difficulty == 'easy'
                          ? 'Mudah'
                          : _current.difficulty == 'medium'
                              ? 'Sedang'
                              : 'Sulit',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- Soal dots navigator ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(widget.questions.length, (i) {
                  final isActive = i == _currentIndex;
                  final isAnswered = _userAnswers.containsKey(i);
                  final isCorrect = isAnswered &&
                      _userAnswers[i] == widget.questions[i].correctAnswer;

                  Color dotColor;
                  if (isActive) {
                    dotColor = AppTheme.primaryDark;
                  } else if (isAnswered) {
                    dotColor =
                        isCorrect ? AppTheme.accentGreen : AppTheme.accentRed;
                  } else {
                    dotColor = Colors.grey.shade300;
                  }

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentIndex = i;
                        _answered = _userAnswers.containsKey(i);
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                        border: isActive
                            ? Border.all(color: AppTheme.primaryDark, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: isActive || isAnswered
                                ? Colors.white
                                : Colors.grey.shade600,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          const Divider(height: 1),

          // --- Konten soal ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: KeyedSubtree(
                  key: ValueKey(_currentIndex),
                  child: _buildQuestionContent(),
                ),
              ),
            ),
          ),

          // --- Bottom nav ---
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildQuestionContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tipe soal badge
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _current.questionType == 'multipleChoice'
                    ? 'Pilihan Ganda'
                    : _current.questionType == 'trueFalse'
                        ? 'Benar / Salah'
                        : 'Essay',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryDark,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Teks pertanyaan
        Text(
          _current.questionText,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            height: 1.6,
          ),
        ),

        const SizedBox(height: 20),

        // Opsi jawaban
        if (_current.questionType == 'multipleChoice' ||
            _current.questionType == 'trueFalse')
          ..._current.options.asMap().entries.map((e) {
            final letter = String.fromCharCode(65 + e.key);
            final option = e.value;
            final userAnswer = _userAnswers[_currentIndex];
            final isSelected = userAnswer == option;
            final isCorrect = option == _current.correctAnswer;

            Color borderColor = AppTheme.divider;
            Color bgColor = Colors.white;
            Color textColor = AppTheme.textPrimary;
            Widget? trailingIcon;

            if (_answered) {
              if (isCorrect) {
                borderColor = AppTheme.accentGreen;
                bgColor = AppTheme.accentGreen.withOpacity(0.08);
                textColor = AppTheme.accentGreen;
                trailingIcon = const Icon(Icons.check_circle_rounded,
                    color: AppTheme.accentGreen, size: 20);
              } else if (isSelected && !isCorrect) {
                borderColor = AppTheme.accentRed;
                bgColor = AppTheme.accentRed.withOpacity(0.08);
                textColor = AppTheme.accentRed;
                trailingIcon = const Icon(Icons.cancel_rounded,
                    color: AppTheme.accentRed, size: 20);
              }
            } else if (isSelected) {
              borderColor = AppTheme.primaryDark;
              bgColor = AppTheme.primaryLight;
            }

            return GestureDetector(
              onTap: () => _selectAnswer(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _answered && isCorrect
                            ? AppTheme.accentGreen
                            : _answered && isSelected && !isCorrect
                                ? AppTheme.accentRed
                                : isSelected
                                    ? AppTheme.primaryDark
                                    : AppTheme.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          letter,
                          style: TextStyle(
                            color: isSelected || (_answered && isCorrect)
                                ? Colors.white
                                : AppTheme.primaryDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: textColor,
                          fontWeight: isSelected || (_answered && isCorrect)
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 8),
                      trailingIcon,
                    ],
                  ],
                ),
              ),
            );
          }),

        // Pembahasan (muncul setelah jawab)
        if (_answered && _current.explanation.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: const Border(
                left: BorderSide(color: AppTheme.primaryDark, width: 4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded,
                        color: AppTheme.primaryDark, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Pembahasan',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _current.explanation,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Jawaban benar (muncul jika salah)
        if (_answered &&
            _userAnswers[_currentIndex] != _current.correctAnswer) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentGreen.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.accentGreen.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: AppTheme.accentGreen, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.nunito(
                          fontSize: 13, color: AppTheme.textSecondary),
                      children: [
                        const TextSpan(text: 'Jawaban benar: '),
                        TextSpan(
                          text: _current.correctAnswer,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accentGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentIndex > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _prevQuestion,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Sebelumnya'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: GoogleFonts.poppins(fontSize: 13),
                ),
              ),
            ),
          if (_currentIndex > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _answered ? _nextQuestion : null,
              icon: Icon(
                _isLast
                    ? Icons.assignment_turned_in_rounded
                    : Icons.arrow_forward_rounded,
                size: 18,
              ),
              label: Text(_isLast ? 'Lihat Hasil' : 'Selanjutnya'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLast
                    ? AppTheme.accentGreen
                    : AppTheme.primaryDark,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade200,
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // Hasil akhir
  // -------------------------------------------------------------------
  Widget _buildResultScreen() {
    final total = widget.questions.length;
    final correct = _correctCount;
    final wrong = total - correct;
    final percentage = (correct / total * 100).round();

    Color scoreColor;
    String scoreEmoji;
    String scoreMessage;

    if (percentage >= 80) {
      scoreColor = AppTheme.accentGreen;
      scoreEmoji = '🎉';
      scoreMessage = 'Luar Biasa!';
    } else if (percentage >= 60) {
      scoreColor = AppTheme.accentOrange;
      scoreEmoji = '💪';
      scoreMessage = 'Cukup Baik!';
    } else {
      scoreColor = AppTheme.accentRed;
      scoreEmoji = '📚';
      scoreMessage = 'Terus Belajar!';
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        automaticallyImplyLeading: false,
        title: Text(
          'Hasil Quiz',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Selesai',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Score card ---
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  scoreEmoji,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 8),
                Text(
                  scoreMessage,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: scoreColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.topicName,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Score circle
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scoreColor.withOpacity(0.1),
                    border: Border.all(color: scoreColor, width: 4),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$percentage%',
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: scoreColor,
                          ),
                        ),
                        Text(
                          '$correct/$total',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ResultStat(
                      label: 'Benar',
                      value: '$correct',
                      color: AppTheme.accentGreen,
                      icon: Icons.check_circle_rounded,
                    ),
                    const SizedBox(width: 16),
                    _ResultStat(
                      label: 'Salah',
                      value: '$wrong',
                      color: AppTheme.accentRed,
                      icon: Icons.cancel_rounded,
                    ),
                    const SizedBox(width: 16),
                    _ResultStat(
                      label: 'Total',
                      value: '$total',
                      color: AppTheme.primaryDark,
                      icon: Icons.quiz_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // --- Review jawaban ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Review Jawaban',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: widget.questions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final q = widget.questions[index];
                final userAnswer = _userAnswers[index] ?? '(tidak dijawab)';
                final isCorrect = userAnswer == q.correctAnswer;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCorrect
                          ? AppTheme.accentGreen.withOpacity(0.3)
                          : AppTheme.accentRed.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? AppTheme.accentGreen
                              : AppTheme.accentRed,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            isCorrect
                                ? Icons.check_rounded
                                : Icons.close_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${index + 1}. ${q.questionText}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            if (!isCorrect) ...[
                              Text(
                                'Jawabanmu: $userAnswer',
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  color: AppTheme.accentRed,
                                ),
                              ),
                              Text(
                                'Jawaban benar: ${q.correctAnswer}',
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  color: AppTheme.accentGreen,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ] else
                              Text(
                                'Jawaban: ${q.correctAnswer}',
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  color: AppTheme.accentGreen,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // --- Tombol ulangi ---
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 0, 16, MediaQuery.of(context).padding.bottom + 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Kembali'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentIndex = 0;
                        _answered = false;
                        _showResult = false;
                        _userAnswers.clear();
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Ulangi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Keluar dari Quiz?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          'Progresmu akan hilang jika keluar sekarang.',
          style: GoogleFonts.nunito(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Lanjutkan Quiz',
              style: GoogleFonts.poppins(color: AppTheme.primaryDark),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentRed),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------
// Helper widgets
// -------------------------------------------------------------------
class _ResultStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _ResultStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyDot extends StatelessWidget {
  final String difficulty;

  const _DifficultyDot({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final color = difficulty == 'easy'
        ? AppTheme.accentGreen
        : difficulty == 'medium'
            ? AppTheme.accentOrange
            : AppTheme.accentRed;

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}