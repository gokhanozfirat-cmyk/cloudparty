import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/cloud_folder_item.dart';
import '../models/cloud_models.dart';
import '../models/playlist_model.dart';
import '../state/app_state.dart';

class _StackEntry {
  const _StackEntry({required this.id, required this.name});
  final String? id;
  final String name;
}

class FolderBrowserSheet extends StatefulWidget {
  const FolderBrowserSheet({
    super.key,
    required this.connection,
    required this.state,
  });

  final CloudConnection connection;
  final AppState state;

  @override
  State<FolderBrowserSheet> createState() => _FolderBrowserSheetState();
}

class _FolderBrowserSheetState extends State<FolderBrowserSheet> {
  late final List<_StackEntry> _stack;
  List<CloudFolderItem>? _items;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _stack = <_StackEntry>[
      _StackEntry(id: null, name: widget.connection.displayName),
    ];
    _loadFolder(null);
  }

  Future<void> _loadFolder(String? folderId) async {
    setState(() {
      _loading = true;
      _error = null;
      _items = null;
    });
    try {
      final List<CloudFolderItem> items = await widget.state.listFolder(
        widget.connection.id,
        folderId,
      );
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _enter(CloudFolderItem folder) {
    _stack.add(_StackEntry(id: folder.id, name: folder.name));
    _loadFolder(folder.id);
  }

  void _goBack() {
    if (_stack.length > 1) {
      _stack.removeLast();
      _loadFolder(_stack.last.id);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _playItem(CloudFolderItem item) {
    final List<CloudFolderItem> siblings = _items ?? <CloudFolderItem>[];
    widget.state.playCloudItem(widget.connection.id, item, siblings);
  }

  Future<void> _addFolderToPlaylist(CloudFolderItem folder) async {
    final BuildContext ctx = context;
    final AppLocalizations l10n = AppLocalizations.of(ctx)!;

    if (widget.state.playlists.isEmpty) {
      await widget.state.createPlaylist(l10n.defaultPlaylistName);
    }

    if (!ctx.mounted) return;

    // ignore: use_build_context_synchronously
    final String? playlistId = await showModalBottomSheet<String>(
      context: ctx,
      showDragHandle: true,
      backgroundColor: AppColors.card,
      builder: (BuildContext context) {
        final AppLocalizations l = AppLocalizations.of(context)!;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                l.moveToPlaylist,
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
                children: widget.state.playlists
                    .map(
                      (PlaylistModel p) => ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.queue_music_rounded,
                              color: Colors.white, size: 20),
                        ),
                        title: Text(p.name),
                        subtitle:
                            Text(l.tracksCount(p.trackIds.length)),
                        onTap: () => Navigator.of(context).pop(p.id),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        );
      },
    );

    if (playlistId == null || !ctx.mounted) return;

    // Load folder contents and add all audio files already in library
    final List<CloudFolderItem> folderItems = await widget.state.listFolder(
      widget.connection.id,
      folder.id,
    );

    if (!ctx.mounted) return;

    for (final CloudFolderItem item in folderItems) {
      if (!item.isFolder && item.remoteUrl != null) {
        final existingTrack = widget.state.tracks.cast<dynamic>().firstWhere(
          (t) => t.remoteUrl == item.remoteUrl,
          orElse: () => null,
        );
        if (existingTrack != null) {
          await widget.state.addTrackToPlaylist(
              playlistId, existingTrack.id as String);
        }
      }
    }

    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(ctx)!.folderAddedToPlaylist),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _stack.length <= 1,
      onPopInvokedWithResult: (bool didPop, _) {
        if (!didPop && _stack.length > 1) {
          _goBack();
        }
      },
      child: Column(
        children: <Widget>[
          _buildHeader(),
          const Divider(height: 1, color: AppColors.cardBorder),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final bool atRoot = _stack.length <= 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: _goBack,
            icon: Icon(
              atRoot ? Icons.close_rounded : Icons.arrow_back_ios_new_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (_stack.length > 1)
                  Text(
                    _stack[_stack.length - 2].name,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                Text(
                  _stack.last.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.textMuted, size: 48),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _loadFolder(_stack.last.id),
                child: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      );
    }

    final List<CloudFolderItem> items = _items ?? <CloudFolderItem>[];
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Bu klasör boş.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        final CloudFolderItem item = items[index];
        return _FolderItemTile(
          item: item,
          onTap: () {
            if (item.isFolder) {
              _enter(item);
            } else {
              _playItem(item);
            }
          },
          onAddFolderToPlaylist:
              item.isFolder ? () => _addFolderToPlaylist(item) : null,
        );
      },
    );
  }
}

class _FolderItemTile extends StatelessWidget {
  const _FolderItemTile({
    required this.item,
    required this.onTap,
    this.onAddFolderToPlaylist,
  });

  final CloudFolderItem item;
  final VoidCallback onTap;
  final VoidCallback? onAddFolderToPlaylist;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.isFolder
                      ? AppColors.accent.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.isFolder
                      ? Icons.folder_rounded
                      : Icons.music_note_rounded,
                  color: item.isFolder
                      ? AppColors.accent
                      : AppColors.primaryLight,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.isFolder
                          ? item.name
                          : _stripExt(item.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    if (!item.isFolder && item.artist != null)
                      Text(
                        item.artist!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (!item.isFolder && item.format != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.format!.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else if (item.isFolder)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (onAddFolderToPlaylist != null)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded,
                            color: AppColors.textMuted, size: 18),
                        color: AppColors.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.cardBorder),
                        ),
                        onSelected: (String v) {
                          if (v == 'playlist') onAddFolderToPlaylist!();
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'playlist',
                            child: Row(
                              children: <Widget>[
                                const Icon(Icons.playlist_add_rounded,
                                    color: AppColors.primaryLight, size: 18),
                                const SizedBox(width: 10),
                                Text(
                                  AppLocalizations.of(context)!
                                      .addFolderToPlaylist,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textMuted, size: 20),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _stripExt(String name) {
    final int dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }
}
