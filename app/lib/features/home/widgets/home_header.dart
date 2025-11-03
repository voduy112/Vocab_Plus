import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_controller.dart';

// Widget Header với gradient
class HomeHeader extends StatelessWidget {
  final ScrollController scrollController;

  const HomeHeader({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthController>().displayName;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 16, 100.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade400,
              Colors.pink.shade200,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome text bên trái (có hiệu ứng)
                Expanded(
                  child: AnimatedWelcomeText(
                    scrollController: scrollController,
                    name: name,
                  ),
                ),
                // Notification icon bên phải (có hiệu ứng)
                AnimatedNotificationIcon(
                  scrollController: scrollController,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Widget Welcome Text có hiệu ứng khi scroll
class AnimatedWelcomeText extends StatelessWidget {
  final ScrollController scrollController;
  final String name;

  const AnimatedWelcomeText({
    super.key,
    required this.scrollController,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRect(
      child: AnimatedBuilder(
        animation: scrollController,
        builder: (context, child) {
          final scrollOffset =
              scrollController.hasClients ? scrollController.offset : 0.0;
          final maxScroll = 200.0;
          final scrollProgress = (scrollOffset / maxScroll).clamp(0.0, 1.0);
          final scale = 1.0 - (scrollProgress * 0.1);
          final translateY = -scrollProgress * 30.0;
          final opacity = 1.0 - (scrollProgress * 0.3);

          return Transform.translate(
            offset: Offset(0, translateY),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topLeft,
              child: Opacity(
                opacity: opacity,
                child: child!,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// Widget Notification Icon có hiệu ứng khi scroll
class AnimatedNotificationIcon extends StatelessWidget {
  final ScrollController scrollController;

  const AnimatedNotificationIcon({
    super.key,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: scrollController,
        builder: (context, child) {
          final scrollOffset =
              scrollController.hasClients ? scrollController.offset : 0.0;
          final maxScroll = 200.0;
          final scrollProgress = (scrollOffset / maxScroll).clamp(0.0, 1.0);
          final scale = 1.0 - (scrollProgress * 0.1);
          final translateY = -scrollProgress * 30.0;
          final opacity = 1.0 - (scrollProgress * 0.3);

          return Transform.translate(
            offset: Offset(0, translateY),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topRight,
              child: Opacity(
                opacity: opacity,
                child: child!,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(top: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const Positioned(
                    right: 6,
                    top: 6,
                    child: CircleAvatar(
                      radius: 5,
                      backgroundColor: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
