// features/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/api/api_client.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            CircleAvatar(
                radius: 36,
                backgroundImage: auth.photoURL != null
                    ? NetworkImage(auth.photoURL!)
                    : null),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(auth.displayName,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              Text(auth.isLoggedIn ? 'Logged in' : 'Guest'),
            ])
          ]),
          const SizedBox(height: 16),
          if (!auth.isLoggedIn)
            FilledButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Đăng nhập Google'),
              onPressed: () async {
                await context.read<AuthController>().signInWithGoogle();
                final api = ApiClient('http://10.0.2.2:5000');
                await api.dio.post('/users/me/upsert'); // upsert hồ sơ
                if (context.mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã đăng nhập & upsert')));
              },
            )
          else
            OutlinedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
              onPressed: () => context.read<AuthController>().signOut(),
            ),
          const SizedBox(height: 24),
          const ListTile(
              leading: Icon(Icons.settings_outlined),
              title: Text('Settings'),
              trailing: Icon(Icons.chevron_right)),
          const ListTile(
              leading: Icon(Icons.notifications_none),
              title: Text('Notifications'),
              trailing: Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}
