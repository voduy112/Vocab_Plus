import 'package:flutter/material.dart';

class ContextMenuScaffold extends StatelessWidget {
  final Widget child;
  final double handleTopMargin;
  final Color backgroundColor;

  const ContextMenuScaffold({
    super.key,
    required this.child,
    this.handleTopMargin = 12,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(top: handleTopMargin),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
