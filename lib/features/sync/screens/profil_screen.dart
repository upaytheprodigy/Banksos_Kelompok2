// lib/features/sync/screens/profil_screen.dart
//
// Layar Profil — modul milik Adjie.
// Menampilkan:
//   - Info user (dummy dulu, nanti connect ke modul Auth Jibril)
//   - Status sinkronisasi lengkap
//   - Tombol "Sync Now" (manual fallback)
//   - Daftar entri SyncQueue terbaru
//
// Tugas: Adjie Ali (feature/offlineSync)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/sync_queue_model.dart';
import '../providers/sync_providers.dart';
import '../services/sync_manager.dart';
import '../widgets/sync_indicator_widget.dart';

class ProfilScreen extends ConsumerWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncManagerProvider);
    final syncList = ref.watch(syncQueueListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: AppTheme.primaryDark,
        actions: [
          // Tombol Sync Now di AppBar
          IconButton(
            icon: syncState.isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sync_rounded),
            tooltip: 'Sync Now',
            onPressed: syncState.isSyncing || !syncState.isOnline
                ? null
                : () => ref
                    .read(syncManagerProvider.notifier)
                    .processPendingQueue(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Baris indikator sync
          const SyncIndicatorWidget(),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // --- Kartu user (dummy) ---
                _UserCard(),

                const SizedBox(height: 20),

                // --- Kartu status sync ---
                _SyncStatusCard(syncState: syncState),

                const SizedBox(height: 20),

                // --- Tombol Sync Now besar ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.sync_rounded),
                    label: Text(
                      syncState.isSyncing
                          ? 'Menyinkronkan...'
                          : 'Sync Sekarang',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: syncState.isOnline
                          ? AppTheme.primaryDark
                          : AppTheme.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: syncState.isSyncing || !syncState.isOnline
                        ? null
                        : () => ref
                            .read(syncManagerProvider.notifier)
                            .processPendingQueue(),
                  ),
                ),

                if (!syncState.isOnline)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Tidak ada koneksi internet. Sync akan otomatis berjalan saat online.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 24),

                // --- Riwayat SyncQueue ---
                _SyncQueueSection(syncList: syncList, ref: ref),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Kartu user (dummy sampai modul Auth Jibril selesai)
// ---------------------------------------------------------------------------

class _UserCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppTheme.primaryLight,
              child: const Icon(
                Icons.person_rounded,
                size: 36,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adjie Ali Nurfizal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '241511034 • Teknik Informatika',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4),
                  // Role chip
                  Chip(
                    label: Text(
                      'User',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    backgroundColor: AppTheme.primaryLight,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Kartu ringkasan status sync
// ---------------------------------------------------------------------------

class _SyncStatusCard extends StatelessWidget {
  final SyncState syncState;

  const _SyncStatusCard({required this.syncState});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.cloud_sync_rounded,
                    color: AppTheme.primaryDark, size: 18),
                SizedBox(width: 8),
                Text(
                  'Status Sinkronisasi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Koneksi
                _StatChip(
                  label: 'Koneksi',
                  value: syncState.isOnline ? 'Online' : 'Offline',
                  color: syncState.isOnline
                      ? AppTheme.accentGreen
                      : AppTheme.textSecondary,
                  icon: syncState.isOnline
                      ? Icons.wifi_rounded
                      : Icons.wifi_off_rounded,
                ),
                const SizedBox(width: 8),
                // Pending
                _StatChip(
                  label: 'Menunggu',
                  value: '${syncState.pendingCount}',
                  color: syncState.pendingCount > 0
                      ? AppTheme.accentOrange
                      : AppTheme.textSecondary,
                  icon: Icons.pending_rounded,
                ),
                const SizedBox(width: 8),
                // Error
                _StatChip(
                  label: 'Gagal',
                  value: '${syncState.errorCount}',
                  color: syncState.errorCount > 0
                      ? AppTheme.accentRed
                      : AppTheme.textSecondary,
                  icon: Icons.error_outline_rounded,
                ),
              ],
            ),
            if (syncState.lastSyncAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Terakhir sync: ${_formatTime(syncState.lastSyncAt!)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section riwayat SyncQueue
// ---------------------------------------------------------------------------

class _SyncQueueSection extends StatelessWidget {
  final List<SyncQueueModel> syncList;
  final WidgetRef ref;

  const _SyncQueueSection({required this.syncList, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Riwayat Sync',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () async {
                await ref
                    .read(syncManagerProvider.notifier)
                    .clearSyncedEntries();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Bersihkan', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (syncList.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    color: AppTheme.accentGreen, size: 32),
                SizedBox(height: 8),
                Text(
                  'Semua data sudah tersinkronisasi',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else
          ...syncList.take(10).map((entry) => _SyncQueueTile(entry: entry)),

        if (syncList.length > 10)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '... dan ${syncList.length - 10} entri lainnya',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

class _SyncQueueTile extends StatelessWidget {
  final SyncQueueModel entry;

  const _SyncQueueTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(entry.status);
    final statusLabel = _statusLabel(entry.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          // Status dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.operationLabel} ${entry.entityType}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (entry.errorMessage != null)
                  Text(
                    entry.errorMessage!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.accentRed,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Status chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.pending:
        return AppTheme.accentOrange;
      case SyncStatus.synced:
        return AppTheme.accentGreen;
      case SyncStatus.error:
        return AppTheme.accentRed;
    }
  }

  String _statusLabel(SyncStatus status) {
    switch (status) {
      case SyncStatus.pending:
        return 'Menunggu';
      case SyncStatus.synced:
        return 'Tersync';
      case SyncStatus.error:
        return 'Gagal';
    }
  }
}
