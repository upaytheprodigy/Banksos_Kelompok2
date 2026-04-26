import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:banksos/core/theme/app_theme.dart';
import 'package:banksos/features/kontribusi/models/question_model.dart';
import 'package:banksos/features/kontribusi/widgets/status_chip.dart';

/// UC-03 (Seruni): Form Submit Soal Baru
/// Stepper 3 langkah: Informasi Soal → Jawaban → Pembahasan & Preview
class SubmitSoalScreen extends StatefulWidget {
  final bool isEditMode;
  const SubmitSoalScreen({super.key, this.isEditMode = false});

  @override
  State<SubmitSoalScreen> createState() => _SubmitSoalScreenState();
}

class _SubmitSoalScreenState extends State<SubmitSoalScreen> {
  int _currentStep = 0;

  // --- Controllers ---
  final _questionTextCtrl = TextEditingController();
  final _explanationCtrl = TextEditingController();
  final _tagInputCtrl = TextEditingController();
  final List<TextEditingController> _optionCtrls = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  // --- Form values ---
  String _questionType = 'multipleChoice';
  String _difficulty = 'medium';
  String _department = 'TI';
  int _correctOptionIndex = 0; // for multipleChoice
  bool _trueFalseAnswer = true; // for trueFalse
  String _essayAnswer = '';
  final List<String> _tags = [];

  // --- Validation ---
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

  static const List<String> _departments = ['TI', 'AK', 'MN', 'EL', 'ME', 'KI'];
  static const List<String> _suggestedTags = [
    'Algoritma', 'Basis Data', 'Jaringan', 'OOP', 'Pemrograman',
    'Python', 'Java', 'SQL', 'Matematika Diskrit', 'Kalkulus',
    'Sorting', 'Tree', 'Graph', 'Kompleksitas', 'Linux',
  ];

