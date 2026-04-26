import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:banksos/core/theme/app_theme.dart';
import 'package:banksos/features/kontribusi/models/question_model.dart';
import 'package:banksos/features/kontribusi/widgets/status_chip.dart';
import 'package:banksos/features/kontribusi/screens/submit_soal_screen.dart';

/// UC-05 (dari Seruni): Layar Kontribusiku
/// Menampilkan semua soal yang pernah disubmit oleh User, dikelompokkan per status.
class KontribusikuScreen extends StatefulWidget {
  const KontribusikuScreen({super.key});

  @override
  State<KontribusikuScreen> createState() => _KontribusikuScreenState();
}

class _KontribusikuScreenState extends State<KontribusikuScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- Data dummy (nanti diganti dengan Riverpod provider + Hive) ---
  List<QuestionModel> _dummyQuestions = [
    QuestionModel(
      id: '1',
      questionText:
          'Manakah pernyataan yang benar mengenai kompleksitas algoritma Bubble Sort dalam kasus terbaik?',
      questionType: 'multipleChoice',
      options: ['O(n²)', 'O(n log n)', 'O(n)', 'O(1)'],
      correctAnswer: 'O(n)',
      explanation:
          'Dalam kasus terbaik (array sudah terurut), Bubble Sort hanya memerlukan satu pass tanpa ada pertukaran, sehingga kompleksitasnya O(n).',
      difficulty: 'medium',
      tags: ['Algoritma', 'Sorting', 'Kompleksitas'],
      departmentId: 'TI',
      status: 'APPROVED',
      createdBy: 'user_seruni',
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    QuestionModel(
      id: '2',
      questionText:
          'Sebutkan dan jelaskan 3 perbedaan utama antara Primary Key dan Foreign Key dalam basis data relasional!',
      questionType: 'essay',
      options: [],
      correctAnswer:
          'Primary Key: unik di setiap baris, tidak boleh NULL, identitas utama entitas. Foreign Key: mereferensikan PK tabel lain, boleh NULL, menjaga integritas referensial.',
      explanation: '',
      difficulty: 'hard',
      tags: ['Basis Data', 'SQL', 'Relasional'],
      departmentId: 'TI',
      status: 'PENDING_REVIEW',
      createdBy: 'user_seruni',
      updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    QuestionModel(
      id: '3',
      questionText:
          'TCP adalah protokol yang bersifat connectionless. Benar atau salah?',
      questionType: 'trueFalse',
      options: ['Benar', 'Salah'],
      correctAnswer: 'Salah',
      explanation:
          'TCP (Transmission Control Protocol) adalah connection-oriented protocol, bukan connectionless. UDP yang bersifat connectionless.',
      difficulty: 'easy',
      tags: ['Jaringan', 'TCP/IP'],
      departmentId: 'TI',
      status: 'NEEDS_REVISION',
      revisionNote:
          'Tolong tambahkan pembahasan yang lebih detail mengenai perbedaan TCP dan UDP.',
      createdBy: 'user_seruni',
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    QuestionModel(
      id: '4',
      questionText:
          'Apa output dari kode Python berikut: print(type(3/2))?',
      questionType: 'multipleChoice',
      options: ['<class \'int\'>', '<class \'float\'>', '<class \'str\'>', 'Error'],
      correctAnswer: '<class \'float\'>',
      explanation:
          'Dalam Python 3, operasi pembagian (/) selalu menghasilkan float meskipun kedua operan adalah integer.',
      difficulty: 'easy',
      tags: ['Pemrograman', 'Python', 'OOP'],
      departmentId: 'TI',
      status: 'DRAFT',
      createdBy: 'user_seruni',
      updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    QuestionModel(
      id: '5',
      questionText:
          'Manakah yang bukan merupakan prinsip SOLID dalam pemrograman berorientasi objek?',
      questionType: 'multipleChoice',
      options: [
        'Single Responsibility',
        'Open/Closed Principle',
        'Liskov Substitution',
        'Dynamic Binding',
      ],
      correctAnswer: 'Dynamic Binding',
      explanation: '',
      difficulty: 'hard',
      tags: ['OOP', 'Design Pattern'],
      departmentId: 'TI',
      status: 'REJECTED',
      rejectionNote:
          'Soal ini sudah terdapat di bank soal dengan formulasi yang lebih baik. Silakan cek soal ID#TI-OOP-023.',
      createdBy: 'user_seruni',
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  List<QuestionModel> _getByStatus(String status) =>
      _dummyQuestions.where((q) => q.status == status).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draftList = _getByStatus('DRAFT');
    final pendingList = _getByStatus('PENDING_REVIEW');
    final approvedList = _getByStatus('APPROVED');
    final needsActionList = [
      ..._getByStatus('REJECTED'),
      ..._getByStatus('NEEDS_REVISION'),
    ];

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kontribusiku',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Soal yang kamu ajukan',
              style: GoogleFonts.nunito(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
            onPressed: () {
              // TODO: filter dialog
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            _buildTab('Draft', draftList.length),
            _buildTab('Menunggu', pendingList.length),
            _buildTab('Disetujui', approvedList.length),
            _buildTab('Perlu Aksi', needsActionList.length, isAlert: true),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SoalListView(questions: draftList, emptyMessage: 'Tidak ada soal draft'),
          _SoalListView(
              questions: pendingList,
              emptyMessage: 'Tidak ada soal yang menunggu review'),
          _SoalListView(
              questions: approvedList,
              emptyMessage: 'Belum ada soal yang disetujui'),
          _SoalListView(
              questions: needsActionList,
              emptyMessage: 'Tidak ada soal yang memerlukan tindakan'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SubmitSoalScreen(
                onSoalSaved: (newQuestion) {
                  setState(() {
                    _dummyQuestions.add(newQuestion);
                  });
                },
              ),
            ),
          );
        },
        backgroundColor: AppTheme.primaryDark,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Buat Soal Baru',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int count, {bool isAlert = false}) {
    return Tab(
      child: Row(
        children: [
          Text(label),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: isAlert && count > 0
                  ? AppTheme.accentRed
                  : Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------
// Widget daftar soal per tab
// -------------------------------------------------------------------
class _SoalListView extends StatelessWidget {
  final List<QuestionModel> questions;
  final String emptyMessage;

  const _SoalListView({
    required this.questions,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: GoogleFonts.nunito(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: questions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _SoalCard(question: questions[index]);
      },
    );
  }
}

// -------------------------------------------------------------------
// Card soal individual
// -------------------------------------------------------------------
class _SoalCard extends StatelessWidget {
  final QuestionModel question;

  const _SoalCard({required this.question});

  IconData get _typeIcon {
    switch (question.questionType) {
      case 'multipleChoice':
        return Icons.format_list_bulleted_rounded;
      case 'trueFalse':
        return Icons.check_circle_outline_rounded;
      case 'essay':
        return Icons.article_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String get _typeLabel {
    switch (question.questionType) {
      case 'multipleChoice':
        return 'Pilihan Ganda';
      case 'trueFalse':
        return 'Benar/Salah';
      case 'essay':
        return 'Essay';
      default:
        return 'Lainnya';
    }
  }

  String get _timeAgo {
    final diff = DateTime.now().difference(question.updatedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }

  @override
  Widget build(BuildContext context) {
    final bool hasNote = question.revisionNote != null || question.rejectionNote != null;
    final String? note = question.revisionNote ?? question.rejectionNote;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: question.status == 'NEEDS_REVISION'
            ? const BorderSide(color: AppTheme.accentYellow, width: 1.5)
            : question.status == 'REJECTED'
                ? const BorderSide(color: AppTheme.accentRed, width: 1.5)
                : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _showDetailBottomSheet(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header row ---
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _typeIcon,
                      size: 18,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _typeLabel,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          _timeAgo,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(status: question.status),
                ],
              ),

              const SizedBox(height: 12),

              // --- Question text ---
              Text(
                question.questionText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 10),

              // --- Tags & difficulty ---
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryDark.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      question.departmentId,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ),
                  DifficultyChip(difficulty: question.difficulty),
                  ...question.tags.take(2).map((t) => TagChip(tag: t)),
                  if (question.tags.length > 2)
                    TagChip(tag: '+${question.tags.length - 2}'),
                ],
              ),

              // --- Catatan revisi/tolak (jika ada) ---
              if (hasNote && note != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: question.status == 'NEEDS_REVISION'
                        ? AppTheme.accentYellow.withOpacity(0.08)
                        : AppTheme.accentRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      left: BorderSide(
                        color: question.status == 'NEEDS_REVISION'
                            ? AppTheme.accentYellow
                            : AppTheme.accentRed,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        question.status == 'NEEDS_REVISION'
                            ? Icons.info_outline_rounded
                            : Icons.block_rounded,
                        size: 14,
                        color: question.status == 'NEEDS_REVISION'
                            ? AppTheme.accentOrange
                            : AppTheme.accentRed,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          note,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // --- Action buttons for DRAFT / NEEDS_REVISION ---
              if (question.status == 'DRAFT' ||
                  question.status == 'NEEDS_REVISION') ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: edit soal
                        },
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: GoogleFonts.poppins(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showSubmitConfirmDialog(context, question);
                        },
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: Text(
                          question.status == 'NEEDS_REVISION'
                              ? 'Resubmit'
                              : 'Ajukan Review',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: GoogleFonts.poppins(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showSubmitConfirmDialog(BuildContext context, QuestionModel question) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Ajukan untuk Review?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          'Soal ini akan dikirim ke Reviewer jurusan ${question.departmentId}. '
          'Kamu tidak bisa mengeditnya selama dalam proses review.',
          style: GoogleFonts.nunito(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Soal berhasil diajukan untuk review!',
                    style: GoogleFonts.nunito(),
                  ),
                  backgroundColor: AppTheme.accentGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: const Text('Ya, Ajukan'),
          ),
        ],
      ),
    );
  }

  void _showDetailBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      children: [
                        StatusChip(status: question.status),
                        const SizedBox(width: 8),
                        DifficultyChip(difficulty: question.difficulty),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      question.questionText,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.6,
                      ),
                    ),
                    if (question.options.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ...question.options.asMap().entries.map((e) {
                        final letter = String.fromCharCode(65 + e.key);
                        final isCorrect = e.value == question.correctAnswer;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? AppTheme.accentGreen.withOpacity(0.1)