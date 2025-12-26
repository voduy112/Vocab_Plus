import 'package:flutter/material.dart';

import '../../../core/services/sync_service.dart';

class SyncStatusCard extends StatelessWidget {
  final bool success;
  final String message;
  final SyncStats? stats;
  final DateTime? syncTime;

  const SyncStatusCard({
    super.key,
    required this.success,
    required this.message,
    required this.stats,
    required this.syncTime,
  });

  String _formatTime(DateTime? time) {
    if (time == null) return 'Thời gian không xác định';
    final local = time.toLocal();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(local.hour)}:${twoDigits(local.minute)} '
        '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        success ? Colors.green : theme.colorScheme.error.withOpacity(0.9);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error_outline,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Lần cuối: ${_formatTime(syncTime)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          if (stats != null) ...[
            const SizedBox(height: 8),
            _StatRow(label: 'Decks', value: stats!.decks),
            _StatRow(label: 'Từ vựng', value: stats!.vocabularies),
            _StatRow(label: 'SRS records', value: stats!.vocabularySrs),
            _StatRow(label: 'Phiên học', value: stats!.studySessions),
            _StatRow(label: 'Ảnh upload', value: stats!.imagesUploaded),
          ],
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int value;

  const _StatRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
          ),
          Text(
            value.toString(),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