  @override
  void dispose() {
    _questionTextCtrl.dispose();
    _explanationCtrl.dispose();
    _tagInputCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  // -------------------------------------------------------------------
  // Step navigation
  // -------------------------------------------------------------------
  void _nextStep() {
    if (_currentStep == 0) {
      if (!(_step1Key.currentState?.validate() ?? false)) return;
    } else if (_currentStep == 1) {
      if (!_validateStep2()) return;
    }
    setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  bool _validateStep2() {
    if (_questionType == 'multipleChoice') {
      for (int i = 0; i < _optionCtrls.length; i++) {
        if (_optionCtrls[i].text.trim().isEmpty) {
          _showSnack('Isi semua opsi jawaban terlebih dahulu!');
          return false;
        }
      }
    }
    return true;
  }

  // -------------------------------------------------------------------
  // Submit
  // -------------------------------------------------------------------
  void _saveDraft() {
    // TODO: simpan ke Hive dengan status DRAFT, lalu SyncQueue
    Navigator.pop(context);
    _showSnackSuccess('Soal tersimpan sebagai Draft!');
  }

  void _submitForReview() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Ajukan untuk Review?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          'Soal akan dikirim ke Reviewer jurusan $_department. '
          'Kamu tidak dapat mengeditnya selama proses review.',
          style: GoogleFonts.nunito(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              // TODO: ubah status ke PENDING_REVIEW, tambah ke SyncQueue
              _showSnackSuccess('Soal berhasil diajukan untuk review!');
            },
            child: const Text('Ya, Ajukan'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.nunito()),
        backgroundColor: AppTheme.accentRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSnackSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.nunito()),
        backgroundColor: AppTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => _showExitDialog(),
        ),
        title: Text(
          widget.isEditMode ? 'Edit Soal' : 'Buat Soal Baru',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _saveDraft,
            icon: const Icon(Icons.save_outlined, color: Colors.white70, size: 18),
            label: Text(
              'Simpan Draft',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Step indicator ---
          _buildStepIndicator(),

          // --- Content ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(
                  key: ValueKey(_currentStep),
                  child: _buildCurrentStep(),
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

  // -------------------------------------------------------------------
  // Step indicator
  // -------------------------------------------------------------------
  Widget _buildStepIndicator() {
    final steps = ['Informasi Soal', 'Jawaban', 'Pembahasan & Preview'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: steps.asMap().entries.map((e) {
          final idx = e.key;
          final label = e.value;
          final isDone = _currentStep > idx;
          final isActive = _currentStep == idx;

          return Expanded(
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppTheme.accentGreen
                            : isActive
                                ? AppTheme.primaryDark
                                : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 16)
                            : Text(
                                '${idx + 1}',
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.grey.shade400,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w400,
                        color: isActive
                            ? AppTheme.primaryDark
                            : AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                if (idx < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 18),
                      color: isDone
                          ? AppTheme.accentGreen
                          : Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Step content dispatcher
  // -------------------------------------------------------------------
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return const SizedBox();
    }
  }

  // -------------------------------------------------------------------
  // Step 1: Informasi Soal
  // -------------------------------------------------------------------
  Widget _buildStep1() {
    return Form(
      key: _step1Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('1. Informasi Soal', Icons.info_outline_rounded),
          const SizedBox(height: 16),

          // Question text
          TextFormField(
            controller: _questionTextCtrl,
            maxLines: 5,
            maxLength: 500,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Pertanyaan tidak boleh kosong'
                : null,
            decoration: const InputDecoration(
              labelText: 'Teks Pertanyaan *',
              hintText: 'Tulis pertanyaan yang jelas dan spesifik...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),

          // Question type
          _labelText('Tipe Soal *'),
          const SizedBox(height: 8),
          Row(
            children: [
              _typeOption('multipleChoice', 'Pilihan Ganda',
                  Icons.format_list_bulleted_rounded),
              const SizedBox(width: 8),
              _typeOption(
                  'trueFalse', 'Benar/Salah', Icons.check_circle_outline_rounded),
              const SizedBox(width: 8),
              _typeOption('essay', 'Essay', Icons.article_rounded),
            ],
          ),
          const SizedBox(height: 16),

          // Difficulty
          _labelText('Tingkat Kesulitan *'),
          const SizedBox(height: 8),
          Row(
            children: [
              _diffOption('easy', 'Mudah', AppTheme.accentGreen),
              const SizedBox(width: 8),
              _diffOption('medium', 'Sedang', AppTheme.accentOrange),
              const SizedBox(width: 8),
              _diffOption('hard', 'Sulit', AppTheme.accentRed),
            ],
          ),
          const SizedBox(height: 16),

          // Department
          DropdownButtonFormField<String>(
            value: _department,
            decoration: const InputDecoration(
              labelText: 'Jurusan Target *',
              prefixIcon: Icon(Icons.school_rounded),
            ),
            items: _departments.map((d) {
              return DropdownMenuItem(
                value: d,
                child: Text(d, style: GoogleFonts.poppins(fontSize: 14)),
              );
            }).toList(),
            onChanged: (v) => setState(() => _department = v!),
          ),
          const SizedBox(height: 16),

          // Tags
          _labelText('Tag / Kategori'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ..._tags.map(
                (t) => TagChip(
                  tag: t,
                  deletable: true,
                  onDelete: () => setState(() => _tags.remove(t)),
                ),
              ),
              GestureDetector(
                onTap: _showTagPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primaryDark),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded,
                          size: 14, color: AppTheme.primaryDark),
                      const SizedBox(width: 4),
                      Text(
                        'Tambah Tag',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: AppTheme.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _typeOption(String value, String label, IconData icon) {
    final selected = _questionType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _questionType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.primaryDark : AppTheme.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? Colors.white : AppTheme.textSecondary,
                  size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  color: selected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _diffOption(String value, String label, Color color) {
    final selected = _difficulty == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _difficulty = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : AppTheme.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: selected ? Colors.white : AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTagPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilih Tag',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggestedTags.map((t) {
                final selected = _tags.contains(t);
                return FilterChip(
                  label: Text(t),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _tags.add(t);
                      } else {
                        _tags.remove(t);
                      }
                    });
                  },
                  selectedColor: AppTheme.primaryLight,
                  checkmarkColor: AppTheme.primaryDark,
                  labelStyle: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppTheme.primaryDark : AppTheme.textPrimary,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Selesai'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Step 2: Jawaban
  // -------------------------------------------------------------------
  Widget _buildStep2() {
    return Form(
      key: _step2Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('2. Pilihan Jawaban', Icons.check_circle_outline_rounded),
          const SizedBox(height: 16),

          if (_questionType == 'multipleChoice') _buildMultipleChoice(),
          if (_questionType == 'trueFalse') _buildTrueFalse(),
          if (_questionType == 'essay') _buildEssay(),
        ],
      ),
    );
  }

  Widget _buildMultipleChoice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 16, color: AppTheme.primaryDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ketuk radio button di sebelah kiri untuk menandai jawaban yang benar.',
                  style: GoogleFonts.nunito(
                      fontSize: 12, color: AppTheme.primaryDark),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._optionCtrls.asMap().entries.map((e) {
          final idx = e.key;
          final ctrl = e.value;
          final letter = String.fromCharCode(65 + idx);
          final isCorrect = _correctOptionIndex == idx;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isCorrect
                  ? AppTheme.accentGreen.withOpacity(0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCorrect ? AppTheme.accentGreen : AppTheme.divider,
                width: isCorrect ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Radio<int>(
                  value: idx,
                  groupValue: _correctOptionIndex,
                  onChanged: (v) => setState(() => _correctOptionIndex = v!),
                  activeColor: AppTheme.accentGreen,
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCorrect ? AppTheme.accentGreen : AppTheme.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      letter,
                      style: TextStyle(
                        color: isCorrect ? Colors.white : AppTheme.primaryDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: ctrl,
                    decoration: InputDecoration(
                      hintText: 'Opsi $letter',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                    ),
                    style: GoogleFonts.nunito(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTrueFalse() {
    return Column(
      children: [
        _trueFalseOption(true, 'Benar', Icons.check_circle_rounded,
            AppTheme.accentGreen),
        const SizedBox(height: 12),
        _trueFalseOption(false, 'Salah', Icons.cancel_rounded, AppTheme.accentRed),
      ],
    );
  }

  Widget _trueFalseOption(
      bool value, String label, IconData icon, Color color) {
    final selected = _trueFalseAnswer == value;
    return GestureDetector(
      onTap: () => setState(() => _trueFalseAnswer = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : AppTheme.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? color : Colors.grey, size: 28),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: selected ? color : AppTheme.textSecondary,
              ),
            ),
            const Spacer(),
            if (selected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Jawaban Benar',
                  style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEssay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelText('Model Jawaban (Kunci Jawaban) *'),
        const SizedBox(height: 8),
        TextFormField(
          maxLines: 5,
          onChanged: (v) => _essayAnswer = v,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Kunci jawaban tidak boleh kosong'
              : null,
          decoration: const InputDecoration(
            hintText:
                'Tulis model jawaban yang akan digunakan sebagai referensi penilaian...',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        _labelText('Rubrik Penilaian (Opsional)'),
        const SizedBox(height: 8),
        TextFormField(
          maxLines: 3,
          decoration: const InputDecoration(
            hintText:
                'Contoh: Nilai 4 jika menyebutkan 3 poin, nilai 2 jika hanya 1 poin...',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // Step 3: Pembahasan & Preview
  // -------------------------------------------------------------------
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('3. Pembahasan & Preview', Icons.preview_rounded),
        const SizedBox(height: 16),

        // Penjelasan
        TextFormField(
          controller: _explanationCtrl,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Pembahasan (Opsional tapi disarankan)',
            hintText:
                'Jelaskan mengapa jawaban tersebut benar, konsep yang terlibat, dll.',
            alignLabelWithHint: true,
          ),
        ),

        const SizedBox(height: 24),

        // Preview
        Row(
          children: [
            const Icon(Icons.visibility_rounded,
                color: AppTheme.primaryDark, size: 18),
            const SizedBox(width: 8),
            Text(
              'Preview Soal',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildPreviewCard(),
      ],
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _department,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
              DifficultyChip(difficulty: _difficulty),
              ..._tags.take(2).map((t) => TagChip(tag: t)),
            ],
          ),
          const SizedBox(height: 12),

          // Question text
          Text(
            _questionTextCtrl.text.isEmpty
                ? '(Teks pertanyaan akan tampil di sini)'
                : _questionTextCtrl.text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.6,
              color: _questionTextCtrl.text.isEmpty
                  ? AppTheme.textSecondary
                  : AppTheme.textPrimary,
            ),
          ),

          if (_questionType == 'multipleChoice' &&
              _optionCtrls.any((c) => c.text.isNotEmpty)) ...[
            const SizedBox(height: 12),
            ..._optionCtrls.asMap().entries.map((e) {
              if (e.value.text.isEmpty) return const SizedBox();
              final letter = String.fromCharCode(65 + e.key);
              final isCorrect = _correctOptionIndex == e.key;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? AppTheme.accentGreen.withOpacity(0.08)
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCorrect ? AppTheme.accentGreen : AppTheme.divider,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isCorrect ? AppTheme.accentGreen : AppTheme.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          letter,
                          style: TextStyle(
                            color: isCorrect ? Colors.white : AppTheme.primaryDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.value.text,
                        style: GoogleFonts.nunito(fontSize: 13),
                      ),
                    ),
                    if (isCorrect)
                      const Icon(Icons.check_circle_rounded,
                          color: AppTheme.accentGreen, size: 16),
                  ],
                ),
              );
            }),
          ],

          if (_questionType == 'trueFalse') ...[
            const SizedBox(height: 8),
            Text(
              'Jawaban: ${_trueFalseAnswer ? 'Benar ✓' : 'Salah ✓'}',
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: AppTheme.accentGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],

          if (_explanationCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(8),
                border: const Border(
                  left: BorderSide(color: AppTheme.primaryDark, width: 3),
                ),
              ),
              child: Text(
                _explanationCtrl.text,
                style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // Bottom navigation
  // -------------------------------------------------------------------
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
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _prevStep,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Kembali'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _currentStep < 2
                ? ElevatedButton.icon(
                    onPressed: _nextStep,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Lanjut'),
                  )
                : ElevatedButton.icon(
                    onPressed: _submitForReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Ajukan Review'),
                  ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------
  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryDark, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _labelText(String text) {
    return Text(
      text,
      style: GoogleFonts.nunito(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary,
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Keluar tanpa menyimpan?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text(
          'Perubahan yang belum disimpan akan hilang. Simpan sebagai draft terlebih dahulu?',
          style: GoogleFonts.nunito(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Lanjut Edit',
                style: GoogleFonts.poppins(color: AppTheme.primaryDark)),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Keluar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _saveDraft();
            },
            child: const Text('Simpan Draft'),
          ),
        ],
      ),
    );
  }
}