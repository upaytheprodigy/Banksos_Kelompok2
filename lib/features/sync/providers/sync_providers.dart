// lib/features/sync/providers/sync_providers.dart
//
// Semua Riverpod provider untuk fitur sync.
// Diakses oleh widget lain dengan ref.watch / ref.read.
//
// Tugas: Adjie Ali (feature/offlineSync)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sync_queue_model.dart';
import '../services/api_service.dart';
import '../services/sync_manager.dart';
import '../services/sync_repository.dart';

// ---------------------------------------------------------------------------
// Instance providers (singleton)
// ---------------------------------------------------------------------------

/// Provider untuk SyncRepository (akses Hive)
final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository();
});

/// Provider untuk ApiService (HTTP ke backend)
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

/// Provider utama — SyncManager sebagai StateNotifier
/// Semua widget yang butuh status sync watch provider ini.
final syncManagerProvider =
    StateNotifierProvider<SyncManager, SyncState>((ref) {
  final repository = ref.watch(syncRepositoryProvider);
  final apiService = ref.watch(apiServiceProvider);
  return SyncManager(repository, apiService);
});

// ---------------------------------------------------------------------------
// Derived providers (turunan dari syncManagerProvider)
// ---------------------------------------------------------------------------

/// Hanya online/offline status — untuk widget yang cuma butuh ini
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(syncManagerProvider).isOnline;
});

/// Jumlah item pending — untuk badge counter
final syncPendingCountProvider = Provider<int>((ref) {
  return ref.watch(syncManagerProvider).pendingCount;
});

/// Jumlah item error — untuk badge merah
final syncErrorCountProvider = Provider<int>((ref) {
  return ref.watch(syncManagerProvider).errorCount;
});

/// Label teks status sync — untuk SyncIndicatorWidget
final syncStatusLabelProvider = Provider<String>((ref) {
  return ref.watch(syncManagerProvider).statusLabel;
});

/// Warna indikator — green/yellow/red
final syncIndicatorColorProvider = Provider<SyncIndicatorColor>((ref) {
  return ref.watch(syncManagerProvider).indicatorColor;
});

// ---------------------------------------------------------------------------
// List providers (untuk admin panel / profil screen)
// ---------------------------------------------------------------------------

/// Daftar semua entri SyncQueue (untuk halaman detail sync)
final syncQueueListProvider = Provider<List<SyncQueueModel>>((ref) {
  // Watch syncManager supaya list refresh saat state berubah
  ref.watch(syncManagerProvider);
  final repo = ref.watch(syncRepositoryProvider);
  return repo.getAllEntries();
});

/// Daftar entri ERROR saja
final syncErrorListProvider = Provider<List<SyncQueueModel>>((ref) {
  ref.watch(syncManagerProvider);
  final repo = ref.watch(syncRepositoryProvider);
  return repo.getErrorEntries();
});
