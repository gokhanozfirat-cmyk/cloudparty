import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../models/audio_track.dart';
import '../../models/cloud_folder_item.dart';
import '../../models/cloud_models.dart';
import '../cloud_sync_exception.dart';
import '../secure_connection_store.dart';
import 'cloud_provider_adapter.dart';

class WebDavProviderAdapter extends CloudProviderAdapter {
  WebDavProviderAdapter({SecureConnectionStore? secureStore})
      : _secureStore = secureStore ?? SecureConnectionStore(),
        _uuid = const Uuid();

  final SecureConnectionStore _secureStore;
  final Uuid _uuid;

  static const Set<String> _supportedExtensions = <String>{
    'mp3', 'm4a', 'mp4', 'wav', 'flac', 'alac', 'ogg', 'opus', 'aac',
  };

  @override
  CloudPlatform get platform => CloudPlatform.webDav;

  @override
  Future<CloudConnection> connect({
    required String connectionId,
    required String fallbackDisplayName,
    Map<String, String> extraData = const {},
  }) async {
    final String url = (extraData['url'] ?? '').trim().replaceAll(RegExp(r'/+$'), '');
    final String username = extraData['username'] ?? '';
    final String password = extraData['password'] ?? '';

    if (url.isEmpty) {
      throw CloudSyncException('WebDAV URL gereklidir.');
    }

    final Dio dio = _buildDio(username, password);
    try {
      final response = await dio.request<dynamic>(
        url,
        options: Options(
          method: 'PROPFIND',
          headers: <String, String>{'Depth': '0'},
          validateStatus: (int? s) => s != null && s < 500,
        ),
      );
      if (response.statusCode == 401) {
        throw CloudSyncException('Kimlik doğrulama başarısız. Kullanıcı adı/şifre kontrol et.');
      }
      if (response.statusCode != null && response.statusCode! >= 400) {
        throw CloudSyncException('Sunucuya bağlanılamadı (${response.statusCode}).');
      }
    } on DioException catch (e) {
      throw CloudSyncException(
        'WebDAV sunucusuna ulaşılamadı.',
        debugDetails: e.message,
      );
    }

    await _secureStore.write(connectionId, <String, dynamic>{
      'url': url,
      'username': username,
      'password': password,
    });

    final Uri parsed = Uri.tryParse(url) ?? Uri();
    final String displayName = username.isNotEmpty
        ? '$username @ ${parsed.host}'
        : parsed.host.isNotEmpty
            ? parsed.host
            : fallbackDisplayName;

    return CloudConnection(
      id: connectionId,
      platform: platform,
      displayName: displayName,
      connectedAt: DateTime.now(),
    );
  }

  @override
  Future<List<AudioTrack>> fetchTracks(CloudConnection connection) async {
    final Map<String, dynamic>? creds = await _secureStore.read(connection.id);
    if (creds == null) {
      throw CloudSyncException('WebDAV kimlik bilgileri bulunamadı. Yeniden bağlan.');
    }
    final String baseUrl = creds['url'] as String;
    final String username = creds['username'] as String;
    final String password = creds['password'] as String;
    final Dio dio = _buildDio(username, password);
    final List<AudioTrack> tracks = <AudioTrack>[];
    await _collectTracks(dio, baseUrl, baseUrl, connection, username, password, tracks);
    return tracks;
  }

  Future<void> _collectTracks(
    Dio dio,
    String baseUrl,
    String folderUrl,
    CloudConnection connection,
    String username,
    String password,
    List<AudioTrack> tracks,
  ) async {
    final List<_WebDavEntry> entries = await _listEntries(dio, folderUrl);
    for (final _WebDavEntry entry in entries) {
      final String fullUrl = _fullUrl(entry.href, baseUrl);
      if (fullUrl == folderUrl || fullUrl == '$folderUrl/') continue;
      if (entry.isCollection) {
        await _collectTracks(dio, baseUrl, fullUrl, connection, username, password, tracks);
      } else if (_isAudio(entry)) {
        tracks.add(_entryToTrack(entry, fullUrl, connection, username, password));
      }
    }
  }

  @override
  Future<List<CloudFolderItem>> listFolder(
    CloudConnection connection,
    String? folderId,
  ) async {
    final Map<String, dynamic>? creds = await _secureStore.read(connection.id);
    if (creds == null) {
      throw CloudSyncException('WebDAV kimlik bilgileri bulunamadı. Yeniden bağlan.');
    }
    final String baseUrl = creds['url'] as String;
    final String username = creds['username'] as String;
    final String password = creds['password'] as String;
    final String folderUrl = folderId ?? baseUrl;
    final Dio dio = _buildDio(username, password);
    final List<_WebDavEntry> entries = await _listEntries(dio, folderUrl);
    final List<CloudFolderItem> items = <CloudFolderItem>[];
    for (final _WebDavEntry entry in entries) {
      final String fullUrl = _fullUrl(entry.href, baseUrl);
      if (fullUrl == folderUrl || fullUrl == '$folderUrl/') continue;
      if (!entry.isCollection && !_isAudio(entry)) continue;
      items.add(CloudFolderItem(
        id: fullUrl,
        name: entry.displayName,
        isFolder: entry.isCollection,
        mimeType: entry.contentType,
        remoteUrl: entry.isCollection ? null : fullUrl,
        requestHeaders: entry.isCollection
            ? null
            : <String, String>{
                'Authorization': _basicAuth(username, password),
              },
        format: entry.isCollection ? null : _formatFromName(entry.displayName),
      ));
    }
    return items;
  }

