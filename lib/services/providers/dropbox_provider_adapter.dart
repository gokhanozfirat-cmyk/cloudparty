import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../models/audio_track.dart';
import '../../models/cloud_folder_item.dart';
import '../../models/cloud_models.dart';
import '../cloud_sync_exception.dart';
import 'oauth_provider_adapter.dart';

class DropboxProviderAdapter extends OAuthProviderAdapter {
  DropboxProviderAdapter() : _uuid = const Uuid();

  final Uuid _uuid;

  static const Set<String> _audioExts = <String>{
    'mp3', 'm4a', 'mp4', 'wav', 'flac', 'alac', 'ogg', 'opus', 'aac',
  };

  @override
  CloudPlatform get platform => CloudPlatform.dropbox;

  @override
  String get clientId => const String.fromEnvironment('DROPBOX_CLIENT_ID');

  @override
  String get authorizationEndpoint =>
      'https://www.dropbox.com/oauth2/authorize';

  @override
  String get tokenEndpoint =>
      'https://api.dropboxapi.com/oauth2/token';

  @override
  List<String> get scopes =>
      <String>['files.metadata.read', 'files.content.read', 'account_info.read'];

  @override
  Map<String, String> get extraAuthParams =>
      const <String, String>{'token_access_type': 'offline'};

  @override
  Future<String?> fetchDisplayName(String accessToken) async {
    try {
      final Response<dynamic> response = await Dio().post<dynamic>(
        'https://api.dropboxapi.com/2/users/get_current_account',
        options: Options(
          headers: <String, String>{'Authorization': 'Bearer $accessToken'},
        ),
        data: 'null',
      );
      final dynamic data = response.data;
      return (data['name']?['display_name'] as String?) ??
          (data['email'] as String?);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<AudioTrack>> fetchTracks(CloudConnection connection) async {
    final String? token = await getValidAccessToken(connection.id);
    if (token == null) {
      throw CloudSyncException('Dropbox oturumu sona erdi. Yeniden bağlan.');
    }
    final List<AudioTrack> tracks = <AudioTrack>[];
    await _collectTracks('', token, connection, tracks);
    return tracks;
  }

  Future<void> _collectTracks(
    String path,
    String token,
    CloudConnection connection,
    List<AudioTrack> tracks,
  ) async {
    final Dio dio = _dio(token);
    String? cursor;
    bool hasMore = true;

    while (hasMore) {
      final Response<dynamic> response = cursor == null
          ? await dio.post<dynamic>(
              'https://api.dropboxapi.com/2/files/list_folder',
              data: <String, dynamic>{
                'path': path,
                'recursive': false,
                'include_non_downloadable_files': false,
              },
            )
          : await dio.post<dynamic>(
              'https://api.dropboxapi.com/2/files/list_folder/continue',
              data: <String, dynamic>{'cursor': cursor},
            );

      final List<dynamic> entries =
          response.data['entries'] as List<dynamic>? ?? <dynamic>[];

      for (final dynamic entry in entries) {
        final String tag = entry['.tag'] as String? ?? '';
        final String name = entry['name'] as String? ?? '';
        final String entryPath = entry['path_display'] as String? ?? '';

        if (tag == 'folder') {
          await _collectTracks(entryPath, token, connection, tracks);
        } else if (tag == 'file' && _isAudio(name)) {
          final String? tempLink = await _getTempLink(entryPath, token);
          if (tempLink != null) {
            tracks.add(_buildTrack(
              connection: connection,
              path: entryPath,
              name: name,
              remoteUrl: tempLink,
            ));
          }
        }
      }

      cursor = response.data['cursor'] as String?;
      hasMore = response.data['has_more'] as bool? ?? false;
    }
  }

  @override
  Future<List<CloudFolderItem>> listFolder(
    CloudConnection connection,
    String? folderId,
  ) async {
    final String? token = await getValidAccessToken(connection.id);
    if (token == null) {
      throw CloudSyncException('Dropbox oturumu sona erdi. Yeniden bağlan.');
    }

    final String path = folderId ?? '';
    final Dio dio = _dio(token);
    final List<CloudFolderItem> items = <CloudFolderItem>[];
    String? cursor;
    bool hasMore = true;

    while (hasMore) {
      final Response<dynamic> response = cursor == null
          ? await dio.post<dynamic>(
              'https://api.dropboxapi.com/2/files/list_folder',
              data: <String, dynamic>{
                'path': path,
                'recursive': false,
                'include_non_downloadable_files': false,
              },
            )
          : await dio.post<dynamic>(
              'https://api.dropboxapi.com/2/files/list_folder/continue',
              data: <String, dynamic>{'cursor': cursor},
            );

      final List<dynamic> entries =
          response.data['entries'] as List<dynamic>? ?? <dynamic>[];

      for (final dynamic entry in entries) {
        final String tag = entry['.tag'] as String? ?? '';
        final String name = entry['name'] as String? ?? '';
        final String entryPath = entry['path_display'] as String? ?? '';

        if (tag == 'folder') {
          items.add(CloudFolderItem(
            id: entryPath,
            name: name,
            isFolder: true,
          ));
        } else if (tag == 'file' && _isAudio(name)) {
          final String? tempLink = await _getTempLink(entryPath, token);
          if (tempLink != null) {
            items.add(CloudFolderItem(
              id: entryPath,
              name: name,
              isFolder: false,
              remoteUrl: tempLink,
              format: _ext(name).toUpperCase(),
            ));
          }
        }
      }

      cursor = response.data['cursor'] as String?;
      hasMore = response.data['has_more'] as bool? ?? false;
    }

    return items;
  }

  Future<String?> _getTempLink(String path, String token) async {
    try {
      final Response<dynamic> resp = await _dio(token).post<dynamic>(
        'https://api.dropboxapi.com/2/files/get_temporary_link',
        data: <String, String>{'path': path},
      );
      return resp.data['link'] as String?;
    } catch (_) {
      return null;
    }
  }

  AudioTrack _buildTrack({
    required CloudConnection connection,
    required String path,
    required String name,
    required String remoteUrl,
  }) {
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
      remoteUrl: remoteUrl,
    );
  }

  bool _isAudio(String name) =>
      _audioExts.contains(_ext(name).toLowerCase());

  String _ext(String name) {
    final int dot = name.lastIndexOf('.');
    return dot > 0 && dot < name.length - 1 ? name.substring(dot + 1) : '';
  }

  Dio _dio(String token) => Dio(BaseOptions(
        headers: <String, String>{'Authorization': 'Bearer $token'},
        contentType: 'application/json',
      ));
}
