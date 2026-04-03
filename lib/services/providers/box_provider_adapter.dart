import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../models/audio_track.dart';
import '../../models/cloud_folder_item.dart';
import '../../models/cloud_models.dart';
import '../cloud_sync_exception.dart';
import 'oauth_provider_adapter.dart';

class BoxProviderAdapter extends OAuthProviderAdapter {
  BoxProviderAdapter() : _uuid = const Uuid();

  final Uuid _uuid;

  static const Set<String> _audioExts = <String>{
    'mp3', 'm4a', 'mp4', 'wav', 'flac', 'alac', 'ogg', 'opus', 'aac',
  };

  @override
  CloudPlatform get platform => CloudPlatform.box;

  @override
  String get clientId => const String.fromEnvironment('BOX_CLIENT_ID');

  @override
  String? get clientSecret {
    const String s = String.fromEnvironment('BOX_CLIENT_SECRET');
    return s.isEmpty ? null : s;
  }

  @override
  String get authorizationEndpoint =>
      'https://account.box.com/api/oauth2/authorize';

  @override
  String get tokenEndpoint => 'https://api.box.com/oauth2/token';

  @override
  List<String> get scopes => <String>['root_readonly'];

  @override
  Future<String?> fetchDisplayName(String accessToken) async {
    try {
      final Response<dynamic> resp = await Dio().get<dynamic>(
        'https://api.box.com/2.0/users/me',
        options: Options(
          headers: <String, String>{'Authorization': 'Bearer $accessToken'},
        ),
      );
      return resp.data['name'] as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<AudioTrack>> fetchTracks(CloudConnection connection) async {
    final String? token = await getValidAccessToken(connection.id);
    if (token == null) {
      throw CloudSyncException('Box oturumu sona erdi. Yeniden bağlan.');
    }
    final List<AudioTrack> tracks = <AudioTrack>[];
    await _collectTracks('0', token, connection, tracks);
    return tracks;
  }

  Future<void> _collectTracks(
    String folderId,
    String token,
    CloudConnection connection,
    List<AudioTrack> tracks,
  ) async {
    final List<dynamic> items = await _listItems(folderId, token);
    for (final dynamic item in items) {
      final String type = item['type'] as String? ?? '';
      if (type == 'folder') {
        await _collectTracks(item['id'] as String, token, connection, tracks);
      } else if (type == 'file' && _isAudio(item['name'] as String? ?? '')) {
        tracks.add(_buildTrack(item, connection, token));
      }
    }
  }

  @override
  Future<List<CloudFolderItem>> listFolder(
    CloudConnection connection,
    String? folderId,
  ) async {
    final String? token = await getValidAccessToken(connection.id);
    if (token == null) {
      throw CloudSyncException('Box oturumu sona erdi. Yeniden bağlan.');
    }

    final String id = folderId ?? '0';
    final List<dynamic> items = await _listItems(id, token);
    final List<CloudFolderItem> result = <CloudFolderItem>[];

    for (final dynamic item in items) {
      final String type = item['type'] as String? ?? '';
      final String name = item['name'] as String? ?? '';
      final String itemId = item['id'] as String? ?? '';
      final bool isFolder = type == 'folder';
      if (!isFolder && !_isAudio(name)) continue;

      result.add(CloudFolderItem(
        id: itemId,
        name: name,
        isFolder: isFolder,
        remoteUrl: isFolder
            ? null
            : 'https://api.box.com/2.0/files/$itemId/content',
        requestHeaders: isFolder
            ? null
            : <String, String>{'Authorization': 'Bearer $token'},
        format: isFolder ? null : _ext(name).toUpperCase(),
      ));
    }
    return result;
  }

  Future<List<dynamic>> _listItems(String folderId, String token) async {
    final List<dynamic> all = <dynamic>[];
    int offset = 0;
    const int limit = 200;
    bool hasMore = true;

    final Dio dio = Dio(BaseOptions(
      headers: <String, String>{'Authorization': 'Bearer $token'},
    ));

    while (hasMore) {
      try {
        final Response<dynamic> resp = await dio.get<dynamic>(
          'https://api.box.com/2.0/folders/$folderId/items',
          queryParameters: <String, dynamic>{
            'fields': 'id,name,type',
            'limit': limit,
            'offset': offset,
          },
        );
        final List<dynamic> entries =
            resp.data['entries'] as List<dynamic>? ?? <dynamic>[];
        all.addAll(entries);
        final int total = resp.data['total_count'] as int? ?? 0;
        offset += entries.length;
        hasMore = offset < total;
      } on DioException catch (e) {
        throw CloudSyncException('Box dosyaları listelenemedi.',
            debugDetails: e.message);
      }
    }
    return all;
  }

  AudioTrack _buildTrack(
    dynamic item,
    CloudConnection connection,
    String token,
  ) {
    final String id = item['id'] as String? ?? '';
    final String name = item['name'] as String? ?? '';
    final int dot = name.lastIndexOf('.');
    final String title = dot > 0 ? name.substring(0, dot) : name;
    final String format = dot > 0 ? name.substring(dot + 1).toUpperCase() : 'MP3';

    return AudioTrack(
      id: _uuid.v5(Namespace.url.value, '${connection.id}:$id'),
      connectionId: connection.id,
      provider: connection.platform,
      title: title,
      artist: connection.displayName,
      format: format,
      createdAt: DateTime.now(),
      remoteUrl: 'https://api.box.com/2.0/files/$id/content',
      requestHeaders: <String, String>{'Authorization': 'Bearer $token'},
    );
  }

  bool _isAudio(String name) =>
      _audioExts.contains(_ext(name).toLowerCase());

  String _ext(String name) {
    final int dot = name.lastIndexOf('.');
    return dot > 0 && dot < name.length - 1 ? name.substring(dot + 1) : '';
  }
}
