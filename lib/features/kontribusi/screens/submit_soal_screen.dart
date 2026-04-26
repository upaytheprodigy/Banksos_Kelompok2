import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:banksos/core/theme/app_theme.dart';
import 'package:banksos/features/kontribusi/models/question_model.dart';
import 'package:banksos/features/kontribusi/widgets/status_chip.dart';

class SubmitSoalScreen extends StatefulWidget {
  final bool isEditMode;
  final Function(QuestionModel)? onSoalSaved;

  const SubmitSoalScreen({
    super.key,
    this.isEditMode = false,
    this.onSoalSaved,
  });

  @override
  State<SubmitSoalScreen> createState() => _SubmitSoalScreenState();
}

class _SubmitSoalScreenState extends State<SubmitSoalScreen> {
  int _currentStep = 0;

  // --- Controllers ---
  final _questionTextCtrl = TextEditingController();
  final _explanationCtrl = TextEditingController();
  final List<TextEditingController> _optionCtrls = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  // --- Step 0: Konteks Soal ---
  String _department = 'TI';
  String _matkul = '';
  String _topik = '';

  // --- Step 1: Info Soal ---
  String _questionType = 'multipleChoice';
  String _difficulty = 'medium';
  int _correctOptionIndex = 0;
  bool _trueFalseAnswer = true;
  String _essayAnswer = '';
  List<String> _tags = [];

  // --- Keys ---
  final _step0Key = GlobalKey<FormState>();
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

  // --- Data ---
  static const Map<String, List<String>> _matkulByDept = {
    'TI': [
      'Algoritma & Struktur Data',
      'Basis Data',
      'Jaringan Komputer',
      'Pemrograman Berorientasi Objek',
      'Matematika Diskrit',
      'Sistem Operasi',
      'Rekayasa Perangkat Lunak',
      'Pemrograman Web',
      'Pemrograman Mobile',
      'Kecerdasan Buatan',
    ],
    'AK': [
      'Akuntansi Dasar',
      'Perpajakan',
      'Audit',
      'Manajemen Keuangan',
      'Akuntansi Biaya',
    ],
    'MN': [
      'Manajemen Pemasaran',
      'Manajemen SDM',
      'Kewirausahaan',
      'Manajemen Operasi',
    ],
    'EL': [
      'Rangkaian Listrik',
      'Elektronika Dasar',
      'Sistem Digital',
      'Mikrokontroler',
    ],
    'ME': [
      'Mekanika Teknik',
      'Termodinamika',
      'Mesin Konversi Energi',
    ],
    'KI': [
      'Kimia Dasar',
      'Kimia Organik',
      'Proses Industri Kimia',
    ],
  };

  static const List<String> _departments = ['TI', 'AK', 'MN', 'EL', 'ME', 'KI'];

  List<String> get _matkulList => _matkulByDept[_department] ?? [];

  @override
  void initState() {
    super.initState();
    _matkul = _matkulList.isNotEmpty ? _matkulList[0] : '';
  }

