import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/audio_track.dart';
import '../models/cloud_models.dart';
import '../models/playlist_model.dart';
import '../services/cloud_sync_service.dart';
import '../services/offline_download_service.dart';

class AppState extends ChangeNotifier {
  AppState({
    CloudSyncService? syncService,
    OfflineDownloadService? downloadService,
  }) : _syncService = syncService ?? CloudSyncService(),
       _downloadService = downloadService ?? OfflineDownloadService(),
       _uuid = const Uuid() {
    _player.playerStateStream.listen((_) => notifyListeners());
    _player.currentIndexStream.listen((_) => notifyListeners());
    _player.shuffleModeEnabledStream.listen((_) => notifyListeners());
    _player.loopModeStream.listen((_) => notifyListeners());
    _player.speedStream.listen((_) => notifyListeners());
  }

  static const String _connectionsKey = 'cloudparty.connections';
  static const String _tracksKey = 'cloudparty.tracks';
  static const String _playlistsKey = 'cloudparty.playlists';
  static const String _localeCodeKey = 'cloudparty.localeCode';

  final CloudSyncService _syncService;
  final OfflineDownloadService _downloadService;
  final Uuid _uuid;
  final AudioPlayer _player = AudioPlayer();

  SharedPreferences? _prefs;

  bool _isInitialized = false;
  Locale _locale = const Locale('en');
  final List<CloudConnection> _connections = <CloudConnection>[];
  final List<AudioTrack> _tracks = <AudioTrack>[];
  final List<PlaylistModel> _playlists = <PlaylistModel>[];

  List<AudioTrack> _activeQueue = <AudioTrack>[];

  Timer? _autoSyncTimer;
  Timer? _sleepTimer;
  DateTime? _sleepEndsAt;
  bool _syncAllInProgress = false;

  bool get isInitialized => _isInitialized;
  Locale get locale => _locale;
  String get localeCode => _locale.languageCode;
  List<CloudConnection> get connections =>
      List<CloudConnection>.unmodifiable(_connections);
  List<AudioTrack> get tracks => List<AudioTrack>.unmodifiable(_tracks);
  List<PlaylistModel> get playlists =>
      List<PlaylistModel>.unmodifiable(_playlists);

  AudioPlayer get player => _player;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  AudioTrack? get currentTrack {
    if (_activeQueue.isEmpty) {
      return null;
    }
    final int index = _player.currentIndex ?? 0;
    if (index < 0 || index >= _activeQueue.length) {
      return null;
    }
    return _activeQueue[index];
  }

  bool get isPlaying => _player.playing;
  double get speed => _player.speed;
  bool get shuffleEnabled => _player.shuffleModeEnabled;
  LoopMode get loopMode => _player.loopMode;
  DateTime? get sleepEndsAt => _sleepEndsAt;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadPersistedState();

    final String? persistedLocale = _prefs?.getString(_localeCodeKey);
    if (persistedLocale == 'tr' || persistedLocale == 'en') {
      _locale = Locale(persistedLocale!);
    } else {
      final String systemCode = PlatformDispatcher.instance.locale.languageCode
          .toLowerCase();
      _locale = systemCode == 'tr' ? const Locale('tr') : const Locale('en');
    }

    _isInitialized = true;
    notifyListeners();
    await _persist();

