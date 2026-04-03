import 'package:flutter/material.dart';
import 'package:cloudparty/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../l10n/cloud_platform_texts.dart';
import '../main.dart';
import '../models/audio_track.dart';
import '../models/cloud_models.dart';
import '../services/cloud_sync_exception.dart';
import '../models/playlist_model.dart';
import '../state/app_state.dart';
import '../widgets/folder_browser_sheet.dart';
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
                    onDisconnectPressed: (String id) =>
                        _disconnectConnection(context, state, id),
                    onBrowsePressed: (String id) =>
                        _showFolderBrowser(context, state, id),
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
                    onDeletePlaylist: (String id) =>
                        _deletePlaylist(context, state, id),
                    onOpenFavorites: () => _showBuiltInPlaylist(
                      context,
                      title: AppLocalizations.of(context)!.favorites,
                      tracks: state.favoriteTracks,
                      emptyMessage: AppLocalizations.of(context)!.noFavorites,
                      state: state,
                      icon: Icons.favorite_rounded,
                      iconColor: Colors.pinkAccent,
                    ),
                    onOpenLastPlayed: () => _showBuiltInPlaylist(
                      context,
                      title: AppLocalizations.of(context)!.lastPlayed,
                      tracks: state.lastPlayedTracks,
                      emptyMessage: AppLocalizations.of(context)!.noLastPlayed,
                      state: state,
                      icon: Icons.history_rounded,
                      iconColor: AppColors.accent,
                    ),
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
        IconButton(
          onPressed: () => state.setOfflineOnly(!state.isOfflineOnly),
          tooltip: l10n.offline,
          icon: Icon(
            state.isOfflineOnly
                ? Icons.wifi_off_rounded
                : Icons.wifi_rounded,
            color: state.isOfflineOnly
                ? AppColors.accent
                : AppColors.textSecondary,
          ),
        ),
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

  Future<void> _disconnectConnection(
    BuildContext context,
    AppState state,
    String id,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final AppLocalizations l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.disconnectConfirmTitle),
          content: Text(l10n.disconnectConfirmBody),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: Text(l10n.disconnect),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;
    await state.disconnectConnection(id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.disconnected)),
    );
  }

  Future<void> _deletePlaylist(
    BuildContext context,
    AppState state,
    String id,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final AppLocalizations l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          content: Text(l10n.deletePlaylistConfirmBody),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: Text(l10n.deletePlaylistLabel),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;
    await state.deletePlaylist(id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.playlistDeleted)),
    );
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
      case TrackAction.toggleFavorite:
        await state.toggleFavorite(track.id);
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

    Map<String, String> extraData = const <String, String>{};
    if (platform == CloudPlatform.webDav) {
      if (!context.mounted) return;
      final Map<String, String>? webDavData = await _showWebDavDialog(context);
      if (webDavData == null) return;
      extraData = webDavData;
    }

    try {
      await state.connectPlatform(
        platform,
        displayName: platform.localizedLabel(l10n),
        extraData: extraData,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('connectPlatform error: $error');
      }
      if (!context.mounted) {
        return;
      }
      final String message = error is CloudSyncException
          ? error.message
          : l10n.cloudConnectFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
    // Bağlantı sonrası Library tab'ına geç
    setState(() => _tabIndex = 1);
  }

  Future<Map<String, String>?> _showWebDavDialog(BuildContext context) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final TextEditingController urlCtrl = TextEditingController();
    final TextEditingController userCtrl = TextEditingController();
    final TextEditingController passCtrl = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext ctx) {
        bool obscure = true;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setS) {
            return AlertDialog(
              backgroundColor: AppColors.card,
              title: Text(
                l10n.cloudWebDav,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: urlCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: l10n.webDavUrlLabel,
                      hintText: l10n.webDavUrlHint,
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                    ),
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: userCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: l10n.webDavUsernameLabel,
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                    ),
                    autocorrect: false,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: l10n.webDavPasswordLabel,
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () => setS(() => obscure = !obscure),
                      ),
                    ),
                    autocorrect: false,
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    final String url = urlCtrl.text.trim();
                    if (url.isEmpty) return;
                    Navigator.of(context).pop(<String, String>{
                      'url': url,
                      'username': userCtrl.text.trim(),
                      'password': passCtrl.text,
                    });
                  },
                  child: Text(l10n.webDavConnectButton),
                ),
              ],
            );
          },
        );
      },
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

  void _showBuiltInPlaylist(
    BuildContext context, {
    required String title,
    required List<AudioTrack> tracks,
    required String emptyMessage,
    required AppState state,
    required IconData icon,
    required Color iconColor,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.card,
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.cardBorder, width: 0.5),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: iconColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context)!.tracksCount(tracks.length),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (tracks.isNotEmpty)
                      FilledButton.icon(
                        onPressed: () => state.playTrack(tracks.first),
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: Text(AppLocalizations.of(context)!.play),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: tracks.isEmpty
                    ? Center(
                        child: Text(
                          emptyMessage,
                          style: const TextStyle(color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: tracks.length,
                        itemBuilder: (BuildContext context, int index) {
                          final AudioTrack track = tracks[index];
                          return TrackTile(
                            track: track,
                            index: index,
                            isFavorite: state.isFavorite(track.id),
                            onTap: () => state.playTrack(track),
                            onAction: (TrackAction action) async {
                              switch (action) {
                                case TrackAction.addToPlaylist:
                                  await _showPlaylistPicker(context, state, track);
                                  break;
                                case TrackAction.download:
                                  await _downloadTrack(context, state, track.id);
                                  break;
                                case TrackAction.toggleFavorite:
                                  await state.toggleFavorite(track.id);
                                  break;
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFolderBrowser(
    BuildContext context,
    AppState state,
    String connectionId,
  ) {
    final connection = state.connections.firstWhere((c) => c.id == connectionId);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.card,
      builder: (BuildContext context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: FolderBrowserSheet(connection: connection, state: state),
      ),
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
    required this.onDisconnectPressed,
    required this.onBrowsePressed,
  });

  final VoidCallback onConnectPressed;
  final ValueChanged<String> onSyncPressed;
  final ValueChanged<String> onManualTrackPressed;
  final ValueChanged<String> onDisconnectPressed;
  final ValueChanged<String> onBrowsePressed;

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
              onBrowse: () => onBrowsePressed(connection.id),
              onManualTrack: () => onManualTrackPressed(connection.id),
              onSync: () => onSyncPressed(connection.id),
              onDisconnect: () => onDisconnectPressed(connection.id),
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
    required this.onBrowse,
    required this.onManualTrack,
    required this.onSync,
    required this.onDisconnect,
  });

  final CloudConnection connection;
  final int trackCount;
  final AppLocalizations l10n;
  final VoidCallback onBrowse;
  final VoidCallback onManualTrack;
  final VoidCallback onSync;
  final VoidCallback onDisconnect;

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
          onTap: onBrowse,
          borderRadius: BorderRadius.circular(16),
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
                  icon: Icons.sync_rounded,
                  tooltip: l10n.syncNowTooltip,
                  onTap: onSync,
                  isPrimary: true,
                ),
                const SizedBox(width: 4),
                PopupMenuButton<_CloudCardAction>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  color: AppColors.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                  onSelected: (_CloudCardAction action) {
                    switch (action) {
                      case _CloudCardAction.addUrl:
                        onManualTrack();
                        break;
                      case _CloudCardAction.disconnect:
                        onDisconnect();
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<_CloudCardAction>>[
                    PopupMenuItem<_CloudCardAction>(
                      value: _CloudCardAction.addUrl,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.add_link_rounded,
                            color: AppColors.primaryLight,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l10n.addUrlTrackTooltip,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<_CloudCardAction>(
                      value: _CloudCardAction.disconnect,
                      child: Row(
                        children: [
                          Icon(
                            Icons.link_off_rounded,
                            color: Colors.red.shade400,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l10n.disconnect,
                            style: TextStyle(color: Colors.red.shade400),
                          ),
                        ],
                      ),
                    ),
                  ],
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

enum _CloudCardAction { addUrl, disconnect }

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

class _LibraryTab extends StatefulWidget {
  const _LibraryTab({required this.onPlayTrack, required this.onAction});

  final ValueChanged<AudioTrack> onPlayTrack;
  final Future<void> Function(AudioTrack, TrackAction) onAction;

  @override
  State<_LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<_LibraryTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final double top = MediaQuery.of(context).padding.top + kToolbarHeight;

    if (state.tracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.music_note_rounded, size: 72, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              l10n.libraryEmpty,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: <Widget>[
        SizedBox(height: top),
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: AppColors.cardBorder,
          tabs: <Tab>[
            Tab(text: l10n.allTracks),
            Tab(text: l10n.artists),
            Tab(text: l10n.offline),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: <Widget>[
              _AllTracksView(
                state: state,
                l10n: l10n,
                query: _query,
                onQueryChanged: (String v) => setState(() => _query = v),
                onPlayTrack: widget.onPlayTrack,
                onAction: widget.onAction,
              ),
              _ArtistsView(
                state: state,
                l10n: l10n,
                onPlayTrack: widget.onPlayTrack,
                onAction: widget.onAction,
              ),
              _OfflineView(
                state: state,
                l10n: l10n,
                onPlayTrack: widget.onPlayTrack,
                onAction: widget.onAction,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AllTracksView extends StatelessWidget {
  const _AllTracksView({
    required this.state,
    required this.l10n,
    required this.query,
    required this.onQueryChanged,
    required this.onPlayTrack,
    required this.onAction,
  });

  final AppState state;
  final AppLocalizations l10n;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<AudioTrack> onPlayTrack;
  final Future<void> Function(AudioTrack, TrackAction) onAction;

  @override
  Widget build(BuildContext context) {
    final List<AudioTrack> source = state.displayTracks;
    final List<AudioTrack> filtered = query.isEmpty
        ? source
        : source.where((AudioTrack t) {
            final String q = query.toLowerCase();
            return t.title.toLowerCase().contains(q) ||
                t.artist.toLowerCase().contains(q);
          }).toList();

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: l10n.searchTracksHint,
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: onQueryChanged,
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    l10n.noSearchResults,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: filtered.length,
                  itemBuilder: (BuildContext context, int index) {
                    final AudioTrack track = filtered[index];
                    return TrackTile(
                      track: track,
                      index: index,
                      isFavorite: state.isFavorite(track.id),
                      onTap: () => onPlayTrack(track),
                      onAction: (TrackAction action) => onAction(track, action),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ArtistsView extends StatefulWidget {
  const _ArtistsView({
    required this.state,
    required this.l10n,
    required this.onPlayTrack,
    required this.onAction,
  });

  final AppState state;
  final AppLocalizations l10n;
  final ValueChanged<AudioTrack> onPlayTrack;
  final Future<void> Function(AudioTrack, TrackAction) onAction;

  @override
  State<_ArtistsView> createState() => _ArtistsViewState();
}

class _ArtistsViewState extends State<_ArtistsView> {
  String? _selectedArtist;

  @override
  Widget build(BuildContext context) {
    final Map<String, List<AudioTrack>> byArtist = widget.state.tracksByArtist;
    final List<String> artistNames = byArtist.keys.toList()..sort();

    if (_selectedArtist != null) {
      final List<AudioTrack> artistTracks =
          byArtist[_selectedArtist] ?? <AudioTrack>[];
      return Column(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textSecondary, size: 18),
            title: Text(
              _selectedArtist!,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              widget.l10n.tracksCount(artistTracks.length),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            onTap: () => setState(() => _selectedArtist = null),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: artistTracks.length,
              itemBuilder: (BuildContext context, int index) {
                final AudioTrack track = artistTracks[index];
                return TrackTile(
                  track: track,
                  index: index,
                  isFavorite: widget.state.isFavorite(track.id),
                  onTap: () => widget.onPlayTrack(track),
                  onAction: (TrackAction action) =>
                      widget.onAction(track, action),
                );
              },
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: artistNames.length,
      itemBuilder: (BuildContext context, int index) {
        final String artist = artistNames[index];
        final int count = byArtist[artist]!.length;
        return ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.person_rounded,
                color: AppColors.primaryLight, size: 22),
          ),
          title: Text(
            artist,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            widget.l10n.tracksCount(count),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted),
          onTap: () => setState(() => _selectedArtist = artist),
        );
      },
    );
  }
}

class _OfflineView extends StatelessWidget {
  const _OfflineView({
    required this.state,
    required this.l10n,
    required this.onPlayTrack,
    required this.onAction,
  });

  final AppState state;
  final AppLocalizations l10n;
  final ValueChanged<AudioTrack> onPlayTrack;
  final Future<void> Function(AudioTrack, TrackAction) onAction;

  @override
  Widget build(BuildContext context) {
    final List<AudioTrack> offline =
        state.tracks.where((AudioTrack t) => t.isOffline).toList();

    if (offline.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.wifi_off_rounded,
                  size: 56, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                l10n.noOfflineTracks,
                style: const TextStyle(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: offline.length,
      itemBuilder: (BuildContext context, int index) {
        final AudioTrack track = offline[index];
        return TrackTile(
          track: track,
          index: index,
          isFavorite: state.isFavorite(track.id),
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
    required this.onDeletePlaylist,
    required this.onOpenFavorites,
    required this.onOpenLastPlayed,
  });

  final VoidCallback onCreatePressed;
  final Future<void> Function(String, bool) onToggleAutoplay;
  final ValueChanged<String> onPlayPlaylist;
  final ValueChanged<PlaylistModel> onOpenPlaylist;
  final ValueChanged<String> onDeletePlaylist;
  final VoidCallback onOpenFavorites;
  final VoidCallback onOpenLastPlayed;

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
        // Built-in: Favorites
        _BuiltInPlaylistCard(
          icon: Icons.favorite_rounded,
          iconColor: Colors.pinkAccent,
          title: l10n.favorites,
          count: state.favoriteTracks.length,
          onTap: onOpenFavorites,
        ),
        // Built-in: Last Played
        _BuiltInPlaylistCard(
          icon: Icons.history_rounded,
          iconColor: AppColors.accent,
          title: l10n.lastPlayed,
          count: state.lastPlayedTracks.length,
          onTap: onOpenLastPlayed,
        ),
        const SizedBox(height: 4),
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
              onDelete: () => onDeletePlaylist(playlist.id),
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
    required this.onDelete,
  });

  final PlaylistModel playlist;
  final int count;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleAutoplay;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

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
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: Colors.red.shade400,
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
              IconButton(
                onPressed: state.player.hasNext ? state.playNext : null,
                icon: Icon(
                  Icons.skip_next_rounded,
                  color: state.player.hasNext
                      ? AppColors.textSecondary
                      : AppColors.textMuted,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuiltInPlaylistCard extends StatelessWidget {
  const _BuiltInPlaylistCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
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
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
