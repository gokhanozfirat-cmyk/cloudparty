import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../models/audio_track.dart';
import '../../models/cloud_folder_item.dart';
import '../../models/cloud_models.dart';
import '../cloud_sync_exception.dart';
import 'oauth_provider_adapter.dart';

/// Covers both OneDrive personal and OneDrive for Business.
class OneDriveProviderAdapter extends OAuthProviderAdapter {
  OneDriveProviderAdapter(this._platform) : _uuid = const Uuid();

  final CloudPlatform _platform;
  final Uuid _uuid;

  static const String _tenantId = 'common';
  static const String _graphBase = 'https://graph.microsoft.com/v1.0';

  static const Set<String> _audioExts = <String>{
    'mp3', 'm4a', 'mp4', 'wav', 'flac', 'alac', 'ogg', 'opus', 'aac',
  };

  @override
  CloudPlatform get platform => _platform;

  @override
  String get clientId => _platform == CloudPlatform.oneDriveBusiness
      ? const String.fromEnvironment('ONEDRIVE_BUSINESS_CLIENT_ID')
      : const String.fromEnvironment('ONEDRIVE_CLIENT_ID');

  @override
  String get authorizationEndpoint =>
      'https://login.microsoftonline.com/$_tenantId/oauth2/v2.0/authorize';

  @override
  String get tokenEndpoint =>
      'https://login.microsoftonline.com/$_tenantId/oauth2/v2.0/token';

  @override
  List<String> get scopes =>
      <String>['Files.Read', 'offline_access', 'User.Read'];

  @override
  Future<String?> fetchDisplayName(String accessToken) async {
    try {
      final Response<dynamic> resp = await Dio().get<dynamic>(
        '$_graphBase/me',
        options: Options(
          headers: <String, String>{'Authorization': 'Bearer $accessToken'},
        ),
      );
      return (resp.data['displayName'] as String?) ??
          (resp.data['userPrincipalName'] as String?);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<AudioTrack>> fetchTracks(CloudConnection connection) async {
    final String? token = await getValidAccessToken(connection.id);
    if (token == null) {
      throw CloudSyncException('OneDrive oturumu sona erdi. Yeniden bağlan.');
    }
    final List<AudioTrack> tracks = <AudioTrack>[];
    await _collectTracks('root', token, connection, tracks);
    return tracks;
  }

  Future<void> _collectTracks(
    String itemId,
    String token,
    CloudConnection connection,
    List<AudioTrack> tracks,
  ) async {
    final List<dynamic> items = await _listItems(itemId, token);
    for (final dynamic item in items) {
      if (item['folder'] != null) {
        await _collectTracks(item['id'] as String, token, connection, tracks);
      } else if (_isAudio(item)) {
        final AudioTrack? track = _buildTrack(item, connection, token);
        if (track != null) tracks.add(track);
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
      throw CloudSyncException('OneDrive oturumu sona erdi. Yeniden bağlan.');
    }

    final String itemId = folderId ?? 'root';
    final List<dynamic> items = await _listItems(itemId, token);
    final List<CloudFolderItem> result = <CloudFolderItem>[];

    for (final dynamic item in items) {
      final bool isFolder = item['folder'] != null;
      if (!isFolder && !_isAudio(item)) continue;
      final String id = item['id'] as String;
      final String name = item['name'] as String? ?? '';
      final String? downloadUrl =
          item['@microsoft.graph.downloadUrl'] as String?;

      result.add(CloudFolderItem(
        id: id,
        name: name,
        isFolder: isFolder,
        remoteUrl: isFolder ? null : (downloadUrl ?? '$_graphBase/me/drive/items/$id/content'),
        requestHeaders: isFolder || downloadUrl != null
            ? null
            : <String, String>{'Authorization': 'Bearer $token'},
        format: isFolder ? null : _ext(name).toUpperCase(),
      ));
    }
    return result;
  }

  Future<List<dynamic>> _listItems(String itemId, String token) async {
    final List<dynamic> all = <dynamic>[];
    String? nextLink =
        '$_graphBase/me/drive/items/$itemId/children?\$select=id,name,folder,file,@microsoft.graph.downloadUrl&\$top=200';

    final Dio dio = Dio(BaseOptions(
      headers: <String, String>{'Authorization': 'Bearer $token'},
    ));

    while (nextLink != null) {
      try {
        final Response<dynamic> resp =
            await dio.get<dynamic>(nextLink);
        final List<dynamic> value =
            resp.data['value'] as List<dynamic>? ?? <dynamic>[];
        all.addAll(value);
        nextLink = resp.data['@odata.nextLink'] as String?;
      } on DioException catch (e) {
        throw CloudSyncException('OneDrive dosyaları listelenemedi.',
            debugDetails: e.message);
      }
    }
    return all;
  }

  AudioTrack? _buildTrack(
    dynamic item,
    CloudConnection connection,
    String token,
  ) {
    final String id = item['id'] as String? ?? '';
    final String name = item['name'] as String? ?? '';
    if (id.isEmpty || name.isEmpty) return null;

    final String? downloadUrl = item['@microsoft.graph.downloadUrl'] as String?;
    final String remoteUrl =
        downloadUrl ?? '$_graphBase/me/drive/items/$id/content';
    final Map<String, String>? headers = downloadUrl != null
        ? null
        : <String, String>{'Authorization': 'Bearer $token'};

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
      remoteUrl: remoteUrl,
      requestHeaders: headers,
    );
  }

  bool _isAudio(dynamic item) {
    if (item['folder'] != null) return false;
    final String? mime = (item['file']?['mimeType'] as String?)?.toLowerCase();
    if (mime != null && (mime.startsWith('audio/') || mime == 'video/mp4')) {
      return true;
    }
    return _audioExts.contains(_ext(item['name'] as String? ?? '').toLowerCase());
  }

  String _ext(String name) {
    final int dot = name.lastIndexOf('.');
    return dot > 0 && dot < name.length - 1 ? name.substring(dot + 1) : '';
  }
}