    _startAutoSync();
    if (_connections.isNotEmpty) {
      unawaited(refreshAllConnections(silent: true));
    }
  }

  Future<void> setLocaleCode(String code) async {
    if (code != 'tr' && code != 'en') {
      return;
    }
    if (_locale.languageCode == code) {
      return;
    }
    _locale = Locale(code);
    notifyListeners();
    await _persist();
  }

  Future<void> connectPlatform(
    CloudPlatform platform, {
    String? displayName,
  }) async {
    final String fallbackName = displayName?.trim().isNotEmpty == true
        ? displayName!.trim()
        : '${platform.label} ${_connections.length + 1}';

    final CloudConnection connection = await _syncService.connectPlatform(
      platform,
      fallbackDisplayName: fallbackName,
    );

    _connections.add(connection);
    notifyListeners();

    try {
      await syncConnection(connection.id, persistAfter: false);
    } finally {
      await _persist();
    }
  }

  Future<void> syncConnection(
    String connectionId, {
    bool persistAfter = true,
  }) async {
    final CloudConnection connection = _connections.firstWhere(
      (CloudConnection item) => item.id == connectionId,
    );

    final List<AudioTrack> fetched = await _syncService
        .fetchTracksForConnection(connection);

    _tracks.removeWhere((AudioTrack track) {
      return track.connectionId == connectionId && !track.isManual;
    });
    _tracks.addAll(fetched);
    _sortTracks();

    notifyListeners();
    if (persistAfter) {
      await _persist();
    }
  }

  Future<void> refreshAllConnections({bool silent = false}) async {
    if (_syncAllInProgress) {
      return;
    }

    _syncAllInProgress = true;
    try {
      for (final CloudConnection connection in _connections) {
        try {
          await syncConnection(connection.id, persistAfter: false);
        } catch (_) {
          if (!silent) {
            rethrow;
          }
        }
      }
      await _persist();
    } finally {
      _syncAllInProgress = false;
    }
  }

  Future<void> addManualTrack({
    required String connectionId,
    required String title,
    required String url,
  }) async {
    final CloudConnection connection = _connections.firstWhere(
      (CloudConnection item) => item.id == connectionId,
    );

    final AudioTrack track = _syncService.createManualTrack(
      connection: connection,
      title: title,
      url: url,
    );

    _tracks.insert(0, track);
    notifyListeners();
    await _persist();
  }

  Future<void> createPlaylist(String name) async {
    final String normalized = name.trim();
    if (normalized.isEmpty) {
      return;
    }

    _playlists.add(PlaylistModel(id: _uuid.v4(), name: normalized));
    notifyListeners();
    await _persist();
  }

  Future<void> setPlaylistAutoplay(String playlistId, bool value) async {
    final int index = _playlists.indexWhere(
      (PlaylistModel item) => item.id == playlistId,
    );
    if (index == -1) {
      return;
    }

    _playlists[index] = _playlists[index].copyWith(autoPlay: value);
    notifyListeners();
    await _persist();
  }

  Future<void> addTrackToPlaylist(String playlistId, String trackId) async {
    final int index = _playlists.indexWhere(
      (PlaylistModel item) => item.id == playlistId,
    );
    if (index == -1) {
      return;
    }

    final PlaylistModel playlist = _playlists[index];
    if (playlist.trackIds.contains(trackId)) {
      return;
    }

    _playlists[index] = playlist.copyWith(
      trackIds: <String>[...playlist.trackIds, trackId],
    );
    notifyListeners();
    await _persist();
  }

  Future<void> removeTrackFromPlaylist(
    String playlistId,
    String trackId,
  ) async {
    final int index = _playlists.indexWhere(
      (PlaylistModel item) => item.id == playlistId,
    );
    if (index == -1) {
      return;
    }

    final PlaylistModel playlist = _playlists[index];
    _playlists[index] = playlist.copyWith(
      trackIds: playlist.trackIds.where((String id) => id != trackId).toList(),
    );
    notifyListeners();
    await _persist();
  }

  List<AudioTrack> tracksForPlaylist(String playlistId) {
    final PlaylistModel? playlist = _playlistById(playlistId);
    if (playlist == null) {
      return <AudioTrack>[];
    }

    return playlist.trackIds
        .map(
          (String id) =>
              _tracks.where((AudioTrack item) => item.id == id).firstOrNull,
        )
        .whereType<AudioTrack>()
        .toList(growable: false);
  }

  int trackCountForConnection(String connectionId) {
    return _tracks
        .where((AudioTrack track) => track.connectionId == connectionId)
        .length;
  }

  Future<void> playTrack(AudioTrack track, {String? playlistId}) async {
    List<AudioTrack> queue;

    if (playlistId != null) {
      final PlaylistModel? playlist = _playlistById(playlistId);
      final List<AudioTrack> playlistTracks = tracksForPlaylist(playlistId);
      if (playlist != null && playlist.autoPlay) {
        queue = playlistTracks;
      } else {
        queue = <AudioTrack>[track];
      }
    } else {
      queue = List<AudioTrack>.from(_tracks);
      _sortTracks(list: queue);
    }

    if (queue.isEmpty) {
      return;
    }

    final int startIndex = queue.indexWhere(
      (AudioTrack item) => item.id == track.id,
    );
    await _setQueueAndPlay(queue, startIndex == -1 ? 0 : startIndex);
  }

  Future<void> playPlaylist(String playlistId) async {
    final PlaylistModel? playlist = _playlistById(playlistId);
    if (playlist == null) {
      return;
    }

    final List<AudioTrack> playlistTracks = tracksForPlaylist(playlistId);
    if (playlistTracks.isEmpty) {
      return;
    }

    final List<AudioTrack> queue = playlist.autoPlay
        ? playlistTracks
        : <AudioTrack>[playlistTracks.first];
    await _setQueueAndPlay(queue, 0);
  }

  Future<void> togglePlayback() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
    notifyListeners();
  }

  Future<void> playNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
      await _player.play();
    }
  }

  Future<void> playPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
      await _player.play();
    }
  }

  Future<void> setSpeed(double value) async {
    await _player.setSpeed(value);
    notifyListeners();
  }

  Future<void> toggleShuffle() async {
    final bool next = !_player.shuffleModeEnabled;
    await _player.setShuffleModeEnabled(next);
    if (next) {
      await _player.shuffle();
    }
    notifyListeners();
  }

  Future<void> cycleRepeatMode() async {
    final LoopMode current = _player.loopMode;
    switch (current) {
      case LoopMode.off:
        await _player.setLoopMode(LoopMode.all);
        break;
      case LoopMode.all:
        await _player.setLoopMode(LoopMode.one);
        break;
      case LoopMode.one:
        await _player.setLoopMode(LoopMode.off);
        break;
    }
    notifyListeners();
  }

  void setSleepTimer(Duration? duration) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepEndsAt = null;

    if (duration != null) {
      _sleepEndsAt = DateTime.now().add(duration);
      _sleepTimer = Timer(duration, () async {
        await _player.pause();
        _sleepEndsAt = null;
        notifyListeners();
      });
    }

    notifyListeners();
  }

  Future<void> downloadTrack(String trackId) async {
    final int index = _tracks.indexWhere(
      (AudioTrack item) => item.id == trackId,
    );
    if (index == -1) {
      return;
    }

    final AudioTrack updated = await _downloadService.downloadTrack(
      _tracks[index],
    );
    _tracks[index] = updated;
    _activeQueue = _activeQueue
        .map((AudioTrack item) => item.id == updated.id ? updated : item)
        .toList(growable: false);

    notifyListeners();
    await _persist();
  }

  Future<void> _setQueueAndPlay(List<AudioTrack> queue, int index) async {
    _activeQueue = queue;

    await _player.setAudioSources(
      queue
          .map(
            (AudioTrack track) => AudioSource.uri(
              track.playUri,
              headers: track.requestHeaders,
              tag: track.id,
            ),
          )
          .toList(growable: false),
      initialIndex: index,
      initialPosition: Duration.zero,
    );
    await _player.play();
    notifyListeners();
  }

  void _loadPersistedState() {
    final SharedPreferences? prefs = _prefs;
    if (prefs == null) {
      return;
    }

    final String? rawConnections = prefs.getString(_connectionsKey);
    final String? rawTracks = prefs.getString(_tracksKey);
    final String? rawPlaylists = prefs.getString(_playlistsKey);

    if (rawConnections != null && rawConnections.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(rawConnections) as List<dynamic>;
      _connections
        ..clear()
        ..addAll(
          decoded
              .map(
                (dynamic item) =>
                    CloudConnection.fromJson(item as Map<String, dynamic>),
              )
              .toList(growable: false),
        );
    }

    if (rawTracks != null && rawTracks.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(rawTracks) as List<dynamic>;
      _tracks
        ..clear()
        ..addAll(
          decoded
              .map(
                (dynamic item) =>
                    AudioTrack.fromJson(item as Map<String, dynamic>),
              )
              .toList(growable: false),
        );
      _sortTracks();
    }

    if (rawPlaylists != null && rawPlaylists.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(rawPlaylists) as List<dynamic>;
      _playlists
        ..clear()
        ..addAll(
          decoded
              .map(
                (dynamic item) =>
                    PlaylistModel.fromJson(item as Map<String, dynamic>),
              )
              .toList(growable: false),
        );
    }
  }

  Future<void> _persist() async {
    final SharedPreferences? prefs = _prefs;
    if (prefs == null) {
      return;
    }

    await prefs.setString(
      _connectionsKey,
      jsonEncode(
        _connections
            .map((CloudConnection item) => item.toJson())
            .toList(growable: false),
      ),
    );
    await prefs.setString(
      _tracksKey,
      jsonEncode(
        _tracks.map((AudioTrack item) => item.toJson()).toList(growable: false),
      ),
    );
    await prefs.setString(
      _playlistsKey,
      jsonEncode(
        _playlists
            .map((PlaylistModel item) => item.toJson())
            .toList(growable: false),
      ),
    );
    await prefs.setString(_localeCodeKey, _locale.languageCode);
  }

  PlaylistModel? _playlistById(String id) {
    for (final PlaylistModel playlist in _playlists) {
      if (playlist.id == id) {
        return playlist;
      }
    }
    return null;
  }

  void _sortTracks({List<AudioTrack>? list}) {
    final List<AudioTrack> target = list ?? _tracks;
    target.sort(
      (AudioTrack a, AudioTrack b) => b.createdAt.compareTo(a.createdAt),
    );
  }

  void _startAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      unawaited(refreshAllConnections(silent: true));
    });
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    _sleepTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final Iterator<T> iterator = this.iterator;
    if (!iterator.moveNext()) {
      return null;
    }
    return iterator.current;
  }
}
