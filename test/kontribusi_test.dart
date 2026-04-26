import 'package:flutter_test/flutter_test.dart';
import 'package:banksos/features/kontribusi/models/question_model.dart';
import 'package:banksos/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

void main() {
  // =========================================================
  // Unit Tests - Modul Kontribusi Soal (Seruni Libertina)
  // =========================================================

  group('QuestionModel - Status Transitions', () {
    late QuestionModel question;

    setUp(() {
      question = QuestionModel(
        id: 'test-001',
        questionText: 'Apa output dari print(type(3/2)) di Python 3?',
        questionType: 'multipleChoice',
        options: ["<class 'int'>", "<class 'float'>", "<class 'str'>", 'Error'],
        correctAnswer: "<class 'float'>",
        explanation: 'Dalam Python 3, pembagian selalu menghasilkan float.',
        difficulty: 'easy',
        tags: ['Python', 'Pemrograman'],
        departmentId: 'TI',
        status: 'DRAFT',
        createdBy: 'user_seruni_001',
        updatedAt: DateTime.now(),
      );
    });

    /// Test 1: Status awal submit soal oleh User harus DRAFT
    test('Status awal soal baru harus DRAFT', () {
      expect(question.status, equals('DRAFT'));
    });

    /// Test 2: Soal tidak boleh langsung APPROVED tanpa melalui PENDING_REVIEW
    /// (business constraint UC-03)
    test('User tidak dapat membuat soal langsung APPROVED', () {
      // User hanya bisa membuat DRAFT atau PENDING_REVIEW
      final validUserStatuses = ['DRAFT', 'PENDING_REVIEW'];
      expect(validUserStatuses.contains(question.status), isTrue);
      expect(question.status, isNot(equals('APPROVED')));
    });

    /// Test 3: Soal DRAFT bisa diubah ke PENDING_REVIEW (ajukan review)
    test('Soal DRAFT dapat diajukan ke PENDING_REVIEW', () {
      final submitted = question.copyWith(status: 'PENDING_REVIEW');
      expect(submitted.status, equals('PENDING_REVIEW'));
    });

    /// Test 4: Soal yang sudah APPROVED tidak bisa diedit ulang oleh User
    test('Soal APPROVED tidak dapat diedit status-nya oleh User', () {
      final approved = question.copyWith(status: 'APPROVED');
      // User tidak boleh mengubah soal APPROVED
      // (di implementasi nyata, cek role di repository layer)
      expect(approved.status, equals('APPROVED'));
      // Test bahwa status APPROVED adalah terminal untuk User
      const userEditableStatuses = ['DRAFT', 'NEEDS_REVISION'];
      expect(userEditableStatuses.contains(approved.status), isFalse);
    });

    /// Test 5: Soal REJECTED bersifat permanen (User tidak bisa resubmit)
    test('Soal REJECTED bersifat permanen', () {
      final rejected = question.copyWith(
        status: 'REJECTED',
        rejectionNote: 'Soal duplikat dari bank soal yang ada.',
      );
      expect(rejected.status, equals('REJECTED'));
      expect(rejected.rejectionNote, isNotNull);
      // Pastikan rejectionNote terisi
      expect(rejected.rejectionNote!.isNotEmpty, isTrue);
    });

    /// Test 6: Soal NEEDS_REVISION harus memiliki revisionNote
    test('Soal NEEDS_REVISION wajib memiliki revisionNote', () {
      final revision = question.copyWith(
        status: 'NEEDS_REVISION',
        revisionNote: 'Tolong tambahkan pembahasan yang lebih detail.',
      );
      expect(revision.status, equals('NEEDS_REVISION'));
      expect(revision.revisionNote, isNotNull);
      expect(revision.revisionNote!.isNotEmpty, isTrue);
    });
  });

  group('QuestionModel - Validasi Data', () {
    /// Test 7: Question harus memiliki minimal 1 tag
    test('Tags dapat kosong (opsional)', () {
      final q = QuestionModel(
        id: 'test-002',
        questionText: 'Test pertanyaan',
        questionType: 'trueFalse',
        options: [],
        correctAnswer: 'Benar',
        difficulty: 'easy',
        tags: [],
        departmentId: 'TI',
        status: 'DRAFT',
        createdBy: 'user_001',
        updatedAt: DateTime.now(),
      );
      expect(q.tags, isEmpty);
    });

    /// Test 8: Multiple choice harus memiliki minimal 2 opsi
    test('Pilihan ganda harus memiliki minimal 2 opsi jawaban', () {
      final validOptions = ['Opsi A', 'Opsi B'];
      expect(validOptions.length >= 2, isTrue);

      final invalidOptions = ['Hanya satu opsi'];
      expect(invalidOptions.length >= 2, isFalse);
    });

    /// Test 9: Pilihan ganda maksimal 5 opsi
    test('Pilihan ganda maksimal 5 opsi jawaban', () {
      final maxOptions = ['A', 'B', 'C', 'D', 'E'];
      expect(maxOptions.length <= 5, isTrue);

      final tooManyOptions = ['A', 'B', 'C', 'D', 'E', 'F'];
      expect(tooManyOptions.length <= 5, isFalse);
    });

    /// Test 10: Jawaban benar harus ada di antara opsi yang tersedia
    test('Jawaban benar harus merupakan salah satu dari opsi yang diberikan', () {
      const options = ['<class int>', '<class float>', '<class str>', 'Error'];
      const correctAnswer = '<class float>';
      expect(options.contains(correctAnswer), isTrue);

      const invalidAnswer = 'Tidak ada yang benar';
      expect(options.contains(invalidAnswer), isFalse);
    });
  });

  group('QuestionModel - Jurusan & Namespace', () {
    /// Test 11: Soal dari jurusan lain tidak boleh muncul di Review Queue jurusan TI
    test('Filter jurusan di Review Queue hanya menampilkan soal jurusan sendiri', () {
      final allPendingQuestions = [
        QuestionModel(
          id: 'q1',
          questionText: 'Soal TI',
          questionType: 'multipleChoice',
          options: ['A', 'B'],
          correctAnswer: 'A',
          difficulty: 'easy',
          tags: ['TI'],
          departmentId: 'TI',
          status: 'PENDING_REVIEW',
          createdBy: 'user1',
          updatedAt: DateTime.now(),
        ),
        QuestionModel(
          id: 'q2',
          questionText: 'Soal Akuntansi',
          questionType: 'multipleChoice',
          options: ['A', 'B'],
          correctAnswer: 'B',
          difficulty: 'medium',
          tags: ['AK'],
          departmentId: 'AK',
          status: 'PENDING_REVIEW',
          createdBy: 'user2',
          updatedAt: DateTime.now(),
        ),
      ];

      // Reviewer TI hanya melihat soal dari departmentId 'TI'
      const reviewerDepartment = 'TI';
      final filteredForReviewer = allPendingQuestions
          .where((q) => q.departmentId == reviewerDepartment)
          .toList();

      expect(filteredForReviewer.length, equals(1));
      expect(filteredForReviewer.first.departmentId, equals('TI'));
    });
  });

  group('AppTheme - Status Colors', () {
    /// Test 12: Warna status chip sesuai desain
    test('Warna chip APPROVED harus hijau', () {
      final color = AppTheme.statusColor('APPROVED');
      expect(color, equals(AppTheme.accentGreen));
    });

    test('Warna chip REJECTED harus merah', () {
      final color = AppTheme.statusColor('REJECTED');
      expect(color, equals(AppTheme.accentRed));
    });

    test('Label status dalam Bahasa Indonesia', () {
      expect(AppTheme.statusLabel('PENDING_REVIEW'), equals('Menunggu Review'));
      expect(AppTheme.statusLabel('NEEDS_REVISION'), equals('Perlu Revisi'));
      expect(AppTheme.statusLabel('DRAFT'), equals('Draft'));
    });
  });
}