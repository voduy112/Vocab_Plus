import 'package:flutter/material.dart';

class AppBarActions extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPreview;
  final VoidCallback onSave;
  final String saveLabel;

  const AppBarActions({
    super.key,
    required this.isLoading,
    required this.onPreview,
    required this.onSave,
    required this.saveLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Xem trước',
          icon: const Icon(Icons.visibility_outlined, color: Colors.black),
          onPressed: onPreview,
        ),
        TextButton(
          onPressed: onSave,
          child: Text(
            saveLabel,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
