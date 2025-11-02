// features/main/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_controller.dart';
import '../widgets/due_heat_map.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthController>().displayName;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day - 15);
    final end = DateTime(now.year, now.month + 2, now.day);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
            ),
            Text(
              name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_outlined),
                ),
                const Positioned(
                  right: 14,
                  top: 14,
                  child: CircleAvatar(
                      radius: 4, backgroundColor: Colors.redAccent),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Lưới chức năng (5 nút)
            GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1,
              children: [
                _FeatureTile(
                  icon: Icons.school_outlined,
                  label: 'Học',
                  bgColor: Theme.of(context).colorScheme.primaryContainer,
                  iconColor: Theme.of(context).colorScheme.primary,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đi tới Học')),
                    );
                  },
                ),
                _FeatureTile(
                  icon: Icons.repeat_outlined,
                  label: 'Ôn tập',
                  bgColor: Theme.of(context).colorScheme.secondaryContainer,
                  iconColor: Theme.of(context).colorScheme.secondary,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đi tới Ôn tập')),
                    );
                  },
                ),
                _FeatureTile(
                  icon: Icons.view_agenda_outlined,
                  label: 'Bộ thẻ',
                  bgColor: Theme.of(context).colorScheme.tertiaryContainer,
                  iconColor: Theme.of(context).colorScheme.tertiary,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đi tới Bộ thẻ')),
                    );
                  },
                ),
                _FeatureTile(
                  icon: Icons.search_outlined,
                  label: 'Tìm kiếm',
                  bgColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                  iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đi tới Tìm kiếm')),
                    );
                  },
                ),
                _FeatureTile(
                  icon: Icons.bar_chart_outlined,
                  label: 'Thống kê',
                  bgColor: Theme.of(context).colorScheme.primaryContainer,
                  iconColor: Theme.of(context).colorScheme.primary,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đi tới Thống kê')),
                    );
                  },
                ),
              ],
            ),
            // HeatMap hiển thị số lượng từ vựng cần học theo ngày
            const SizedBox(height: 16),
            DueHeatMap(start: start, end: end),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? bgColor;
  final Color? iconColor;

  const _FeatureTile(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.bgColor,
      this.iconColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: bgColor ?? theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor ?? theme.colorScheme.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
