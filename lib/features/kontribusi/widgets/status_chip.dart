import 'package:flutter/material.dart';
import 'package:banksos/core/theme/app_theme.dart';
import 'package:banksos/features/kontribusi/models/question_model.dart';

class StatusChip extends StatelessWidget {
  final String status;
  final bool small;

  const StatusChip({super.key, required this.status, this.small = false});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status);
    final label = AppTheme.statusLabel(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: small ? 6 : 8,
            height: small ? 6 : 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: small ? 10 : 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class DifficultyChip extends StatelessWidget {
  final String difficulty;

  const DifficultyChip({super.key, required this.difficulty});

  Color get _color {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppTheme.accentGreen;
      case 'medium':
        return AppTheme.accentOrange;
      case 'hard':
        return AppTheme.accentRed;
      default:
        return Colors.grey;
    }
  }

  String get _label {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 'Mudah';
      case 'medium':
        return 'Sedang';
      case 'hard':
        return 'Sulit';
      default:
        return difficulty;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  final String tag;
  final bool deletable;
  final VoidCallback? onDelete;

  const TagChip({
    super.key,
    required this.tag,
    this.deletable = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$tag',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryDark,
            ),
          ),
          if (deletable) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDelete,
              child: Icon(                  // ← hapus 'const' di sini
                Icons.close_rounded,
                size: 14,
                color: AppTheme.primaryDark,
              ),
            ),
          ],
        ],
      ),
    );
  }
}