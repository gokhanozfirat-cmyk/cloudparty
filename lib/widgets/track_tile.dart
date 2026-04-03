import 'package:flutter/material.dart';
import 'package:cloudparty/l10n/app_localizations.dart';

import '../main.dart';
import '../models/audio_track.dart';

enum TrackAction { addToPlaylist, download, toggleFavorite }

class TrackTile extends StatelessWidget {
  const TrackTile({
    super.key,
    required this.track,
    required this.onTap,
    required this.onAction,
    this.index,
    this.isFavorite = false,
  });

  final AudioTrack track;
  final VoidCallback onTap;
  final ValueChanged<TrackAction> onAction;
  final int? index;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final List<List<Color>> gradients = [
      [const Color(0xFF7C3AED), const Color(0xFF4F46E5)],
      [const Color(0xFFEC4899), const Color(0xFF8B5CF6)],
      [const Color(0xFF06B6D4), const Color(0xFF3B82F6)],
      [const Color(0xFF10B981), const Color(0xFF06B6D4)],
      [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
    ];
    final List<Color> gradientColors =
        gradients[(index ?? 0) % gradients.length];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[0].withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  track.isOffline
                      ? Icons.offline_pin_rounded
                      : Icons.music_note_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          track.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: track.isOffline
                                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                : AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            track.format.toUpperCase(),
                            style: TextStyle(
                              color: track.isOffline
                                  ? const Color(0xFF10B981)
                                  : AppColors.primaryLight,
                              fontSize: 9,
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
              PopupMenuButton<TrackAction>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                color: AppColors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.cardBorder),
                ),
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<TrackAction>>[
                  PopupMenuItem<TrackAction>(
                    value: TrackAction.addToPlaylist,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.playlist_add_rounded,
                          color: AppColors.primaryLight,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l10n.moveToPlaylist,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<TrackAction>(
                    value: TrackAction.download,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.download_rounded,
                          color: Color(0xFF10B981),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l10n.downloadForOffline,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<TrackAction>(
                    value: TrackAction.toggleFavorite,
                    child: Row(
                      children: [
                        Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFavorite
                              ? Colors.pinkAccent
                              : AppColors.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isFavorite ? l10n.removeFavorite : l10n.addFavorite,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: onAction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
