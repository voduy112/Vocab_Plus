import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_controller.dart';
import '../../notifications/widgets/notification_dialog.dart';

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
                // Khoảng trống cho notification icon (icon được đặt riêng trong home_screen)
                const SizedBox(width: 50),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Widget animation chung cho scroll
class ScrollAnimatedWidget extends StatelessWidget {
  final ScrollController scrollController;
  final Widget child;
  final double maxScroll;
  final double scaleFactor;
  final double translateYFactor;
  final double opacityFactor;
  final Alignment scaleAlignment;
  final bool clipRect;

  const ScrollAnimatedWidget({
    super.key,
    required this.scrollController,
    required this.child,
    this.maxScroll = 200.0,
    this.scaleFactor = 0.1,
    this.translateYFactor = 30.0,
    this.opacityFactor = 0.3,
    this.scaleAlignment = Alignment.topLeft,
    this.clipRect = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget animatedWidget = AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        final scrollOffset =
            scrollController.hasClients ? scrollController.offset : 0.0;
        final scrollProgress = (scrollOffset / maxScroll).clamp(0.0, 1.0);
        final scale = 1.0 - (scrollProgress * scaleFactor);
        final translateY = -scrollProgress * translateYFactor;
        final opacity = 1.0 - (scrollProgress * opacityFactor);

        return Transform.translate(
          offset: Offset(0, translateY),
          child: Transform.scale(
            scale: scale,
            alignment: scaleAlignment,
            child: Opacity(
              opacity: opacity,
              child: child!,
            ),
          ),
        );
      },
      child: child,
    );

    return clipRect ? ClipRect(child: animatedWidget) : animatedWidget;
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

    return ScrollAnimatedWidget(
      scrollController: scrollController,
      maxScroll: 100.0, // Giảm maxScroll để icon ẩn nhanh hơn
      scaleFactor: 0.2,
      translateYFactor: 50.0, // Icon di chuyển lên trên khi scroll lên
      opacityFactor: 1.0,
      scaleAlignment: Alignment.topLeft,
      clipRect: true,
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
    return ScrollAnimatedWidget(
      scrollController: scrollController,
      maxScroll: 100.0, // Giảm maxScroll để icon ẩn nhanh hơn
      scaleFactor: 0.2,
      translateYFactor: 50.0, // Icon di chuyển lên trên khi scroll lên
      opacityFactor: 1.0, // Icon ẩn hoàn toàn khi scroll lên một đoạn
      scaleAlignment: Alignment.topRight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          NotificationDialog.show(context);
        },
        child: Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.all(8),
          width: 50,
          height: 50,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                NotificationDialog.show(context);
              },
              borderRadius: BorderRadius.circular(25),
              splashColor: Colors.white.withOpacity(0.2),
              highlightColor: Colors.white.withOpacity(0.1),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                  // Badge hiển thị số thông báo chưa đọc (có thể thêm logic sau)
                  // Positioned(
                  //   right: 5,
                  //   top: 5,
                  //   child: IgnorePointer(
                  //     child: CircleAvatar(
                  //       radius: 5,
                  //       backgroundColor: Colors.redAccent,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
