import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';

class ProfileHeaderCard extends StatelessWidget {
  final AuthController auth;
  final VoidCallback onSignIn;

  const ProfileHeaderCard({
    super.key,
    required this.auth,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isLoggedIn = auth.isLoggedIn;
    final String displayName = isLoggedIn &&
            auth.displayName.trim().isNotEmpty &&
            auth.displayName.toLowerCase() != 'guest'
        ? auth.displayName
        : 'Khách';
    final String subtitle =
        isLoggedIn && (auth.email != null && auth.email!.trim().isNotEmpty)
            ? auth.email!.trim()
            : 'Chưa đăng nhập';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage:
                    auth.photoURL != null ? NetworkImage(auth.photoURL!) : null,
                backgroundColor: Colors.yellow.shade400,
                child: auth.photoURL == null
                    ? const Icon(
                        Icons.sentiment_satisfied_alt,
                        size: 32,
                        color: Colors.black87,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isLoggedIn) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Đăng nhập Google'),
                onPressed: onSignIn,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
