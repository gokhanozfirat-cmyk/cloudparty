import 'package:flutter/material.dart';
import 'package:cloudparty/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../l10n/cloud_platform_texts.dart';
import '../main.dart';
import '../models/audio_track.dart';
import '../models/cloud_models.dart';
import '../models/playlist_model.dart';
import '../state/app_state.dart';
import '../widgets/player_sheet.dart';
import '../widgets/track_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, state, l10n),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: !state.isInitialized
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              )
            : IndexedStack(
                index: _tabIndex,
                children: <Widget>[
                  _CloudsTab(
                    onConnectPressed: () => _showConnectSheet(context, state),
                    onSyncPressed: (String id) =>
                        _syncConnection(context, state, id),
                    onManualTrackPressed: (String id) =>
                        _showManualTrackDialog(context, state, id),
                  ),
                  _LibraryTab(
                    onPlayTrack: (AudioTrack track) => state.playTrack(track),
                    onAction: (AudioTrack track, TrackAction action) =>
                        _handleTrackAction(context, state, track, action),
                  ),
                  _PlaylistsTab(
                    onCreatePressed: () =>
                        _showCreatePlaylistDialog(context, state),
                    onToggleAutoplay: (String id, bool value) =>
                        state.setPlaylistAutoplay(id, value),
                    onPlayPlaylist: (String id) => state.playPlaylist(id),
                    onOpenPlaylist: (PlaylistModel playlist) =>
                        _openPlaylistDetails(context, state, playlist),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (state.currentTrack != null)
            _MiniPlayerBar(
              state: state,
              onOpen: () => _showPlayerSheet(context, state),
            ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(
                top: BorderSide(color: AppColors.cardBorder, width: 0.5),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _tabIndex,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              onDestinationSelected: (int value) {
                setState(() {
                  _tabIndex = value;
                });
              },
              destinations: <NavigationDestination>[
                NavigationDestination(
                  icon: const Icon(Icons.cloud_outlined),
                  selectedIcon: const Icon(Icons.cloud_rounded),
                  label: l10n.navClouds,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.library_music_outlined),
                  selectedIcon: const Icon(Icons.library_music_rounded),
                  label: l10n.navLibrary,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.queue_music_outlined),
                  selectedIcon: const Icon(Icons.queue_music_rounded),
                  label: l10n.navPlaylists,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppState state,
    AppLocalizations l10n,
  ) {
    return AppBar(
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.background,
              AppColors.background.withValues(alpha: 0.0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
      title: ShaderMask(
        shaderCallback: (bounds) =>
            AppColors.primaryGradient.createShader(bounds),
        child: Text(
          l10n.appTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: -1,
          ),
        ),
      ),
      actions: <Widget>[
        PopupMenuButton<String>(
          tooltip: l10n.languageLabel,
          icon: const Icon(Icons.language_rounded, color: AppColors.textSecondary),
          onSelected: (String code) {
            state.setLocaleCode(code);
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'tr',
              child: Text(l10n.languageTurkish),
            ),
            PopupMenuItem<String>(
              value: 'en',
              child: Text(l10n.languageEnglish),
            ),
          ],
        ),
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            onPressed: () => _showPlayerSheet(context, state),
            icon: const Icon(Icons.graphic_eq_rounded),
            tooltip: l10n.playerControlsTooltip,
            style: IconButton.styleFrom(
              foregroundColor: AppColors.primaryLight,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _syncConnection(
    BuildContext context,
    AppState state,
    String id,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    try {
      await state.syncConnection(id);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('syncConnection error: $error');
      }
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.cloudSyncFailed)));
      return;
    }
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.cloudSynced)));
  }

  Future<void> _handleTrackAction(
    BuildContext context,
    AppState state,
    AudioTrack track,
    TrackAction action,
  ) async {
    switch (action) {
      case TrackAction.addToPlaylist:
        await _showPlaylistPicker(context, state, track);
        break;
      case TrackAction.download:
        await _downloadTrack(context, state, track.id);
        break;
    }
  }

  Future<void> _downloadTrack(
    BuildContext context,
    AppState state,
    String trackId,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    try {
      await state.downloadTrack(trackId);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.trackDownloadedOffline)));
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.downloadFailed)));
    }
  }

  Future<void> _showConnectSheet(BuildContext context, AppState state) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    final CloudPlatform? platform = await showModalBottomSheet<CloudPlatform>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.card,
      builder: (BuildContext context) {
        final AppLocalizations l10n = AppLocalizations.of(context)!;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Text(
                  l10n.connectAnotherCloud,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: CloudPlatform.values
                      .map(
                        (CloudPlatform item) => _CloudPlatformTile(
                          item: item,
                          l10n: l10n,
                          onTap: () => Navigator.of(context).pop(item),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (platform == null) {
      return;
    }

    try {
      await state.connectPlatform(
        platform,
        displayName: platform.localizedLabel(l10n),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('connectPlatform error: $error');
      }
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.cloudConnectFailed)));
      return;
    }
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.connectedMessage(platform.localizedLabel(l10n))),
      ),
    );
  }

  Future<void> _showManualTrackDialog(
    BuildContext context,
    AppState state,
    String connectionId,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final TextEditingController titleController = TextEditingController();
    final TextEditingController urlController = TextEditingController();

    final bool? submit = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.addFileUrl),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: l10n.trackTitleLabel),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: InputDecoration(labelText: l10n.audioUrlLabel),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.add),
            ),
          ],
        );
      },
    );

    if (submit != true) {
      return;
    }

    final String title = titleController.text.trim();
    final String url = urlController.text.trim();

    if (title.isEmpty || Uri.tryParse(url) == null) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.invalidTitleOrUrl)));
      return;
    }

    await state.addManualTrack(
      connectionId: connectionId,
      title: title,
      url: url,
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.trackAddedFromUrl)));
  }

  Future<void> _showCreatePlaylistDialog(
    BuildContext context,
    AppState state,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final TextEditingController controller = TextEditingController();

    final bool? submit = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.createPlaylistTitle),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: l10n.playlistNameLabel),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.create),
            ),
          ],
        );
      },
    );

    if (submit != true) {
      return;
    }

    await state.createPlaylist(controller.text);
  }

  Future<void> _showPlaylistPicker(
    BuildContext context,
    AppState state,
    AudioTrack track,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    if (state.playlists.isEmpty) {
      await state.createPlaylist(l10n.defaultPlaylistName);
      if (!context.mounted) {
        return;
      }
    }

    final String? playlistId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.card,
      builder: (BuildContext context) {
        final AppLocalizations l10n = AppLocalizations.of(context)!;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                l10n.moveToPlaylist,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: state.playlists
                    .map(
                      (PlaylistModel playlist) => ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.queue_music_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(playlist.name),
                        subtitle: Text(l10n.tracksCount(playlist.trackIds.length)),
                        onTap: () => Navigator.of(context).pop(playlist.id),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        );
      },
    );

    if (playlistId == null) {
      return;
    }

    await state.addTrackToPlaylist(playlistId, track.id);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.trackMovedToPlaylist)));
  }

  Future<void> _openPlaylistDetails(
    BuildContext context,
    AppState state,
    PlaylistModel playlist,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.card,
      builder: (BuildContext context) {
        return Consumer<AppState>(
          builder: (BuildContext context, AppState value, _) {
            final AppLocalizations l10n = AppLocalizations.of(context)!;
            final List<AudioTrack> tracks = value.tracksForPlaylist(playlist.id);
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.cardBorder,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.queue_music_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                playlist.name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                l10n.tracksCount(tracks.length),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => value.playPlaylist(playlist.id),
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: Text(l10n.play),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: tracks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.music_off_rounded,
                                  size: 48,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  l10n.noTracksInPlaylist,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: tracks.length,
                            itemBuilder: (BuildContext context, int index) {
                              final AudioTrack track = tracks[index];
                              return ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: AppColors.primaryLight,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  track.title,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(track.artist),
                                onTap: () => value.playTrack(
                                  track,
                                  playlistId: playlist.id,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline_rounded,
                                    color: AppColors.textMuted,
                                  ),
                                  onPressed: () =>
                                      value.removeTrackFromPlaylist(
                                        playlist.id,
                                        track.id,
                                      ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPlayerSheet(BuildContext context, AppState state) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      builder: (BuildContext context) => PlayerSheet(state: state),
    );
  }
}

class _CloudPlatformTile extends StatelessWidget {
  const _CloudPlatformTile({
    required this.item,
    required this.l10n,
    required this.onTap,
  });

  final CloudPlatform item;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.cloud_rounded, color: AppColors.primaryLight),
      ),
      title: Text(
        item.localizedLabel(l10n),
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(item.localizedHint(l10n)),
      trailing: item.isIosOnly
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                l10n.iosShort,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textMuted,
            ),
      onTap: onTap,
    );
  }
}

