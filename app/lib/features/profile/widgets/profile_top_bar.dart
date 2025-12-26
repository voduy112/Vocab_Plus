import 'package:flutter/material.dart';

class ProfileTopBar extends StatelessWidget {
  final VoidCallback onBack;

  const ProfileTopBar({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _roundButton(
          context,
          icon: Icons.arrow_back,
          onTap: onBack,
        ),
        Text(
          'Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 48), // Placeholder để giữ căn giữa
      ],
    );
  }

  Widget _roundButton(
    BuildContext context, {
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 20,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
