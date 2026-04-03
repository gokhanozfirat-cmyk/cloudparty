import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../models/audio_track.dart';
import '../../models/cloud_folder_item.dart';
import '../../models/cloud_models.dart';
import '../cloud_sync_exception.dart';
import 'oauth_provider_adapter.dart';

class PCloudProviderAdapter extends OAuthProviderAdapter {
  PCloudProviderAdapter() : _uuid = const Uuid();

  final Uuid _uuid;

  // pCloud hosts: api.pcloud.com (US), eapi.pcloud.com (EU)
  // We'll try US first; EU users may need to change this.
  static const String _apiBase = 'https://api.pcloud.com';

  static const Set<String> _audioExts = <String>{
    'mp3', 'm4a', 'mp4', 'wav', 'flac', 'alac', 'ogg', 'opus', 'aac',
  };

  @override
  CloudPlatform get platform => CloudPlatform.pCloud;

  @override
  String get clientId => const String.fromEnvironment('PCLOUD_CLIENT_ID');

  @override
  String get authorizationEndpoint =>
      'https://my.pcloud.com/oauth2/authorize';

  @override
  String get tokenEndpoint => '$_apiBase/oauth2_token';

  @override
  List<String> get scopes => <String>[];

  @override
  Future<String?> fetchDisplayName(String accessToken) async {
    try {
      final Response<dynamic> resp = await Dio().get<dynamic>(
        '$_apiBase/userinfo',
        queryParameters: <String, String>{'access_token': accessToken},
      );
      return resp.data['email'] as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<AudioTrack>> fetchTracks(CloudConnection connection) async {
    final String? token = await getValidAccessToken(connection.id);
    if (token == null) {
      throw CloudSyncException('pCloud oturumu sona erdi. Yeniden bağlan.');
    }
    final List<AudioTrack> tracks = <AudioTrack>[];
    await _collectTracks(0, token, connection, tracks);
    return tracks;
  }

  Future<void> _collectTracks(
    int folderId,
    String token,
    CloudConnection connection,
    List<AudioTrack> tracks,
  ) async {
    final List<dynamic> contents = await _listFolder(folderId, token);
    for (final dynamic item in contents) {
      final bool isFolder = item['isfolder'] as bool? ?? false;
      if (isFolder) {
        await _collectTracks(
            item['folderid'] as int, token, connection, tracks);
      } else {
        final String name = item['name'] as String? ?? '';
        if (_isAudio(name)) {
          final String? link = await _getFileLink(
              item['fileid'] as int, token);
          if (link != null) {
            tracks.add(_buildTrack(item, link, connection));
          }
        }
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
      throw CloudSyncException('pCloud oturumu sona erdi. Yeniden bağlan.');
    }

    final int folderIdInt =
        folderId != null ? int.tryParse(folderId) ?? 0 : 0;
    final List<dynamic> contents = await _listFolder(folderIdInt, token);
    final List<CloudFolderItem> result = <CloudFolderItem>[];

    for (final dynamic item in contents) {
      final bool isFolder = item['isfolder'] as bool? ?? false;
      final String name = item['name'] as String? ?? '';

      if (isFolder) {
        result.add(CloudFolderItem(
          id: '${item['folderid']}',
          name: name,
          isFolder: true,
        ));
      } else if (_isAudio(name)) {
        final String? link =
            await _getFileLink(item['fileid'] as int, token);
        if (link != null) {
          result.add(CloudFolderItem(
            id: '${item['fileid']}',
            name: name,
            isFolder: false,
            remoteUrl: link,
            format: _ext(name).toUpperCase(),
          ));
        }
      }
    }
    return result;
  }

  Future<List<dynamic>> _listFolder(int folderId, String token) async {
    try {
      final Response<dynamic> resp = await Dio().get<dynamic>(
        '$_apiBase/listfolder',
        queryParameters: <String, dynamic>{
          'folderid': folderId,
          'access_token': token,
        },
      );
      return resp.data['metadata']?['contents'] as List<dynamic>? ??
          <dynamic>[];
    } on DioException catch (e) {
      throw CloudSyncException('pCloud klasörü listelenemedi.',
          debugDetails: e.message);
    }
  }

  Future<String?> _getFileLink(int fileId, String token) async {
    try {
      final Response<dynamic> resp = await Dio().get<dynamic>(
        '$_apiBase/getfilelink',
        queryParameters: <String, dynamic>{
          'fileid': fileId,
          'access_token': token,
        },
      );
      final List<dynamic> hosts =
          resp.data['hosts'] as List<dynamic>? ?? <dynamic>[];
      final String path = resp.data['path'] as String? ?? '';
      if (hosts.isEmpty || path.isEmpty) return null;
      return 'https://${hosts.first}$path';
    } catch (_) {
      return null;
    }
  }

  AudioTrack _buildTrack(
    dynamic item,
    String remoteUrl,
    CloudConnection connection,
  ) {
    final String name = item['name'] as String? ?? '';
    final int fileId = item['fileid'] as int? ?? 0;
    final int dot = name.lastIndexOf('.');
    final String title = dot > 0 ? name.substring(0, dot) : name;
    final String format = dot > 0 ? name.substring(dot + 1).toUpperCase() : 'MP3';

    return AudioTrack(
      id: _uuid.v5(Namespace.url.value, '${connection.id}:$fileId'),
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
}
