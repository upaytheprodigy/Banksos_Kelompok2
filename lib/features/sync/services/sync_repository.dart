// lib/features/sync/services/sync_repository.dart
//
// Repository untuk operasi CRUD pada SyncQueue di Hive.
// SyncManager menggunakan class ini — tidak langsung akses Hive.
//
// Tugas: Adjie Ali (feature/offlineSync)

import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/sync_queue_model.dart';

/// Nama box Hive yang menyimpan SyncQueue
const kSyncQueueBox = 'sync_queue';

class SyncRepository {
  /// Mendapatkan box SyncQueue yang sudah terbuka
  Box<SyncQueueModel> get _box => Hive.box<SyncQueueModel>(kSyncQueueBox);

  /// Tambahkan satu operasi ke antrean.
  ///
  /// Dipanggil setiap kali ada operasi CRUD yang perlu disinkronkan.
  /// Contoh: setelah menyimpan QuestionModel baru ke Hive.
  Future<void> enqueue(SyncQueueModel entry) async {
    await _box.put(entry.id, entry);
  }

  /// Ambil semua entri dengan status PENDING, diurutkan berdasarkan timestamp (FIFO).
  List<SyncQueueModel> getPendingEntries() {
    return _box.values
        .where((e) => e.status == SyncStatus.pending)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Ambil semua entri dengan status ERROR.
  List<SyncQueueModel> getErrorEntries() {
    return _box.values
        .where((e) => e.status == SyncStatus.error)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // terbaru dulu
  }

  /// Ambil semua entri (untuk tampilan admin/profil).
  List<SyncQueueModel> getAllEntries() {
    return _box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Update status entri setelah berhasil di-sync.
  Future<void> markSynced(String entryId) async {
    final entry = _box.get(entryId);
    if (entry == null) return;
    entry.status = SyncStatus.synced;
    entry.errorMessage = null;
    await entry.save();
  }

  /// Update entri setelah gagal — naikkan retryCount.
  /// Jika sudah 3x gagal, status menjadi ERROR.
  Future<void> markFailed(String entryId, String errorMessage) async {
    final entry = _box.get(entryId);
    if (entry == null) return;
    entry.retryCount++;
    entry.errorMessage = errorMessage;
    if (entry.retryCount >= 3) {
      entry.status = SyncStatus.error;
    }
    // Jika belum 3x, tetap PENDING (akan dicoba lagi)
    await entry.save();
  }

  /// Reset entri ERROR kembali ke PENDING (untuk tombol "Retry" manual).
  Future<void> resetToRetry(String entryId) async {
    final entry = _box.get(entryId);
    if (entry == null) return;
    entry.status = SyncStatus.pending;
    entry.retryCount = 0;
    entry.errorMessage = null;
    await entry.save();
  }

  /// Hapus semua entri yang sudah SYNCED (bersihkan box secara berkala).
  Future<void> clearSynced() async {
    final syncedKeys = _box.values
        .where((e) => e.status == SyncStatus.synced)
        .map((e) => e.id)
        .toList();
    await _box.deleteAll(syncedKeys);
  }

  /// Hitung jumlah entri PENDING (untuk badge di UI).
  int get pendingCount =>
      _box.values.where((e) => e.status == SyncStatus.pending).length;

  /// Hitung jumlah entri ERROR (untuk badge merah di UI).
  int get errorCount =>
      _box.values.where((e) => e.status == SyncStatus.error).length;

  /// Apakah semua entri sudah SYNCED?
  bool get isAllSynced => pendingCount == 0 && errorCount == 0;

  /// ValueListenable untuk reaksi UI real-time saat box berubah.
  ValueListenable<Box<SyncQueueModel>> get listenable => _box.listenable();
}
