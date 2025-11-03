import 'dart:async';
import 'package:flutter/material.dart';
// Removed third-party calendar builder; implementing a custom lightweight heatmap below
import '../../decks/services/vocabulary_service.dart';

class DueHeatMap extends StatefulWidget {
  final DateTime start;
  final DateTime end;
  final int? deckId;

  const DueHeatMap(
      {super.key, required this.start, required this.end, this.deckId});

  @override
  State<DueHeatMap> createState() => _DueHeatMapState();
}

class _DueHeatMapState extends State<DueHeatMap>
    with AutomaticKeepAliveClientMixin<DueHeatMap> {
  late DateTime _viewStart;
  late DateTime _viewEnd;
  // Static cache to persist across route changes and widget rebuilds
  // Cache key: "deckId_year" -> Map<DateTime, int>
  static final Map<String, Map<DateTime, int>> _cacheMap = {};
  static final Map<String, Set<int>> _yearsCachedMap = {};
  bool _isLoading = true;
  DateTime? _selectedDate;
  final Map<DateTime, GlobalKey> _cellKeys = {};
  OverlayEntry? _tooltipEntry;
  Timer? _tooltipTimer;

  String get _yearsCacheKey => '${widget.deckId ?? 'all'}';
  Map<DateTime, int> get _cache => _cacheMap[_yearsCacheKey] ?? {};
  Set<int> get _yearsCached => _yearsCachedMap[_yearsCacheKey] ?? {};

  @override
  void initState() {
    super.initState();
    _viewStart = widget.start;
    _viewEnd = widget.end;
    // Initialize cache for this deck if not exists
    if (!_cacheMap.containsKey(_yearsCacheKey)) {
      _cacheMap[_yearsCacheKey] = {};
      _yearsCachedMap[_yearsCacheKey] = {};
    }
    // If current year is already cached, render instantly
    if (_yearsCached.contains(_viewStart.year)) {
      _isLoading = false;
    } else {
      _primeCache();
    }
  }

  @override
  void didUpdateWidget(covariant DueHeatMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Always ensure latest data by invalidating cache for this deck and reloading
    if (widget.deckId != oldWidget.deckId ||
        widget.start != oldWidget.start ||
        widget.end != oldWidget.end) {
      _viewStart = widget.start;
      _viewEnd = widget.end;
    }
    _invalidateCacheForKey(_yearsCacheKey);
    setState(() {
      _isLoading = true;
    });
    _primeCache();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _tooltipTimer?.cancel();
    _tooltipTimer = null;
    _tooltipEntry?.remove();
    _tooltipEntry = null;
    super.dispose();
  }

  Future<void> _primeCache() async {
    final int currentYear = _viewStart.year;
    await _loadYear(currentYear);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
    // Prefetch adjacent years without blocking UI
    _loadYear(currentYear - 1);
    _loadYear(currentYear + 1);
  }

  Future<void> _loadYear(int year) async {
    if (_yearsCached.contains(year)) return;
    final DateTime yStart = DateTime(year, 1, 1);
    final DateTime yEnd = DateTime(year, 12, 31);
    final vocabService = VocabularyService();
    final Map<DateTime, int> data = await vocabService.getDueCountsByDateRange(
        start: yStart, end: yEnd, deskId: widget.deckId);
    // Merge into cache for this deck
    if (!_cacheMap.containsKey(_yearsCacheKey)) {
      _cacheMap[_yearsCacheKey] = {};
      _yearsCachedMap[_yearsCacheKey] = {};
    }
    final deckCache = _cacheMap[_yearsCacheKey]!;
    data.forEach((date, count) {
      final DateTime key = DateTime(date.year, date.month, date.day);
      deckCache[key] = count;
    });
    _yearsCachedMap[_yearsCacheKey]!.add(year);
    if (mounted) setState(() {});
  }

  // Invalidate cache for a specific key (deck/all) so the next load fetches fresh data
  void _invalidateCacheForKey(String key) {
    _cacheMap.remove(key);
    _yearsCachedMap.remove(key);
  }

  // Deprecated fetch call replaced by cached loading

  void _shiftRangeByYear(int deltaYears) {
    // If the provided range spans roughly a year, jump year-by-year.
    final int totalDays = _viewEnd.difference(_viewStart).inDays + 1;
    final bool isAnnual = totalDays >= 360 && totalDays <= 370;
    if (isAnnual) {
      final DateTime newStart = DateTime(_viewStart.year + deltaYears, 1, 1);
      final DateTime newEnd = DateTime(_viewStart.year + deltaYears, 12, 31);
      setState(() {
        _viewStart = newStart;
        _viewEnd = newEnd;
      });
      // Ensure target year is cached in background
      _loadYear(newStart.year);
    } else {
      // Otherwise, shift by the same number of days as the current window.
      final Duration delta = Duration(days: totalDays * deltaYears);
      setState(() {
        _viewStart = _viewStart.add(delta);
        _viewEnd = _viewEnd.add(delta);
      });
    }
  }

  void _removeTooltip() {
    _tooltipTimer?.cancel();
    _tooltipTimer = null;
    _tooltipEntry?.remove();
    _tooltipEntry = null;
  }

  void _showTooltip(BuildContext context, DateTime date, int count) {
    _removeTooltip();
    final DateTime keyDate = DateTime(date.year, date.month, date.day);
    final GlobalKey? cellKey = _cellKeys[keyDate];
    if (cellKey == null || cellKey.currentContext == null) return;
    final RenderBox box =
        cellKey.currentContext!.findRenderObject() as RenderBox;
    final Offset topCenter = box.localToGlobal(Offset(box.size.width / 2, 0));

    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final String dateLine =
        '${weekdays[date.weekday - 1]} ${months[date.month - 1]} ${date.day}, ${date.year}';

    // Calculate tooltip position: center horizontally, place above cell with small gap
    const double tooltipWidth = 263.0;
    const double estimatedTooltipHeight =
        50.0; // Estimated: container ~66px + arrow ~12px
    const double gap = 10.0;

    final double tooltipTop = topCenter.dy - estimatedTooltipHeight - gap;
    final double screenWidth = MediaQuery.of(context).size.width;
    const double screenPadding = 8.0;
    final double idealLeft = topCenter.dx - (tooltipWidth / 2);
    final double minLeft = screenPadding;
    final double maxLeft = screenWidth - tooltipWidth - screenPadding;
    final double clampedLeft = idealLeft.clamp(minLeft, maxLeft);

    _tooltipEntry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                setState(() {
                  _selectedDate = null;
                });
                _removeTooltip();
              },
            ),
          ),
          Positioned(
            left: clampedLeft,
            top: tooltipTop,
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: tooltipWidth),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 8,
                            offset: Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.white),
                            children: [
                              TextSpan(
                                  text: '$count ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              TextSpan(text: count == 1 ? 'card ' : 'cards '),
                              const TextSpan(
                                  text: 'reviewed',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(dateLine,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_tooltipEntry!);

    // Tự động tắt tooltip sau 5 giây
    _tooltipTimer?.cancel();
    _tooltipTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _tooltipEntry != null) {
        setState(() {
          _selectedDate = null;
        });
        _removeTooltip();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final Color backgroundColor = theme.colorScheme.secondaryContainer;
    final Color heatBaseColor = theme.colorScheme.primary;

    return Container(
      clipBehavior: Clip.none,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header similar to the screenshot: big year + navigation arrows
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_viewStart.year}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Heatmap Reviewed Cards',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _NavButton(
                icon: Icons.chevron_left,
                onPressed: () => _shiftRangeByYear(-1),
                background: theme.colorScheme.surface.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              _NavButton(
                icon: Icons.chevron_right,
                onPressed: () => _shiftRangeByYear(1),
                background: theme.colorScheme.surface.withOpacity(0.6),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Builder(builder: (context) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = _cache;
            final DateTime today = DateTime.now();

            Color _cellColor(int? value) {
              // 0 -> neutral from surfaceContainerHigh (no activity)
              // 1-2 -> light, 3-5 -> medium, 6-9 -> strong, 10+ -> strongest
              if (value == null || value == 0) {
                return theme.colorScheme.surfaceContainerHigh;
              }
              final int v = value;
              final int level = v >= 10
                  ? 4
                  : v >= 6
                      ? 3
                      : v >= 3
                          ? 2
                          : 1;

              // Opacity steps chosen for good contrast on secondaryContainer background
              const List<double> opacities = [0.05, 0.25, 0.5, 0.75, 1.0];
              return heatBaseColor.withOpacity(opacities[level]);
            }

            // Build a simple GitHub-like weekly heatmap with Sunday on top
            const double cellSize = 19;
            const double gap = 4;

            DateTime _firstSunday(DateTime d) {
              final int daysToSunday = d.weekday % 7; // Sun=7 -> 0
              return DateTime(d.year, d.month, d.day)
                  .subtract(Duration(days: daysToSunday));
            }

            DateTime _lastSaturday(DateTime d) {
              final int daysToSaturday = (6 - (d.weekday % 7) + 7) % 7;
              final DateTime base = DateTime(d.year, d.month, d.day);
              return base.add(Duration(days: daysToSaturday));
            }

            final DateTime start = _firstSunday(_viewStart);
            final DateTime end = _lastSaturday(_viewEnd);

            List<List<DateTime>> _weeks() {
              final List<List<DateTime>> weeks = [];
              DateTime cursor = start;
              while (!cursor.isAfter(end)) {
                final List<DateTime> column =
                    List.generate(7, (i) => cursor.add(Duration(days: i)));
                weeks.add(column);
                cursor = cursor.add(const Duration(days: 7));
              }
              return weeks;
            }

            final weeks = _weeks();

            // Tooltip content is rendered via OverlayEntry; helpers inlined there.

            Widget _monthLabels() {
              const months = [
                'Jan',
                'Feb',
                'Mar',
                'Apr',
                'May',
                'Jun',
                'Jul',
                'Aug',
                'Sep',
                'Oct',
                'Nov',
                'Dec'
              ];
              final double colWidth = cellSize + gap;
              final List<Widget> segments = [];
              int i = 0;
              while (i < weeks.length) {
                final int m = weeks[i][0].month;
                int j = i;
                while (j < weeks.length && weeks[j][0].month == m) {
                  j++;
                }
                final double segmentWidth = (j - i) * colWidth;
                segments.add(Container(
                  width: segmentWidth,
                  padding: EdgeInsets.only(left: gap / 2),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    months[m - 1],
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ));
                i = j;
              }

              // Width placeholder for weekday labels + spacing before weeks
              final double leftGutter = (cellSize + gap) + 6;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: leftGutter),
                  ...segments,
                ],
              );
            }

            // Horizontal header removed in favor of vertical weekday labels at left

            Widget _weekdayLabelsVertical() {
              const labels = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
              return Column(
                children: List.generate(7, (i) {
                  return Container(
                    width: cellSize,
                    height: cellSize,
                    margin: const EdgeInsets.all(gap / 2),
                    alignment: Alignment.center,
                    child: Text(
                      labels[i],
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }),
              );
            }

            Widget _buildCell(DateTime date) {
              final bool isInRange =
                  !date.isBefore(_viewStart) && !date.isAfter(_viewEnd);
              final int? value =
                  data[DateTime(date.year, date.month, date.day)];
              final bool isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final bool isSelected = _selectedDate != null &&
                  _selectedDate!.year == date.year &&
                  _selectedDate!.month == date.month &&
                  _selectedDate!.day == date.day;
              return GestureDetector(
                onTap: () {
                  final int count = value ?? 0;
                  setState(() {
                    if (isSelected) {
                      _selectedDate = null; // toggle off
                    } else {
                      _selectedDate = DateTime(date.year, date.month, date.day);
                    }
                  });
                  _showTooltip(context, date, count);
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      key: _cellKeys.putIfAbsent(
                          DateTime(date.year, date.month, date.day),
                          () => GlobalKey()),
                      width: cellSize,
                      height: cellSize,
                      margin: const EdgeInsets.all(gap / 2),
                      decoration: BoxDecoration(
                        color: isInRange
                            ? _cellColor(value)
                            : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(4)),
                        border: isSelected
                            ? Border.all(
                                color: theme.colorScheme.tertiary, width: 2.2)
                            : isToday
                                ? Border.all(color: Colors.blue, width: 2.5)
                                : null,
                      ),
                    ),
                    // Tooltip shown via OverlayEntry; nothing inline here
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _monthLabels(),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left padding + vertical weekday labels
                      _weekdayLabelsVertical(),
                      ...weeks.map((column) => Column(
                            children: column.map(_buildCell).toList(),
                          )),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color background;

  const _NavButton({
    required this.icon,
    required this.onPressed,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}
