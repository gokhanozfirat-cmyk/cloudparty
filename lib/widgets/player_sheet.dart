import 'package:flutter/material.dart';
import 'package:cloudparty/l10n/app_localizations.dart';
import 'package:just_audio/just_audio.dart';

import '../main.dart';
import '../state/app_state.dart';

class PlayerSheet extends StatelessWidget {
  const PlayerSheet({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final track = state.currentTrack;
    if (track == null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.music_off_rounded, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              l10n.noTrackSelected,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Album art
              Center(
                child: Container(
                  width: double.infinity,
                  height: 220,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF2D1B69),
                        Color(0xFF1E0A3C),
                        Color(0xFF3D0A3C),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background glow circles
                      Positioned(
                        top: 20,
                        left: 30,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 30,
                        right: 40,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.secondary.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                      // Main icon
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              blurRadius: 24,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Track info
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              track.artist,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                track.format.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.primaryLight,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Progress
              _ProgressSection(state: state),

              const SizedBox(height: 16),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _ControlButton(
                    icon: Icons.skip_previous_rounded,
                    onTap: state.playPrevious,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: state.togglePlayback,
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        state.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _ControlButton(
                    icon: Icons.skip_next_rounded,
                    onTap: state.playNext,
                    size: 28,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Shuffle & Repeat
              Row(
                children: <Widget>[
                  Expanded(
                    child: _ToggleChip(
                      icon: Icons.shuffle_rounded,
                      label: l10n.shuffle,
                      selected: state.shuffleEnabled,
                      onTap: state.toggleShuffle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ToggleChip(
                      icon: _repeatIcon(state.loopMode),
                      label: l10n.repeatMode(_repeatLabel(l10n, state.loopMode)),
                      selected: state.loopMode != LoopMode.off,
                      onTap: state.cycleRepeatMode,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Speed
              _SectionLabel(label: l10n.speed),
              const SizedBox(height: 10),
              Row(
                children: <double>[0.5, 1.0, 1.5, 2.0, 3.0]
                    .map(
                      (double value) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _SpeedChip(
                            value: value,
                            selected: state.speed == value,
                            onTap: () => state.setSpeed(value),
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),

              const SizedBox(height: 20),

              // Sleep timer
              _SectionLabel(label: l10n.sleepTimer),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <_TimerOption>[
                  const _TimerOption(
                    label: '15m',
                    duration: Duration(minutes: 15),
                  ),
                  const _TimerOption(
                    label: '30m',
                    duration: Duration(minutes: 30),
                  ),
                  const _TimerOption(
                    label: '60m',
                    duration: Duration(hours: 1),
                  ),
                  const _TimerOption(
                    label: '90m',
                    duration: Duration(minutes: 90),
                  ),
                  _TimerOption(label: l10n.timerOff, duration: null),
                ]
                    .map(
                      (_TimerOption option) => _TimerChip(
                        label: option.label,
                        selected: _isTimerSelected(
                          state.sleepEndsAt,
                          option.duration,
                        ),
                        onTap: () => state.setSleepTimer(option.duration),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _repeatIcon(LoopMode mode) {
    switch (mode) {
      case LoopMode.one:
        return Icons.repeat_one_rounded;
      default:
        return Icons.repeat_rounded;
    }
  }

  bool _isTimerSelected(DateTime? sleepEndsAt, Duration? duration) {
    if (duration == null) {
      return sleepEndsAt == null;
    }
    if (sleepEndsAt == null) {
      return false;
    }
    final Duration delta = sleepEndsAt.difference(DateTime.now());
    return (delta.inMinutes - duration.inMinutes).abs() <= 1;
  }

  String _repeatLabel(AppLocalizations l10n, LoopMode mode) {
    switch (mode) {
      case LoopMode.off:
        return l10n.repeatOff;
      case LoopMode.all:
        return l10n.repeatAll;
      case LoopMode.one:
        return l10n.repeatOne;
    }
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.size = 24,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: size),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.primaryLight : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.primaryLight : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeedChip extends StatelessWidget {
  const _SpeedChip({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final double value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.cardBorder,
          ),
        ),
        child: Center(
          child: Text(
            '${value.toStringAsFixed(1)}x',
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimerChip extends StatelessWidget {
  const _TimerChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.secondary.withValues(alpha: 0.2)
              : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.secondary : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.secondary : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: state.durationStream,
      builder: (BuildContext context, AsyncSnapshot<Duration?> durationSnapshot) {
        final Duration total = durationSnapshot.data ?? Duration.zero;

        return StreamBuilder<Duration>(
          stream: state.positionStream,
          builder: (
            BuildContext context,
            AsyncSnapshot<Duration> positionSnapshot,
          ) {
            final Duration position = positionSnapshot.data ?? Duration.zero;
            final double max =
                total.inMilliseconds.toDouble().clamp(1, double.infinity);
            final double value =
                position.inMilliseconds.toDouble().clamp(0, max);

            return Column(
              children: <Widget>[
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 16,
                    ),
                  ),
                  child: Slider(
                    value: value,
                    max: max,
                    onChanged: (double next) {
                      state.player.seek(
                        Duration(milliseconds: next.round()),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        _formatDuration(position),
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatDuration(total),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final String minutes = twoDigits(duration.inMinutes.remainder(60));
    final String seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

class _TimerOption {
  const _TimerOption({required this.label, required this.duration});

  final String label;
  final Duration? duration;
}