  @override
  Future<Map<String, String>?> getFreshHeaders(CloudConnection connection) async {
    final Map<String, dynamic>? creds = await _secureStore.read(connection.id);
    if (creds == null) return null;
    final String username = creds['username'] as String;
    final String password = creds['password'] as String;
    return <String, String>{'Authorization': _basicAuth(username, password)};
  }

  @override
  Future<void> disconnect(CloudConnection connection) async {
    await _secureStore.delete(connection.id);
  }

  Future<List<_WebDavEntry>> _listEntries(Dio dio, String folderUrl) async {
    try {
      final Response<String> response = await dio.request<String>(
        folderUrl,
        options: Options(
          method: 'PROPFIND',
          headers: <String, String>{
            'Depth': '1',
            'Content-Type': 'application/xml; charset=utf-8',
          },
          responseType: ResponseType.plain,
          validateStatus: (int? s) => s != null && s < 500,
        ),
        data: '<?xml version="1.0" encoding="utf-8"?>'
            '<D:propfind xmlns:D="DAV:">'
            '<D:prop><D:displayname/><D:resourcetype/><D:getcontenttype/></D:prop>'
            '</D:propfind>',
      );
      return _parseMultistatus(response.data ?? '');
    } on DioException catch (e) {
      throw CloudSyncException('Klasör listelenemedi.', debugDetails: e.message);
    }
  }

  List<_WebDavEntry> _parseMultistatus(String xml) {
    final List<_WebDavEntry> entries = <_WebDavEntry>[];
    final RegExp responseRx = RegExp(
      r'<[A-Za-z0-9_-]+:response[^>]*>(.*?)</[A-Za-z0-9_-]+:response>',
      dotAll: true,
    );
    for (final RegExpMatch match in responseRx.allMatches(xml)) {
      final String content = match.group(1)!;
      final RegExpMatch? hrefMatch = RegExp(
        r'<[A-Za-z0-9_-]+:href[^>]*>(.*?)</[A-Za-z0-9_-]+:href>',
      ).firstMatch(content);
      if (hrefMatch == null) continue;
      final String href = Uri.decodeComponent(hrefMatch.group(1)!.trim());
      final bool isCollection =
          RegExp(r'<[A-Za-z0-9_-]+:collection\s*/?>').hasMatch(content);
      final RegExpMatch? nameMatch = RegExp(
        r'<[A-Za-z0-9_-]+:displayname[^>]*>(.*?)</[A-Za-z0-9_-]+:displayname>',
        dotAll: true,
      ).firstMatch(content);
      String displayName = nameMatch?.group(1)?.trim() ?? '';
      if (displayName.isEmpty) {
        displayName = Uri.decodeComponent(href.replaceAll(RegExp(r'/+$'), '').split('/').last);
      }
      final RegExpMatch? ctMatch = RegExp(
        r'<[A-Za-z0-9_-]+:getcontenttype[^>]*>(.*?)</[A-Za-z0-9_-]+:getcontenttype>',
      ).firstMatch(content);
      final String? contentType = ctMatch?.group(1)?.trim();
      entries.add(_WebDavEntry(
        href: href,
        isCollection: isCollection,
        displayName: displayName,
        contentType: contentType,
      ));
    }
    return entries;
  }

  String _fullUrl(String href, String baseUrl) {
    if (href.startsWith('http://') || href.startsWith('https://')) return href;
    final Uri base = Uri.parse(baseUrl);
    final String portStr = base.port > 0 ? ':${base.port}' : '';
    return '${base.scheme}://${base.host}$portStr$href';
  }

  Dio _buildDio(String username, String password) {
    final Dio dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 15)));
    if (username.isNotEmpty || password.isNotEmpty) {
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          options.headers['Authorization'] = _basicAuth(username, password);
          handler.next(options);
        },
      ));
    }
    return dio;
  }

  String _basicAuth(String username, String password) =>
      'Basic ${base64.encode(utf8.encode('$username:$password'))}';

  AudioTrack _entryToTrack(
    _WebDavEntry entry,
    String fullUrl,
    CloudConnection connection,
    String username,
    String password,
  ) {
    final String name = entry.displayName;
    final int dot = name.lastIndexOf('.');
    final String title = dot > 0 ? name.substring(0, dot) : name;
    final String format = dot > 0 ? name.substring(dot + 1).toUpperCase() : 'MP3';
    return AudioTrack(
      id: _uuid.v5(Namespace.url.value, '${connection.id}:$fullUrl'),
      connectionId: connection.id,
      provider: connection.platform,
      title: title,
      artist: connection.displayName,
      format: format,
      createdAt: DateTime.now(),
      remoteUrl: fullUrl,
      requestHeaders: <String, String>{'Authorization': _basicAuth(username, password)},
    );
  }

  bool _isAudio(_WebDavEntry entry) {
    final String? ct = entry.contentType?.toLowerCase();
    if (ct != null && (ct.startsWith('audio/') || ct == 'video/mp4')) return true;
    return _supportedExtensions.contains(_ext(entry.displayName).toLowerCase());
  }

  String _ext(String name) {
    final int dot = name.lastIndexOf('.');
    return dot > 0 && dot < name.length - 1 ? name.substring(dot + 1) : '';
  }

  String? _formatFromName(String name) {
    final String ext = _ext(name);
    return ext.isNotEmpty ? ext.toUpperCase() : null;
  }
}

class _WebDavEntry {
  const _WebDavEntry({
    required this.href,
    required this.isCollection,
    required this.displayName,
    this.contentType,
  });

  final String href;
  final bool isCollection;
  final String displayName;
  final String? contentType;
}
