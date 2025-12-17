import 'package:flutter/material.dart';

class PronunciationActionButtons extends StatelessWidget {
  final VoidCallback onVoiceCoach;
  final VoidCallback onRepeat;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final bool isRecording;
  final bool isEvaluating;
  final bool isLoadingAudio;
  final bool isMicLocked;

  const PronunciationActionButtons({
    super.key,
    required this.onVoiceCoach,
    required this.onRepeat,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.isRecording,
    required this.isEvaluating,
    required this.isLoadingAudio,
    required this.isMicLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SecondaryActionButton(
            icon: Icons.volume_up_rounded,
            label: 'Voice Coach',
            onTap: onVoiceCoach,
            isLoading: isLoadingAudio,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: PrimaryActionButton(
            isRecording: isRecording,
            isEvaluating: isEvaluating,
            isLocked: isMicLocked,
            onStartRecording: onStartRecording,
            onStopRecording: onStopRecording,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SecondaryActionButton(
            icon: Icons.restart_alt_rounded,
            label: 'Repeat',
            onTap: onRepeat,
          ),
        ),
      ],
    );
  }
}

class SecondaryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const SecondaryActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: isLoading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : Icon(
                      icon,
                      color: theme.colorScheme.primary,
                    ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrimaryActionButton extends StatelessWidget {
  final bool isRecording;
  final bool isEvaluating;
  final bool isLocked;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;

  const PrimaryActionButton({
    super.key,
    required this.isRecording,
    required this.isEvaluating,
    required this.isLocked,
    required this.onStartRecording,
    required this.onStopRecording,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDisabled = isEvaluating || isLocked;
    final backgroundColor = isRecording
        ? Colors.redAccent
        : isDisabled
            ? theme.colorScheme.primary.withOpacity(0.4)
            : theme.colorScheme.primary;
    return AspectRatio(
      aspectRatio: 1,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(32),
        elevation: 6,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: isDisabled
              ? null
              : (isRecording ? onStopRecording : onStartRecording),
          child: Center(
            child: isEvaluating
                ? const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : Icon(
                    isRecording
                        ? Icons.stop_rounded
                        : (isLocked
                            ? Icons.volume_up_rounded
                            : Icons.mic_rounded),
                    color: Colors.white,
                    size: 40,
                  ),
          ),
        ),
      ),
    );
  }
}
