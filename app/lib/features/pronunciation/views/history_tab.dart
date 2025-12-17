import 'package:flutter/material.dart';

import '../../../core/models/pronunciation_session_history.dart';
import '../services/pronunciation_session_history_service.dart';

class PronunciationHistoryTab extends StatefulWidget {
  const PronunciationHistoryTab({super.key});

  @override
  State<PronunciationHistoryTab> createState() =>
      _PronunciationHistoryTabState();
}

class _PronunciationHistoryTabState extends State<PronunciationHistoryTab> {
  final PronunciationSessionHistoryService _historyService =
      PronunciationSessionHistoryService();
  late Future<List<PronunciationSessionHistory>> _futureSessions;

  @override
  void initState() {
    super.initState();
    _futureSessions = _load();
  }

  Future<List<PronunciationSessionHistory>> _load() {
    return _historyService.getRecent(limit: 50);
  }

  Future<void> _refresh() async {
    final sessions = await _load();
    if (!mounted) return;
    setState(() {
      _futureSessions = Future.value(sessions);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PronunciationSessionHistory>>(
      future: _futureSessions,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _HistoryError(
            message: 'Không thể tải lịch sử: ${snapshot.error}',
            onRetry: _refresh,
          );
        }

        final sessions = snapshot.data ?? [];
        if (sessions.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                _HistoryEmpty(),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final session = sessions[index];

              // Nếu session chưa có id (trường hợp ngoại lệ), không cho swipe xoá
              if (session.id == null) {
                return _HistorySessionCard(
                  session: session,
                  onTap: () => _showSessionSummary(context, session),
                );
              }

              return Dismissible(
                key: ValueKey('pron_sess_${session.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [
                      Icon(Icons.delete_outline_rounded, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Xoá',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Xoá lịch sử phiên này?'),
                        content: const Text(
                          'Bạn có chắc chắn muốn xoá lịch sử phiên luyện này? '
                          'Thao tác này không thể hoàn tác.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Xoá'),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) async {
                  if (session.id != null) {
                    await _historyService.deleteById(session.id!);
                    if (mounted) {
                      _refresh();
                    }
                  }
                },
                child: _HistorySessionCard(
                  session: session,
                  onTap: () => _showSessionSummary(context, session),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showSessionSummary(
      BuildContext context, PronunciationSessionHistory session) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text(
                'Tổng kết phiên luyện',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bạn đã luyện ${session.practicedWords} / ${session.totalWords} từ trong bộ "${session.deckName}".',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _SummaryStatChip(
                    label: 'Điểm trung bình',
                    value: session.avgOverall,
                    color: Colors.indigo,
                  ),
                  const SizedBox(width: 8),
                  _SummaryStatChip(
                    label: 'Độ chính xác',
                    value: session.avgAccuracy,
                    color: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _SummaryStatChip(
                    label: 'Độ trôi chảy',
                    value: session.avgFluency,
                    color: Colors.purple,
                  ),
                  const SizedBox(width: 8),
                  _SummaryStatChip(
                    label: 'Độ đầy đủ',
                    value: session.avgCompleteness,
                    color: Colors.teal,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.emoji_events_rounded,
                      size: 20, color: Colors.green[600]),
                  const SizedBox(width: 6),
                  Text(
                    '${session.highCount} từ đạt ≥ 80 điểm',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.flag_rounded, size: 20, color: Colors.orange[700]),
                  const SizedBox(width: 6),
                  Text(
                    '${session.lowCount} từ dưới 60 điểm (cần luyện thêm)',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Đóng bottom sheet
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Hoàn thành',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HistorySessionCard extends StatelessWidget {
  const _HistorySessionCard({
    required this.session,
    required this.onTap,
  });

  final PronunciationSessionHistory session;
  final VoidCallback onTap;

  Color _scoreColor(double score, BuildContext context) {
    if (score >= 80) return Colors.green.shade600;
    if (score >= 60) return Colors.orange.shade600;
    return Theme.of(context).colorScheme.error;
  }

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    if (diff.inDays == 0) {
      return 'Hôm nay $hour:$minute';
    }
    if (diff.inDays == 1) {
      return 'Hôm qua $hour:$minute';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final overallColor = _scoreColor(session.avgOverall, context);
    final practicedLabel =
        '${session.practicedWords}/${session.totalWords} từ đã luyện';

    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      session.deckName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: overallColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${session.avgOverall.toStringAsFixed(0)} điểm',
                      style: TextStyle(
                        color: overallColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                practicedLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _MiniStatChip(
                    label: 'Chính xác',
                    value: session.avgAccuracy,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _MiniStatChip(
                    label: 'Trôi chảy',
                    value: session.avgFluency,
                    color: Colors.purple,
                  ),
                  const SizedBox(width: 8),
                  _MiniStatChip(
                    label: 'Đầy đủ',
                    value: session.avgCompleteness,
                    color: Colors.teal,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.emoji_events_rounded,
                      size: 18, color: Colors.green[600]),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${session.highCount} từ ≥ 80 điểm',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.flag_rounded, size: 18, color: Colors.orange[700]),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${session.lowCount} từ < 60 điểm',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _formatTimestamp(session.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryStatChip extends StatelessWidget {
  const _SummaryStatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              value.toStringAsFixed(1),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStatChip extends StatelessWidget {
  const _MiniStatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              value.toStringAsFixed(0),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.history_rounded, size: 48, color: Colors.grey),
        const SizedBox(height: 12),
        Text(
          'Chưa có lịch sử học',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Hoàn thành một phiên luyện để xem lịch sử tại đây.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
