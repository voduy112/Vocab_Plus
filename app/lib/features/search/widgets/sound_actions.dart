import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../data/dictionary/models.dart';
import '../services/sound_resolver_service.dart';

class SoundActions extends StatefulWidget {
  final WordEntry entry;
  const SoundActions({super.key, required this.entry});
  @override
  State<SoundActions> createState() => _SoundActionsState();
}

class _SoundActionsState extends State<SoundActions> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  WordSound? _findByTag(String tag) {
    final sounds = widget.entry.sounds ?? const <WordSound>[];
    final upper = tag.toUpperCase();
    final tagged = sounds.where((s) =>
        s.audio != null &&
        s.tags.any((t) => t.toString().toUpperCase() == upper));
    if (tagged.isNotEmpty) return tagged.first;
    final byName = sounds.where(
        (s) => (s.audio ?? '').toLowerCase().contains(upper.toLowerCase()));
    if (byName.isNotEmpty) return byName.first;
    return null;
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _playForTag(String tag) async {
    final sound = _findByTag(tag);
    final fileName = sound?.audio;
    if (fileName == null || fileName.isEmpty) return;
    setState(() => _isPlaying = true);
    final url = await SoundResolverService().resolveCommonsUrl(fileName);
    if (url != null) {
      await _player.stop();
      await _player.play(UrlSource(url));
    }
    setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasUS = _findByTag('US')?.audio != null;
    final hasUK = _findByTag('UK')?.audio != null;
    if (!hasUS && !hasUK) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasUS)
          _SoundIconButton(
            tooltip: 'US',
            isLoading: _isPlaying,
            onPressed: () => _playForTag('US'),
          ),
        if (hasUK)
          _SoundIconButton(
            tooltip: 'UK',
            isLoading: _isPlaying,
            onPressed: () => _playForTag('UK'),
          ),
      ],
    );
  }
}

class _SoundIconButton extends StatelessWidget {
  final String tooltip;
  final bool isLoading;
  final VoidCallback onPressed;
  const _SoundIconButton(
      {required this.tooltip,
      required this.isLoading,
      required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: const Icon(Icons.volume_up, size: 20),
      label: Text(tooltip),
      style: TextButton.styleFrom(
        foregroundColor: Colors.blue.shade800,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}