  @override
  void dispose() {
    _questionTextCtrl.dispose();
    _explanationCtrl.dispose();
    for (final c in _optionCtrls) c.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------
  // Navigation
  // -------------------------------------------------------------------
  void _nextStep() {
    if (_currentStep == 0) {
      if (!(_step0Key.currentState?.validate() ?? false)) return;
    } else if (_currentStep == 1) {
      if (!(_step1Key.currentState?.validate() ?? false)) return;
    } else if (_currentStep == 2) {
      if (!_validateStep2()) return;
    }
    setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  bool _validateStep2() {
    if (_questionType == 'multipleChoice') {
      for (final ctrl in _optionCtrls) {
        if (ctrl.text.trim().isEmpty) {
          _showSnack('Isi semua opsi jawaban terlebih dahulu!');
          return false;
        }
      }
    }
    return true;
  }

  // -------------------------------------------------------------------
  // Save & Submit
  // -------------------------------------------------------------------
  QuestionModel _buildQuestion(String status) {
    List<String> options = [];
    String correctAnswer = '';

    if (_questionType == 'multipleChoice') {
      options = _optionCtrls.map((c) => c.text.trim()).toList();
      correctAnswer = options.isNotEmpty ? options[_correctOptionIndex] : '';
    } else if (_questionType == 'trueFalse') {
      options = ['Benar', 'Salah'];
      correctAnswer = _trueFalseAnswer ? 'Benar' : 'Salah';
    } else {
      correctAnswer = _essayAnswer;
    }

    // Auto-generate tags dari matkul & topik
    final autoTags = <String>[];
    if (_matkul.isNotEmpty) autoTags.add(_matkul);
    if (_topik.isNotEmpty) autoTags.add(_topik);
    autoTags.addAll(_tags);

    return QuestionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      questionText: _questionTextCtrl.text.trim(),
      questionType: _questionType,
      options: options,
      correctAnswer: correctAnswer,
      explanation: _explanationCtrl.text.trim(),
      difficulty: _difficulty,
      tags: autoTags,
      departmentId: _department,
      status: status,
      createdBy: 'user_seruni',
      updatedAt: DateTime.now(),
    );
  }

  void _saveDraft() {
    if (_questionTextCtrl.text.trim().isEmpty) {
      _showSnack('Isi teks pertanyaan terlebih dahulu!');
      return;
    }
    final newQuestion = _buildQuestion('DRAFT');
    widget.onSoalSaved?.call(newQuestion);
    Navigator.pop(context);
    _showSnackSuccess('Soal tersimpan sebagai Draft!');
  }

  void _submitForReview() {
    if (_questionTextCtrl.text.trim().isEmpty) {
      _showSnack('Isi teks pertanyaan terlebih dahulu!');
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Ajukan untuk Review?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text(
          'Soal "$_matkul - $_topik" akan dikirim ke Reviewer jurusan $_department.',
          style: GoogleFonts.nunito(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final newQuestion = _buildQuestion('PENDING_REVIEW');
              widget.onSoalSaved?.call(newQuestion);
              Navigator.pop(context);
              _showSnackSuccess('Soal berhasil diajukan untuk review!');
            },
            child: const Text('Ya, Ajukan'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.nunito()),
      backgroundColor: AppTheme.accentRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showSnackSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.nunito()),
      backgroundColor: AppTheme.accentGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
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
          onPressed: _showExitDialog,
        ),
        title: Text(
          widget.isEditMode ? 'Edit Soal' : 'Buat Soal Baru',
          style: GoogleFonts.poppins(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton.icon(
            onPressed: _saveDraft,
            icon: const Icon(Icons.save_outlined, color: Colors.white70, size: 18),
            label: Text('Simpan Draft',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
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
          _buildBottomNav(),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // Step Indicator
  // -------------------------------------------------------------------
  Widget _buildStepIndicator() {
    final steps = ['Konteks', 'Soal', 'Jawaban', 'Preview'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                      width: 26,
                      height: 26,
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
                                color: Colors.white, size: 14)
                            : Text('${idx + 1}',
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.grey.shade400,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                )),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(label,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                          color: isActive
                              ? AppTheme.primaryDark
                              : AppTheme.textSecondary,
                        )),
                  ],
                ),
                if (idx < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 18),
                      color: isDone ? AppTheme.accentGreen : Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildStep0();
      case 1: return _buildStep1();
      case 2: return _buildStep2();
      case 3: return _buildStep3();
      default: return const SizedBox();
    }
  }

  // -------------------------------------------------------------------
  // Step 0: Konteks (Jurusan, Matkul, Topik)
  // -------------------------------------------------------------------
  Widget _buildStep0() {
    return Form(
      key: _step0Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Konteks Soal', Icons.school_rounded),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Tentukan jurusan, mata kuliah, dan topik spesifik sebelum membuat soal. '
              'Ini membantu Reviewer memverifikasi soal dengan lebih cepat.',
              style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.primaryDark),
            ),
          ),
          const SizedBox(height: 20),

