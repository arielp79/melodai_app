import 'package:flutter/material.dart';

import '../../domain/entities/mixer_channel_state.dart';

class MixerChannelStrip extends StatelessWidget {
  const MixerChannelStrip({
    super.key,
    required this.channel,
    required this.onVolumeChanged,
    required this.onMuteToggled,
    required this.onSoloToggled,
    this.enabled = true,
  });

  final MixerChannelState channel;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onMuteToggled;
  final VoidCallback onSoloToggled;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playable = channel.isPlayable && enabled;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    channel.label,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (!playable)
                  Text(
                    'sin audio',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
            if (channel.loadError != null) ...[
              const SizedBox(height: 4),
              Text(
                channel.loadError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                _MixerToggleButton(
                  label: 'M',
                  active: channel.muted,
                  onPressed: playable ? onMuteToggled : null,
                  activeColor: theme.colorScheme.errorContainer,
                ),
                const SizedBox(width: 8),
                _MixerToggleButton(
                  label: 'S',
                  active: channel.solo,
                  onPressed: playable ? onSoloToggled : null,
                  activeColor: theme.colorScheme.primaryContainer,
                ),
                const SizedBox(width: 12),
                Text(
                  '${(channel.volume * 100).round()}%',
                  style: theme.textTheme.labelMedium,
                ),
                Expanded(
                  child: Slider(
                    value: channel.volume,
                    onChanged: playable ? onVolumeChanged : null,
                    min: 0,
                    max: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MixerToggleButton extends StatelessWidget {
  const _MixerToggleButton({
    required this.label,
    required this.active,
    required this.onPressed,
    required this.activeColor,
  });

  final String label;
  final bool active;
  final VoidCallback? onPressed;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? activeColor : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: active
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
