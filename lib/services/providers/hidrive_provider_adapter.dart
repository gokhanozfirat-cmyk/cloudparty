import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../models/audio_track.dart';
import '../../models/cloud_folder_item.dart';
import '../../models/cloud_models.dart';
import '../cloud_sync_exception.dart';
import 'oauth_provider_adapter.dart';

class HiDriveProviderAdapter extends OAuthProviderAdapter {
  HiDriveProviderAdapter() : _uuid = const Uuid();

  final Uuid _uuid;

  static const String _apiBase = 'https://my.hidrive.com/api';

  static const Set<String> _audioExts = <String>{
    'mp3', 'm4a', 'mp4', 'wav', 'flac', 'alac', 'ogg', 'opus', 'aac',
  };

  @override
  CloudPlatform get platform => CloudPlatform.hiDrive;

  @override
  String get clientId => const String.fromEnvironment('HIDRIVE_CLIENT_ID');

  @override
  String? get clientSecret {
    const String s = String.fromEnvironment('HIDRIVE_CLIENT_SECRET');
    return s.isEmpty ? null : s;
  }

  @override
  String get authorizationEndpoint =>
      'https://my.hidrive.com/oauth2/authorize';

  @override
  String get tokenEndpoint => 'https://my.hidrive.com/oauth2/token';

  @override
  List<String> get scopes => <String>['user', 'rw'];

  @override
  Future<String?> fetchDisplayName(String accessToken) async {
    try {
      final Response<dynamic> resp = await Dio().get<dynamic>(
        '$_apiBase/user/me',
        options: Options(
          headers: <String, String>{'Authorization': 'Bearer $accessToken'},
        ),
      );
      return resp.data['alias'] as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<AudioTrack>> fetchTracks(CloudConnection connection) async {
    final String? token = await getValidAccessToken(connection.id);
    if (token == null) {
      throw CloudSyncException('HiDrive oturumu sona erdi. Yeniden bağlan.');
    }
    final List<AudioTrack> tracks = <AudioTrack>[];
    await _collectTracks('/', token, connection, tracks);
    return tracks;
  }

  Future<void> _collectTracks(
    String path,
    String token,
    CloudConnection connection,
    List<AudioTrack> tracks,
  ) async {
    final List<dynamic> members = await _listDir(path, token);
    for (final dynamic item in members) {
      final String type = item['type'] as String? ?? '';
      final String name = item['name'] as String? ?? '';
      final String itemPath = item['path'] as String? ?? '';

      if (type == 'dir') {
        await _collectTracks(itemPath, token, connection, tracks);
      } else if (type == 'file' && _isAudio(name)) {
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
      throw CloudSyncException('HiDrive oturumu sona erdi. Yeniden bağlan.');
    }

    final String path = folderId ?? '/';
    final List<dynamic> members = await _listDir(path, token);
    final List<CloudFolderItem> result = <CloudFolderItem>[];

    for (final dynamic item in members) {
      final String type = item['type'] as String? ?? '';
      final String name = item['name'] as String? ?? '';
      final String itemPath = item['path'] as String? ?? '';
      final bool isFolder = type == 'dir';
      if (!isFolder && !_isAudio(name)) continue;

      result.add(CloudFolderItem(
        id: itemPath,
        name: name,
        isFolder: isFolder,
        remoteUrl: isFolder
            ? null
            : '$_apiBase/file?path=${Uri.encodeComponent(itemPath)}',
        requestHeaders: isFolder
            ? null
            : <String, String>{'Authorization': 'Bearer $token'},
        format: isFolder ? null : _ext(name).toUpperCase(),
      ));
    }
    return result;
  }

  Future<List<dynamic>> _listDir(String path, String token) async {
    try {
      final Response<dynamic> resp = await Dio().get<dynamic>(
        '$_apiBase/dir',
        queryParameters: <String, String>{'path': path},
        options: Options(
          headers: <String, String>{'Authorization': 'Bearer $token'},
        ),
      );
      return resp.data['members'] as List<dynamic>? ?? <dynamic>[];
    } on DioException catch (e) {
      throw CloudSyncException('HiDrive klasörü listelenemedi.',
          debugDetails: e.message);
    }
  }

  AudioTrack _buildTrack(
    dynamic item,
    CloudConnection connection,
    String token,
  ) {
    final String name = item['name'] as String? ?? '';
    final String path = item['path'] as String? ?? '';
    final int dot = name.lastIndexOf('.');
    final String title = dot > 0 ? name.substring(0, dot) : name;
    final String format = dot > 0 ? name.substring(dot + 1).toUpperCase() : 'MP3';

    return AudioTrack(
      id: _uuid.v5(Namespace.url.value, '${connection.id}:$path'),
      connectionId: connection.id,
      provider: connection.platform,
      title: title,
      artist: connection.displayName,
      format: format,
      createdAt: DateTime.now(),
      remoteUrl: '$_apiBase/file?path=${Uri.encodeComponent(path)}',
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
