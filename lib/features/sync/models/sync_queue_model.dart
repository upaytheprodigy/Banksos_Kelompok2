// lib/features/sync/models/sync_queue_model.dart
//
// Entitas SyncQueue — setiap operasi CRUD yang belum terkirim ke cloud
// disimpan di sini sebagai antrian FIFO.
//
// Tugas: Adjie Ali (feature/offlineSync)

// ignore: depend_on_referenced_packages
import 'package:hive/hive.dart';

// Adapter type ID unik untuk Hive — jangan diubah setelah production
part 'sync_queue_model.g.dart';

/// Jenis operasi yang bisa masuk antrean
@HiveType(typeId: 10)
enum SyncOperation {
  @HiveField(0)
  create,

  @HiveField(1)
  update,

  @HiveField(2)
  delete,
}

/// Status tiap entri di SyncQueue
@HiveType(typeId: 11)
enum SyncStatus {
  @HiveField(0)
  pending, // belum dikirim

  @HiveField(1)
  synced, // berhasil dikirim

  @HiveField(2)
  error, // gagal setelah 3x retry
}

/// Model satu entri di SyncQueue.
///
/// Setiap kali user melakukan CRUD (buat soal, jawab kuis, dll),
/// satu SyncQueueModel dibuat dan disimpan ke Hive.
/// SyncManager akan memprosesnya secara FIFO saat online.
@HiveType(typeId: 12)
class SyncQueueModel extends HiveObject {
  /// ID unik entri ini (UUID atau timestamp-based)
  @HiveField(0)
  String id;

  /// Tipe entitas yang dioperasikan, misal: 'Question', 'QuizSession', 'User'
  @HiveField(1)
  String entityType;

  /// ID entitas yang dioperasikan di Hive (local ID)
  @HiveField(2)
  String entityId;

  /// Jurusan terkait (untuk filter admin panel)
  @HiveField(3)
  String? departmentId;

  /// Jenis operasi: create, update, atau delete
  @HiveField(4)
  SyncOperation operation;

  /// Data lengkap yang akan dikirim ke backend sebagai JSON string
  /// Contoh: jsonEncode(questionModel.toJson())
  @HiveField(5)
  String payload;

  /// Status saat ini
  @HiveField(6)
  SyncStatus status;

  /// Pesan error terakhir (jika status == error)
  @HiveField(7)
  String? errorMessage;

  /// Berapa kali sudah dicoba (max 3)
  @HiveField(8)
  int retryCount;

  /// Kapan entri ini dibuat — digunakan untuk urutan FIFO
  @HiveField(9)
  DateTime timestamp;

  SyncQueueModel({
    required this.id,
    required this.entityType,
    required this.entityId,
    this.departmentId,
    required this.operation,
    required this.payload,
    this.status = SyncStatus.pending,
    this.errorMessage,
    this.retryCount = 0,
    required this.timestamp,
  });

  /// Apakah entri ini masih bisa di-retry?
  bool get canRetry => retryCount < 3;

  /// Human-readable label operasi (untuk UI)
  String get operationLabel {
    switch (operation) {
      case SyncOperation.create:
        return 'Buat';
      case SyncOperation.update:
        return 'Perbarui';
      case SyncOperation.delete:
        return 'Hapus';
    }
  }

  @override
  String toString() =>
      'SyncQueue[$id] $operationLabel $entityType/$entityId — $status (retry: $retryCount)';
}
