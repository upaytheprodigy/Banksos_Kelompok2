// lib/features/sync/services/sync_manager.dart
//
// SyncManager — inti dari fitur offlineSync.
//
// Tanggung jawab:
//   1. Monitor konektivitas internet (connectivity_plus)
//   2. Proses SyncQueue secara FIFO saat online
//   3. Exponential backoff saat retry
//   4. Last Write Wins conflict resolution berdasarkan updatedAt
//   5. Notify provider saat ada perubahan status
//
// Tugas: Adjie Ali (feature/offlineSync)

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sync_queue_model.dart';
import 'sync_repository.dart';
import 'api_service.dart';

/// State yang di-expose ke UI
class SyncState {
  final bool isOnline;
  final bool isSyncing;
  final int pendingCount;
  final int errorCount;
  final String? lastError;
  final DateTime? lastSyncAt;

  const SyncState({
    this.isOnline = false,
    this.isSyncing = false,
    this.pendingCount = 0,
    this.errorCount = 0,
    this.lastError,
    this.lastSyncAt,
  });

  SyncState copyWith({
    bool? isOnline,
    bool? isSyncing,
    int? pendingCount,
    int? errorCount,
    String? lastError,
    DateTime? lastSyncAt,
  }) {
    return SyncState(
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      errorCount: errorCount ?? this.errorCount,
      lastError: lastError ?? this.lastError,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  /// Label singkat untuk ditampilkan di UI
  String get statusLabel {
    if (isSyncing) return 'Menyinkronkan...';
    if (!isOnline) return 'Offline';
    if (errorCount > 0) return '$errorCount item gagal';
    if (pendingCount > 0) return '$pendingCount item menunggu sync';
    return 'Tersinkronisasi';
  }

  /// Warna indikator (untuk SyncIndicatorWidget)
  SyncIndicatorColor get indicatorColor {
    if (errorCount > 0) return SyncIndicatorColor.red;
    if (pendingCount > 0 || isSyncing) return SyncIndicatorColor.yellow;
    return SyncIndicatorColor.green;
  }
}

enum SyncIndicatorColor { green, yellow, red }

// ---------------------------------------------------------------------------
// SyncManager Notifier
// ---------------------------------------------------------------------------

class SyncManager extends StateNotifier<SyncState> {
  final SyncRepository _repository;
  final ApiService _apiService;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isProcessing = false;

  SyncManager(this._repository, this._apiService) : super(const SyncState()) {
    _init();
  }

  void _init() {
    // Cek koneksi awal
    _checkConnectivityAndSync();

    // Subscribe ke perubahan konektivitas
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen(_onConnectivityChanged);

    // Update count dari Hive saat init
    _refreshCounts();
  }

  /// Dipanggil oleh listener connectivity_plus
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final hasConnection = results.any((r) => r != ConnectivityResult.none);

    if (hasConnection && !state.isOnline) {
      // Baru online — langsung proses antrian
      state = state.copyWith(isOnline: true);
      processPendingQueue();
    } else if (!hasConnection) {
      state = state.copyWith(isOnline: false, isSyncing: false);
    }
  }

  Future<void> _checkConnectivityAndSync() async {
    final results = await Connectivity().checkConnectivity();
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    state = state.copyWith(isOnline: hasConnection);
    if (hasConnection) {
      await processPendingQueue();
    }
  }

  /// Update badge counts dari Hive
  void _refreshCounts() {
    state = state.copyWith(
      pendingCount: _repository.pendingCount,
      errorCount: _repository.errorCount,
    );
  }

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Tambahkan operasi ke antrian sync.
  ///
  /// Dipanggil dari modul lain setiap kali ada perubahan data.
  /// Contoh penggunaan:
  ///   await syncManager.enqueue(
  ///     entityType: 'Question',
  ///     entityId: question.id,
  ///     operation: SyncOperation.create,
  ///     payload: jsonEncode(question.toJson()),
  ///     departmentId: question.departmentId,
  ///   );
  Future<void> enqueue({
    required String entityType,
    required String entityId,
    required SyncOperation operation,
    required String payload,
    String? departmentId,
  }) async {
    final entry = SyncQueueModel(
      id: '${entityType}_${entityId}_${DateTime.now().millisecondsSinceEpoch}',
      entityType: entityType,
      entityId: entityId,
      departmentId: departmentId,
      operation: operation,
      payload: payload,
      timestamp: DateTime.now(),
    );

    await _repository.enqueue(entry);
    _refreshCounts();

    // Kalau sedang online, langsung proses
    if (state.isOnline && !_isProcessing) {
      processPendingQueue();
    }
  }

  /// Proses semua entri PENDING secara FIFO.
  ///
  /// - Dijalankan otomatis saat online
  /// - Bisa dipanggil manual via tombol "Sync Now"
  Future<void> processPendingQueue() async {
    if (_isProcessing) return; // hindari double-processing
    _isProcessing = true;
    state = state.copyWith(isSyncing: true);

    try {
      final pending = _repository.getPendingEntries(); // sudah urut FIFO

      for (final entry in pending) {
        if (!state.isOnline) break; // berhenti kalau tiba-tiba offline

        await _processSingleEntry(entry);
      }
    } finally {
      _isProcessing = false;
      _refreshCounts();
      state = state.copyWith(
        isSyncing: false,
        lastSyncAt: DateTime.now(),
      );
    }
  }

  /// Proses satu entri dengan Last Write Wins conflict resolution.
  Future<void> _processSingleEntry(SyncQueueModel entry) async {
    try {
      // --- Last Write Wins (LWW) ---
      // Sebelum kirim, cek apakah data di cloud lebih baru dari local
      if (entry.operation != SyncOperation.delete) {
        final shouldProceed = await _checkLWW(entry);
        if (!shouldProceed) {
          // Cloud lebih baru — skip, tandai synced
          await _repository.markSynced(entry.id);
          return;
        }
      }

      // --- Kirim ke backend ---
      final response = await _apiService.sendSyncEntry(entry);

      if (response.success) {
        await _repository.markSynced(entry.id);
      } else {
        await _handleRetry(entry, response.errorMessage ?? 'Unknown error');
      }
    } on Exception catch (e) {
      await _handleRetry(entry, e.toString());
    }
  }

  /// Last Write Wins: bandingkan updatedAt lokal vs cloud.
  ///
  /// Return true  → lokal lebih baru, lanjutkan kirim ke cloud.
  /// Return false → cloud lebih baru, skip (cloud menang).
  Future<bool> _checkLWW(SyncQueueModel entry) async {
    // Parse updatedAt dari payload lokal
    DateTime? localUpdatedAt;
    try {
      final payloadMap = _parsePayload(entry.payload);
      if (payloadMap['updatedAt'] != null) {
        localUpdatedAt = DateTime.tryParse(payloadMap['updatedAt'].toString());
      }
    } on Exception {
      // Tidak bisa parse payload — tetap lanjutkan kirim
      return true;
    }

    if (localUpdatedAt == null) return true; // tidak ada timestamp — lanjutkan

    // Ambil data dari cloud
    final cloudResponse = await _apiService.fetchLatestFromCloud(
      entry.entityType,
      entry.entityId,
    );

    if (!cloudResponse.success) return true; // gagal fetch cloud — lanjutkan
    if (cloudResponse.data == null) return true; // belum ada di cloud — lanjutkan

    final cloudUpdatedAt = cloudResponse.serverUpdatedAt;
    if (cloudUpdatedAt == null) return true; // cloud tidak punya timestamp — lanjutkan

    // Bandingkan: lokal lebih baru → kirim; cloud lebih baru → skip
    return localUpdatedAt.isAfter(cloudUpdatedAt) ||
        localUpdatedAt.isAtSameMomentAs(cloudUpdatedAt);
  }

  /// Handle retry dengan exponential backoff.
  Future<void> _handleRetry(SyncQueueModel entry, String error) async {
    await _repository.markFailed(entry.id, error);

    if (!entry.canRetry) {
      // Sudah 3x gagal — status ERROR, notify user
      state = state.copyWith(
        lastError: 'Gagal sync ${entry.entityType}: $error',
      );
    } else {
      // Exponential backoff: 2^retryCount detik (1s, 2s, 4s)
      final delay = Duration(seconds: (1 << entry.retryCount).clamp(1, 30));
      await Future.delayed(delay);
    }
  }

  /// Reset semua entri ERROR kembali ke PENDING dan proses ulang.
  /// Dipanggil saat user tap "Coba Lagi" di UI.
  Future<void> retryAllErrors() async {
    final errors = _repository.getErrorEntries();
    for (final entry in errors) {
      await _repository.resetToRetry(entry.id);
    }
    _refreshCounts();
    if (state.isOnline) {
      await processPendingQueue();
    }
  }

  /// Bersihkan entri SYNCED lama dari Hive.
  Future<void> clearSyncedEntries() async {
    await _repository.clearSynced();
    _refreshCounts();
  }

  /// Set JWT token setelah login (dipanggil oleh modul Auth - Jibril)
  void setAuthToken(String token) {
    _apiService.setAuthToken(token);
  }

  void clearAuthToken() {
    _apiService.clearAuthToken();
  }

  // -------------------------------------------------------------------------
  // Helper
  // -------------------------------------------------------------------------

  Map<String, dynamic> _parsePayload(String payload) {
    try {
      final decoded = payload;
      // Sederhana: cari 'updatedAt' di payload string
      // Di implementasi nyata, gunakan jsonDecode
      if (decoded.contains('"updatedAt"')) {
        final start = decoded.indexOf('"updatedAt"') + 12;
        final end = decoded.indexOf('"', start + 1);
        if (end > start) {
          final value = decoded.substring(start, end);
          return {'updatedAt': value.replaceAll('"', '').replaceAll(':', '')};
        }
      }
      return {};
    } on Exception {
      return {};
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}