class _CloudsTab extends StatelessWidget {
  const _CloudsTab({
    required this.onConnectPressed,
    required this.onSyncPressed,
    required this.onManualTrackPressed,
  });

  final VoidCallback onConnectPressed;
  final ValueChanged<String> onSyncPressed;
  final ValueChanged<String> onManualTrackPressed;

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final top = MediaQuery.of(context).padding.top + kToolbarHeight;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, top + 8, 16, 24),
      children: <Widget>[
        // Connect button
        Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onConnectPressed,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_link_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      l10n.connectAnotherCloud,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (state.connections.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 56,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.noCloudConnected,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...state.connections.map(
            (CloudConnection connection) => _CloudConnectionCard(
              connection: connection,
              trackCount: state.trackCountForConnection(connection.id),
              l10n: l10n,
              onManualTrack: () => onManualTrackPressed(connection.id),
              onSync: () => onSyncPressed(connection.id),
            ),
          ),
      ],
    );
  }
}

class _CloudConnectionCard extends StatelessWidget {
  const _CloudConnectionCard({
    required this.connection,
    required this.trackCount,
    required this.l10n,
    required this.onManualTrack,
    required this.onSync,
  });

  final CloudConnection connection;
  final int trackCount;
  final AppLocalizations l10n;
  final VoidCallback onManualTrack;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.cloud_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    connection.displayName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        connection.platform.localizedLabel(l10n),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l10n.filesCount(trackCount),
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              children: [
                _IconBtn(
                  icon: Icons.add_circle_outline_rounded,
                  tooltip: l10n.addUrlTrackTooltip,
                  onTap: onManualTrack,
                ),
                const SizedBox(width: 4),
                _IconBtn(
                  icon: Icons.sync_rounded,
                  tooltip: l10n.syncNowTooltip,
                  onTap: onSync,
                  isPrimary: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isPrimary
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.cardBorder.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isPrimary ? AppColors.primaryLight : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _LibraryTab extends StatelessWidget {
  const _LibraryTab({required this.onPlayTrack, required this.onAction});

  final ValueChanged<AudioTrack> onPlayTrack;
  final Future<void> Function(AudioTrack, TrackAction) onAction;

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final top = MediaQuery.of(context).padding.top + kToolbarHeight;

    if (state.tracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.music_note_rounded,
              size: 72,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.libraryEmpty,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(0, top + 8, 0, 24),
      itemCount: state.tracks.length,
      itemBuilder: (BuildContext context, int index) {
        final AudioTrack track = state.tracks[index];
        return TrackTile(
          track: track,
          index: index,
          onTap: () => onPlayTrack(track),
          onAction: (TrackAction action) => onAction(track, action),
        );
      },
    );
  }
}

class _PlaylistsTab extends StatelessWidget {
  const _PlaylistsTab({
    required this.onCreatePressed,
    required this.onToggleAutoplay,
    required this.onPlayPlaylist,
    required this.onOpenPlaylist,
  });

  final VoidCallback onCreatePressed;
  final Future<void> Function(String, bool) onToggleAutoplay;
  final ValueChanged<String> onPlayPlaylist;
  final ValueChanged<PlaylistModel> onOpenPlaylist;

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final top = MediaQuery.of(context).padding.top + kToolbarHeight;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, top + 8, 16, 24),
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onCreatePressed,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.playlist_add_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      l10n.createPlaylistTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (state.playlists.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.queue_music_rounded,
                  size: 56,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.noPlaylistYet,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          ...state.playlists.map((PlaylistModel playlist) {
            final int count = state.tracksForPlaylist(playlist.id).length;
            return _PlaylistCard(
              playlist: playlist,
              count: count,
              l10n: l10n,
              onTap: () => onOpenPlaylist(playlist),
              onToggleAutoplay: (bool value) =>
                  onToggleAutoplay(playlist.id, value),
              onPlay: () => onPlayPlaylist(playlist.id),
            );
          }),
      ],
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({
    required this.playlist,
    required this.count,
    required this.l10n,
    required this.onTap,
    required this.onToggleAutoplay,
    required this.onPlay,
  });

  final PlaylistModel playlist;
  final int count;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleAutoplay;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondary.withValues(alpha: 0.8),
                        AppColors.primary.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.queue_music_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.tracksCount(count),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          l10n.autoplay,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: playlist.autoPlay,
                            onChanged: onToggleAutoplay,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: onPlay,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniPlayerBar extends StatelessWidget {
  const _MiniPlayerBar({required this.state, required this.onOpen});

  final AppState state;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final AudioTrack? track = state.currentTrack;
    if (track == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onOpen,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E0A3C), Color(0xFF2D0A3C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: state.togglePlayback,
                icon: Icon(
                  state.isPlaying
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_fill_rounded,
                  color: AppColors.primaryLight,
                  size: 34,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
