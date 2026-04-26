import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:banksos/core/theme/app_theme.dart';
import 'package:banksos/features/kontribusi/models/question_model.dart';
import 'package:banksos/features/soal/screens/quiz_screen.dart';

/// Layar daftar topik per mata kuliah untuk mahasiswa.
/// Mengelompokkan soal APPROVED berdasarkan topicName.
class TopicListScreen extends StatelessWidget {
  final String departmentId;
  final String matkulName;
  final List<QuestionModel> allQuestions;

  const TopicListScreen({
    super.key,
    required this.departmentId,
    required this.matkulName,
    required this.allQuestions,
  });

  /// Hanya soal yang sudah APPROVED dan sesuai matkul ini
  List<QuestionModel> get _approvedQuestions => allQuestions
      .where((q) =>
          q.status == 'APPROVED' &&
          q.departmentId == departmentId &&
          q.matkulName == matkulName)
      .toList();

  /// Kelompokkan soal berdasarkan topicName
  Map<String, List<QuestionModel>> get _topicMap {
    final Map<String, List<QuestionModel>> map = {};
    for (final q in _approvedQuestions) {
      final key = q.topicName.isEmpty ? 'Umum' : q.topicName;
      map.putIfAbsent(key, () => []).add(q);
    }
    return map;
  }

  Color _difficultyColor(List<QuestionModel> questions) {
    final counts = {'easy': 0, 'medium': 0, 'hard': 0};
    for (final q in questions) {
      counts[q.difficulty] = (counts[q.difficulty] ?? 0) + 1;
    }
    if ((counts['hard'] ?? 0) > (counts['easy'] ?? 0)) return AppTheme.accentRed;
    if ((counts['medium'] ?? 0) >= (counts['easy'] ?? 0)) return AppTheme.accentOrange;
    return AppTheme.accentGreen;
  }

  String _difficultyLabel(List<QuestionModel> questions) {
    final counts = {'easy': 0, 'medium': 0, 'hard': 0};
    for (final q in questions) {
      counts[q.difficulty] = (counts[q.difficulty] ?? 0) + 1;
    }
    if ((counts['hard'] ?? 0) > (counts['easy'] ?? 0)) return 'Sulit';
    if ((counts['medium'] ?? 0) >= (counts['easy'] ?? 0)) return 'Sedang';
    return 'Mudah';
  }

  @override
  Widget build(BuildContext context) {
    final topicMap = _topicMap;
    final topicEntries = topicMap.entries.toList();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              matkulName,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              departmentId,
              style: GoogleFonts.nunito(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: topicEntries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada soal tersedia\nuntuk mata kuliah ini',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header info ---
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.topic_rounded,
                            color: AppTheme.primaryDark, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${topicEntries.length} Topik Tersedia',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '${_approvedQuestions.length} soal total',
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
                const Divider(height: 1),

                // --- List topik ---
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: topicEntries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final topic = topicEntries[index].key;
                      final questions = topicEntries[index].value;
                      final color = _difficultyColor(questions);
                      final label = _difficultyLabel(questions);

                      return _TopicCard(
                        topicName: topic,
                        questions: questions,
                        difficultyColor: color,
                        difficultyLabel: label,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuizScreen(
                                topicName: topic,
                                matkulName: matkulName,
                                questions: questions,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

// -------------------------------------------------------------------
// Card per topik
// -------------------------------------------------------------------
class _TopicCard extends StatelessWidget {
  final String topicName;
  final List<QuestionModel> questions;
  final Color difficultyColor;
  final String difficultyLabel;
  final VoidCallback onTap;

  const _TopicCard({
    required this.topicName,
    required this.questions,
    required this.difficultyColor,
    required this.difficultyLabel,
    required this.onTap,
  });

  Map<String, int> get _typeCounts {
    final counts = {'multipleChoice': 0, 'trueFalse': 0, 'essay': 0};
    for (final q in questions) {
      counts[q.questionType] = (counts[q.questionType] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final counts = _typeCounts;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.folder_open_rounded,
                        color: AppTheme.primaryDark, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      topicName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: AppTheme.textSecondary),
                ],
              ),

              const SizedBox(height: 14),

              // --- Stats row ---
              Row(
                children: [
                  // Jumlah soal
                  _StatBadge(
                    icon: Icons.quiz_rounded,
                    label: '${questions.length} soal',
                    color: AppTheme.primaryDark,
                  ),
                  const SizedBox(width: 8),
                  // Kesulitan
                  _StatBadge(
                    icon: Icons.bar_chart_rounded,
                    label: difficultyLabel,
                    color: difficultyColor,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // --- Tipe soal breakdown ---
              Wrap(
                spacing: 6,
                children: [
                  if ((counts['multipleChoice'] ?? 0) > 0)
                    _TypeChip(
                      icon: Icons.format_list_bulleted_rounded,
                      label: '${counts['multipleChoice']} PG',
                    ),
                  if ((counts['trueFalse'] ?? 0) > 0)
                    _TypeChip(
                      icon: Icons.check_circle_outline_rounded,
                      label: '${counts['trueFalse']} B/S',
                    ),
                  if ((counts['essay'] ?? 0) > 0)
                    _TypeChip(
                      icon: Icons.article_rounded,
                      label: '${counts['essay']} Essay',
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // --- Tombol mulai ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Mulai Kerjakan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TypeChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppTheme.textSecondary),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}