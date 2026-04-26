// lib/features/sync/widgets/sync_indicator_widget.dart
//
// Widget baris tipis di bawah header yang menampilkan status sync real-time.
//
//   🟢  "Tersinkronisasi"          → semua data sudah sync
//   🟡  "3 item menunggu sync"     → ada yang pending
//   🔴  "2 item gagal (Tap detail)" → ada yang error
//
// Cara pakai — taruh di bawah AppBar atau di atas body Scaffold:
//
//   Column(
//     children: [
//       const SyncIndicatorWidget(),
//       Expanded(child: ...),
//     ],
//   )
//
// Tugas: Adjie Ali (feature/offlineSync)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/sync_providers.dart';
import '../services/sync_manager.dart';

class SyncIndicatorWidget extends ConsumerWidget {
  const SyncIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncManagerProvider);

    // Kalau semua oke dan tidak ada pending/error, tampilkan strip tipis
    // yang hampir tidak mengganggu
    final color = _resolveColor(syncState);
    final label = syncState.statusLabel;
    final showTapHint = syncState.errorCount > 0;

    return GestureDetector(
      onTap: showTapHint
          ? () => _showSyncDetailSheet(context, ref)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        color: color.withValues(alpha: .12),
        child: Row(
          children: [
            // Titik indikator
            _SyncDot(color: color, isPulsing: syncState.isSyncing),
            const SizedBox(width: 8),
            // Label
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            // Ikon tap kalau ada error
            if (showTapHint)
              Icon(Icons.chevron_right_rounded, size: 16, color: color),
            // Ikon sync sedang jalan
            if (syncState.isSyncing)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: color,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _resolveColor(SyncState state) {
    switch (state.indicatorColor) {
      case SyncIndicatorColor.green:
        return AppTheme.accentGreen;
      case SyncIndicatorColor.yellow:
        return AppTheme.accentOrange;
      case SyncIndicatorColor.red:
        return AppTheme.accentRed;
    }
  }

  void _showSyncDetailSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ProviderScope(
        overrides: const [],
        child: _SyncDetailSheet(ref: ref),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Titik berdenyut saat sync sedang berjalan
// ---------------------------------------------------------------------------

class _SyncDot extends StatefulWidget {
  final Color color;
  final bool isPulsing;

  const _SyncDot({required this.color, required this.isPulsing});

  @override
  State<_SyncDot> createState() => _SyncDotState();
}

class _SyncDotState extends State<_SyncDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPulsing) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      );
    }
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Opacity(
        opacity: _animation.value,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet detail sync (daftar error + tombol retry)
// ---------------------------------------------------------------------------

class _SyncDetailSheet extends ConsumerWidget {
  final WidgetRef ref;

  const _SyncDetailSheet({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef consumerRef) {
    final syncState = consumerRef.watch(syncManagerProvider);
    final errorList = consumerRef.watch(syncErrorListProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.85,
      minChildSize: 0.3,
      expand: false,
      builder: (_, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  const Icon(Icons.sync_problem_rounded,
                      color: AppTheme.accentRed, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${syncState.errorCount} Item Gagal Sync',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  // Tombol retry semua
                  TextButton.icon(
                    onPressed: syncState.isOnline
                        ? () {
                            consumerRef
                                .read(syncManagerProvider.notifier)
                                .retryAllErrors();
                            Navigator.pop(context);
                          }
                        : null,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Coba Lagi'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryDark,
                    ),
                  ),
                ],
              ),

              if (!syncState.isOnline)
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 4),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off_rounded,
                          color: AppTheme.accentOrange, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Tidak ada koneksi internet',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.accentOrange,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // Daftar error
              Expanded(
                child: errorList.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada item gagal',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: errorList.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final entry = errorList[i];
                          return _SyncErrorTile(
                            entry: entry,
                            onRetry: syncState.isOnline
                                ? () async {
                                    await consumerRef
                                        .read(syncRepositoryProvider)
                                        .resetToRetry(entry.id);
                                    await consumerRef
                                        .read(syncManagerProvider.notifier)
                                        .processPendingQueue();
                                  }
                                : null,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SyncErrorTile extends StatelessWidget {
  final dynamic entry;
  final VoidCallback? onRetry;

  const _SyncErrorTile({required this.entry, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.accentRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.sync_problem_rounded,
            color: AppTheme.accentRed, size: 18),
      ),
      title: Text(
        '${entry.operationLabel} ${entry.entityType}',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        entry.errorMessage ?? 'Unknown error',
        style: const TextStyle(
          fontSize: 11,
          color: AppTheme.textSecondary,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: onRetry != null
          ? IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  color: AppTheme.primaryDark, size: 20),
              onPressed: onRetry,
              tooltip: 'Coba lagi',
            )
          : null,
    );
  }
}
