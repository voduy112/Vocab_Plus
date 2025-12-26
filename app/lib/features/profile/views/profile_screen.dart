// features/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/profile_option_tile.dart';
import '../widgets/profile_top_bar.dart';
import '../widgets/sync_status_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: ChangeNotifierProvider(
          create: (_) => ProfileController(),
          child: const _ProfileContent(),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final controller = context.watch<ProfileController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileTopBar(onBack: () => Navigator.of(context).maybePop()),
          const SizedBox(height: 24),
          ProfileHeaderCard(
            auth: auth,
            onSignIn: () async {
              await context.read<AuthController>().signInWithGoogle();
              await controller.ensureUserUpserted(context);
            },
          ),
          const SizedBox(height: 28),
          if (auth.isLoggedIn)
            ProfileOptionTile(
              icon: Icons.sync,
              label: 'Đồng bộ',
              onTap: controller.isSyncing
                  ? null
                  : () => controller.syncDataToCloud(context),
              trailing: controller.isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
          if (auth.isLoggedIn && controller.syncProgressMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                controller.syncProgressMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
          if (controller.lastSyncMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: SyncStatusCard(
                message: controller.lastSyncMessage!,
                success: controller.lastSyncSucceeded ?? false,
                stats: controller.lastSyncStats,
                syncTime: controller.lastSyncTime,
              ),
            ),
          ProfileOptionTile(
            icon: Icons.delete_forever_outlined,
            label: 'Xóa toàn bộ dữ liệu',
            onTap: () => controller.resetDatabase(context),
          ),
          if (auth.isLoggedIn)
            ProfileOptionTile(
              icon: Icons.logout,
              label: 'Đăng xuất',
              onTap: () => controller.signOut(context),
            ),
        ],
      ),
    );
  }
}