          // Jurusan
          _labelText('Jurusan Target *'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _department,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.apartment_rounded),
              hintText: 'Pilih jurusan',
            ),
            items: _departments.map((d) => DropdownMenuItem(
              value: d,
              child: Text(d, style: GoogleFonts.poppins(fontSize: 14)),
            )).toList(),
            onChanged: (v) {
              setState(() {
                _department = v!;
                _matkul = _matkulByDept[v]?.first ?? '';
              });
            },
          ),
          const SizedBox(height: 16),

          // Mata Kuliah
          _labelText('Mata Kuliah *'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _matkul.isEmpty ? null : _matkul,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.book_rounded),
              hintText: 'Pilih mata kuliah',
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Pilih mata kuliah' : null,
            items: _matkulList.map((m) => DropdownMenuItem(
              value: m,
              child: Text(m, style: GoogleFonts.poppins(fontSize: 13)),
            )).toList(),
            onChanged: (v) => setState(() => _matkul = v!),
          ),
          const SizedBox(height: 16),

          // Topik/Tema Spesifik
          _labelText('Topik / Tema Spesifik *'),
          const SizedBox(height: 4),
          Text(
            'Contoh: "Bab 3 - Graf", "Normalisasi Database", "TCP/IP Layer"',
            style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _topik,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Isi topik spesifik'
                : null,
            onChanged: (v) => _topik = v,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.topic_rounded),
              hintText: 'mis. Matematika Diskrit 2 - Bab Graf',
            ),
          ),
          const SizedBox(height: 20),

          // Preview konteks
          if (_matkul.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.folder_rounded,
                        color: AppTheme.primaryDark, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_department • $_matkul',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                        if (_topik.isNotEmpty)
                          Text(
                            _topik,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
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
          // Info konteks yang dipilih
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder_rounded,
                    color: AppTheme.primaryDark, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$_department • $_matkul${_topik.isNotEmpty ? ' • $_topik' : ''}',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppTheme.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _sectionHeader('Informasi Soal', Icons.info_outline_rounded),
          const SizedBox(height: 16),

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

          _labelText('Tipe Soal *'),
          const SizedBox(height: 8),
          Row(
            children: [
              _typeOption('multipleChoice', 'Pilihan Ganda',
                  Icons.format_list_bulleted_rounded),
              const SizedBox(width: 8),
              _typeOption('trueFalse', 'Benar/Salah',
                  Icons.check_circle_outline_rounded),
              const SizedBox(width: 8),
              _typeOption('essay', 'Essay', Icons.article_rounded),
            ],
          ),
          const SizedBox(height: 16),

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
        ],
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
          _sectionHeader('Pilihan Jawaban', Icons.check_circle_outline_rounded),
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
                  'Ketuk radio button untuk menandai jawaban yang benar.',
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
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: isCorrect ? AppTheme.accentGreen : AppTheme.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(letter,
                        style: TextStyle(
                          color: isCorrect ? Colors.white : AppTheme.primaryDark,
                          fontWeight: FontWeight.w700, fontSize: 13,
                        )),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: e.value,
                    decoration: InputDecoration(
                      hintText: 'Opsi $letter',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 0),
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
        _tfOption(true, 'Benar', Icons.check_circle_rounded, AppTheme.accentGreen),
        const SizedBox(height: 12),
        _tfOption(false, 'Salah', Icons.cancel_rounded, AppTheme.accentRed),
      ],
    );
  }

  Widget _tfOption(bool value, String label, IconData icon, Color color) {
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
              width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? color : Colors.grey, size: 28),
            const SizedBox(width: 16),
            Text(label,
                style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600,
                  color: selected ? color : AppTheme.textSecondary,
                )),
            const Spacer(),
            if (selected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(20)),
                child: Text('Jawaban Benar',
                    style: GoogleFonts.nunito(
                        color: Colors.white, fontSize: 12,
                        fontWeight: FontWeight.w700)),
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
            hintText: 'Tulis model jawaban sebagai referensi penilaian...',
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
        _sectionHeader('Pembahasan & Preview', Icons.preview_rounded),
        const SizedBox(height: 16),

        TextFormField(
          controller: _explanationCtrl,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Pembahasan (Opsional tapi disarankan)',
            hintText: 'Jelaskan mengapa jawaban tersebut benar...',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            const Icon(Icons.visibility_rounded,
                color: AppTheme.primaryDark, size: 18),
            const SizedBox(width: 8),
            Text('Preview Soal',
                style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: AppTheme.primaryDark,
                )),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Konteks
          Wrap(spacing: 6, runSpacing: 6, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primaryDark.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$_department • $_matkul',
                  style: GoogleFonts.poppins(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: AppTheme.primaryDark,
                  )),
            ),
            DifficultyChip(difficulty: _difficulty),
          ]),
          if (_topik.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(_topik,
                style: GoogleFonts.nunito(
                    fontSize: 11, color: AppTheme.textSecondary)),
          ],
          const SizedBox(height: 12),

          // Pertanyaan
          Text(
            _questionTextCtrl.text.isEmpty
                ? '(Teks pertanyaan akan tampil di sini)'
                : _questionTextCtrl.text,
            style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w500, height: 1.6,
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
                      color: isCorrect ? AppTheme.accentGreen : AppTheme.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? AppTheme.accentGreen
                            : AppTheme.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(letter,
                            style: TextStyle(
                              color: isCorrect
                                  ? Colors.white
                                  : AppTheme.primaryDark,
                              fontWeight: FontWeight.w700, fontSize: 11,
                            )),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(e.value.text,
                            style: GoogleFonts.nunito(fontSize: 13))),
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
            Text('Jawaban: ${_trueFalseAnswer ? 'Benar ✓' : 'Salah ✓'}',
                style: GoogleFonts.nunito(
                  fontSize: 13, color: AppTheme.accentGreen,
                  fontWeight: FontWeight.w700,
                )),
          ],

          if (_explanationCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(8),
                border: const Border(
                    left: BorderSide(color: AppTheme.primaryDark, width: 3)),
              ),
              child: Text(_explanationCtrl.text,
                  style: GoogleFonts.nunito(
                    fontSize: 12, color: AppTheme.textSecondary, height: 1.5,
                  )),
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // Bottom Nav
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
            child: _currentStep < 3
                ? ElevatedButton.icon(
                    onPressed: _nextStep,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Lanjut'),
                  )
                : ElevatedButton.icon(
                    onPressed: _submitForReview,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGreen),
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
              Text(label,
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    color: selected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center),
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
            child: Text(label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: selected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                )),
          ),
        ),
      ),
    );
  }

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
        Text(title,
            style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            )),
      ],
    );
  }

  Widget _labelText(String text) {
    return Text(text,
        style: GoogleFonts.nunito(
          fontSize: 13, fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
        ));
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Keluar tanpa menyimpan?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text(
          'Simpan sebagai draft terlebih dahulu?',
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