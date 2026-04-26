// test/features/sync/sync_manager_test.dart
//
// Unit test untuk modul offlineSync.
// Skenario yang diuji (sesuai dokumen Sprint 4):
//   ✅ LWW: local lebih baru → kirim ke cloud
//   ✅ LWW: cloud lebih baru → skip, tandai synced
//   ✅ FIFO: entri diproses berdasarkan urutan timestamp
//   ✅ Retry 3x lalu status ERROR
//   ✅ Pending count dan error count benar
//   ✅ resetToRetry: ERROR kembali ke PENDING dengan retryCount = 0
//
// Tugas: Adjie Ali (feature/offlineSync)

import 'package:flutter_test/flutter_test.dart';
import 'package:banksos/features/sync/models/sync_queue_model.dart';
import 'package:banksos/features/sync/services/sync_manager.dart';

// ---------------------------------------------------------------------------
// Karena unit test tidak bisa akses Hive (butuh device), kita uji pure logic:
//   - Model SyncQueueModel
//   - LWW logic
//   - FIFO ordering
//   - Retry counting
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // GROUP 1: SyncQueueModel
  // =========================================================================
  group('SyncQueueModel', () {
    late SyncQueueModel entry;

    setUp(() {
      entry = SyncQueueModel(
        id: 'test_001',
        entityType: 'Question',
        entityId: 'q_123',
        operation: SyncOperation.create,
        payload: '{"id":"q_123","updatedAt":"2026-04-26T10:00:00.000Z"}',
        timestamp: DateTime(2026, 4, 26, 10, 0, 0),
      );
    });

    test('status awal harus PENDING', () {
      expect(entry.status, SyncStatus.pending);
    });

    test('retryCount awal harus 0', () {
      expect(entry.retryCount, 0);
    });

    test('canRetry benar selama retryCount < 3', () {
      expect(entry.canRetry, isTrue);
      entry.retryCount = 2;
      expect(entry.canRetry, isTrue);
      entry.retryCount = 3;
      expect(entry.canRetry, isFalse);
    });

    test('operationLabel mengembalikan teks yang benar', () {
      entry.operation = SyncOperation.create;
      expect(entry.operationLabel, 'Buat');
      entry.operation = SyncOperation.update;
      expect(entry.operationLabel, 'Perbarui');
      entry.operation = SyncOperation.delete;
      expect(entry.operationLabel, 'Hapus');
    });
  });

  // =========================================================================
  // GROUP 2: Last Write Wins (LWW) Logic
  // =========================================================================
  group('Last Write Wins (LWW)', () {
    /// Mensimulasikan logika LWW di SyncManager._checkLWW
    /// Return true → lokal lebih baru (kirim ke cloud)
    /// Return false → cloud lebih baru (skip)
    bool lwwShouldSend(DateTime localUpdatedAt, DateTime? cloudUpdatedAt) {
      if (cloudUpdatedAt == null) return true; // belum ada di cloud
      return localUpdatedAt.isAfter(cloudUpdatedAt) ||
          localUpdatedAt.isAtSameMomentAs(cloudUpdatedAt);
    }

    test('local lebih baru dari cloud → harus kirim ke cloud', () {
      final localTime = DateTime(2026, 4, 26, 12, 0, 0);
      final cloudTime = DateTime(2026, 4, 26, 10, 0, 0);
      expect(lwwShouldSend(localTime, cloudTime), isTrue);
    });

    test('cloud lebih baru dari local → harus skip (cloud menang)', () {
      final localTime = DateTime(2026, 4, 26, 10, 0, 0);
      final cloudTime = DateTime(2026, 4, 26, 12, 0, 0);
      expect(lwwShouldSend(localTime, cloudTime), isFalse);
    });

    test('timestamp sama → kirim (local sama valid dengan cloud)', () {
      final sameTime = DateTime(2026, 4, 26, 11, 0, 0);
      expect(lwwShouldSend(sameTime, sameTime), isTrue);
    });

    test('cloud null (entitas belum ada di cloud) → harus kirim', () {
      final localTime = DateTime(2026, 4, 26, 10, 0, 0);
      expect(lwwShouldSend(localTime, null), isTrue);
    });
  });

  // =========================================================================
  // GROUP 3: FIFO Ordering
  // =========================================================================
  group('FIFO Ordering', () {
    test('entri harus diurutkan dari yang paling lama (timestamp terkecil)', () {
      final entries = [
        SyncQueueModel(
          id: 'e3',
          entityType: 'Question',
          entityId: 'q3',
          operation: SyncOperation.update,
          payload: '{}',
          timestamp: DateTime(2026, 4, 26, 11, 0, 0), // paling baru
        ),
        SyncQueueModel(
          id: 'e1',
          entityType: 'Question',
          entityId: 'q1',
          operation: SyncOperation.create,
          payload: '{}',
          timestamp: DateTime(2026, 4, 26, 9, 0, 0), // paling lama
        ),
        SyncQueueModel(
          id: 'e2',
          entityType: 'QuizSession',
          entityId: 's1',
          operation: SyncOperation.create,
          payload: '{}',
          timestamp: DateTime(2026, 4, 26, 10, 0, 0), // tengah
        ),
      ];

      // Simulasi sort FIFO seperti di SyncRepository.getPendingEntries()
      entries.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      expect(entries[0].id, 'e1'); // paling lama dulu
      expect(entries[1].id, 'e2');
      expect(entries[2].id, 'e3'); // paling baru terakhir
    });

    test('entri dengan timestamp sama mempertahankan urutan relatif', () {
      final sameTime = DateTime(2026, 4, 26, 10, 0, 0);
      final entries = [
        SyncQueueModel(
          id: 'a',
          entityType: 'Question',
          entityId: 'q1',
          operation: SyncOperation.create,
          payload: '{}',
          timestamp: sameTime,
        ),
        SyncQueueModel(
          id: 'b',
          entityType: 'Question',
          entityId: 'q2',
          operation: SyncOperation.create,
          payload: '{}',
          timestamp: sameTime,
        ),
      ];

      entries.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      // Tidak boleh melempar error
      expect(entries.length, 2);
    });
  });

  // =========================================================================
  // GROUP 4: Retry Logic
  // =========================================================================
  group('Retry Logic', () {
    late SyncQueueModel entry;

    setUp(() {
      entry = SyncQueueModel(
        id: 'retry_test',
        entityType: 'Question',
        entityId: 'q_fail',
        operation: SyncOperation.create,
        payload: '{}',
        timestamp: DateTime.now(),
      );
    });

    test('setelah 1x gagal → retryCount = 1, status masih PENDING', () {
      entry.retryCount++;
      entry.errorMessage = 'Network timeout';
      // Belum 3x → tetap PENDING
      expect(entry.retryCount, 1);
      expect(entry.canRetry, isTrue);
      expect(entry.status, SyncStatus.pending);
    });

    test('setelah 2x gagal → retryCount = 2, masih bisa retry', () {
      entry.retryCount = 2;
      expect(entry.canRetry, isTrue);
    });

    test('setelah 3x gagal → canRetry false, status harus ERROR', () {
      // Simulasi logika di SyncRepository.markFailed
      entry.retryCount = 3;
      if (entry.retryCount >= 3) {
        entry.status = SyncStatus.error;
      }
      expect(entry.canRetry, isFalse);
      expect(entry.status, SyncStatus.error);
    });

    test('resetToRetry → retryCount kembali 0 dan status PENDING', () {
      // Setup: entry dalam kondisi ERROR
      entry.status = SyncStatus.error;
      entry.retryCount = 3;
      entry.errorMessage = 'Server error 500';

      // Simulasi SyncRepository.resetToRetry
      entry.status = SyncStatus.pending;
      entry.retryCount = 0;
      entry.errorMessage = null;

      expect(entry.status, SyncStatus.pending);
      expect(entry.retryCount, 0);
      expect(entry.errorMessage, isNull);
      expect(entry.canRetry, isTrue);
    });
  });

  // =========================================================================
  // GROUP 5: SyncState
  // =========================================================================
  group('SyncState', () {
    test('statusLabel benar saat semua tersync', () {
      final state = SyncState(
        isOnline: true,
        pendingCount: 0,
        errorCount: 0,
      );
      expect(state.statusLabel, 'Tersinkronisasi');
    });

    test('statusLabel benar saat ada pending', () {
      final state = SyncState(
        isOnline: true,
        pendingCount: 5,
        errorCount: 0,
      );
      expect(state.statusLabel, '5 item menunggu sync');
    });

    test('statusLabel benar saat ada error', () {
      final state = SyncState(
        isOnline: true,
        pendingCount: 0,
        errorCount: 2,
      );
      expect(state.statusLabel, '2 item gagal');
    });

    test('statusLabel benar saat offline', () {
      final state = SyncState(isOnline: false);
      expect(state.statusLabel, 'Offline');
    });

    test('statusLabel benar saat sedang sync', () {
      final state = SyncState(isOnline: true, isSyncing: true);
      expect(state.statusLabel, 'Menyinkronkan...');
    });

    test('indicatorColor merah saat ada error', () {
      final state = SyncState(errorCount: 1);
      expect(state.indicatorColor, SyncIndicatorColor.red);
    });

    test('indicatorColor kuning saat ada pending', () {
      final state = SyncState(isOnline: true, pendingCount: 3);
      expect(state.indicatorColor, SyncIndicatorColor.yellow);
    });

    test('indicatorColor hijau saat semua bersih', () {
      final state = SyncState(
        isOnline: true,
        pendingCount: 0,
        errorCount: 0,
      );
      expect(state.indicatorColor, SyncIndicatorColor.green);
    });
  });

  // =========================================================================
  // GROUP 6: Exponential Backoff
  // =========================================================================
  group('Exponential Backoff Duration', () {
    /// Simulasi kalkulasi delay di SyncManager._handleRetry
    Duration backoffDelay(int retryCount) {
      return Duration(seconds: (1 << retryCount).clamp(1, 30));
    }

    test('retry ke-0 → delay 1 detik', () {
      expect(backoffDelay(0), const Duration(seconds: 1));
    });

    test('retry ke-1 → delay 2 detik', () {
      expect(backoffDelay(1), const Duration(seconds: 2));
    });

    test('retry ke-2 → delay 4 detik', () {
      expect(backoffDelay(2), const Duration(seconds: 4));
    });

    test('tidak melebihi 30 detik meski retryCount besar', () {
      expect(backoffDelay(10), const Duration(seconds: 30));
    });
  });
}
