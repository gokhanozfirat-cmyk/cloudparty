import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:uuid/uuid.dart';

import '../../models/audio_track.dart';
import '../../models/cloud_folder_item.dart';
import '../../models/cloud_models.dart';
import '../cloud_sync_exception.dart';
import '../secure_connection_store.dart';
import 'cloud_provider_adapter.dart';

class GoogleDriveProviderAdapter implements CloudProviderAdapter {
  GoogleDriveProviderAdapter({
    GoogleSignIn? googleSignIn,
    SecureConnectionStore? secureStore,
  }) : _googleSignIn =
           googleSignIn ??
           GoogleSignIn(
             scopes: const <String>[drive.DriveApi.driveReadonlyScope],
             clientId: _readDefine('GOOGLE_WEB_CLIENT_ID'),
             serverClientId: _readDefine('GOOGLE_SERVER_CLIENT_ID'),
           ),
       _secureStore = secureStore ?? SecureConnectionStore(),
       _uuid = const Uuid();

  final GoogleSignIn _googleSignIn;
  final SecureConnectionStore _secureStore;
  final Uuid _uuid;

  static const Set<String> _supportedExtensions = <String>{
    'mp3',
    'm4a',
    'mp4',
    'wav',
    'flac',
    'alac',
    'ogg',
    'opus',
    'aac',
  };

  @override
  CloudPlatform get platform => CloudPlatform.googleDrive;

  @override
  Future<CloudConnection> connect({
    required String connectionId,
    required String fallbackDisplayName,
    Map<String, String> extraData = const {},
  }) async {
    GoogleSignInAccount? account;
    try {
      account = await _googleSignIn.signInSilently();
      account ??= await _googleSignIn.signIn();
    } catch (error) {
      throw CloudSyncException(
        'Google Drive connection failed.',
        debugDetails: error.toString(),
      );
    }

    if (account == null) {
      throw CloudSyncException('Google Drive sign-in was cancelled.');
    }

    final GoogleSignInAuthentication auth = await account.authentication;
    if (auth.accessToken == null || auth.accessToken!.isEmpty) {
      throw CloudSyncException('Google Drive token could not be received.');
    }

    await _secureStore.write(connectionId, <String, dynamic>{
      'provider': platform.name,
      'email': account.email,
      'displayName': account.displayName,
      'connectedAt': DateTime.now().toIso8601String(),
    });

    return CloudConnection(
      id: connectionId,
      platform: platform,
      displayName: _displayNameOf(account, fallbackDisplayName),
      connectedAt: DateTime.now(),
      externalAccountId: account.id,
    );
  }

  @override
  Future<List<AudioTrack>> fetchTracks(CloudConnection connection) async {
    final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
    if (account == null) {
      throw CloudSyncException(
        'Google Drive session is not active. Please reconnect.',
      );
    }

    final client = await _googleSignIn.authenticatedClient();
    if (client == null) {
      throw CloudSyncException(
        'Google Drive authenticated client is unavailable. Reconnect required.',
      );
    }

    final GoogleSignInAuthentication auth = await account.authentication;
    if (auth.accessToken == null || auth.accessToken!.isEmpty) {
      throw CloudSyncException(
        'Google Drive token is missing. Reconnect required.',
      );
    }

    final drive.DriveApi api = drive.DriveApi(client);
    final List<AudioTrack> tracks = <AudioTrack>[];
    String? pageToken;

    try {
      do {
        final drive.FileList response = await api.files.list(
          q: "trashed = false and (mimeType contains 'audio/' or mimeType contains 'video/mp4' or name contains '.mp3' or name contains '.m4a' or name contains '.mp4' or name contains '.wav' or name contains '.flac' or name contains '.alac' or name contains '.ogg' or name contains '.opus' or name contains '.aac')",
          $fields:
              'nextPageToken, files(id,name,mimeType,modifiedTime,size,owners(displayName))',
          orderBy: 'modifiedTime desc',
          pageSize: 200,
          pageToken: pageToken,
          spaces: 'drive',
          corpora: 'user',
        );

        final List<drive.File> files = response.files ?? <drive.File>[];
        for (final drive.File file in files) {
          if (!_isAudio(file)) {
            continue;
          }
          final String? fileId = file.id;
          if (fileId == null || fileId.isEmpty) {
            continue;
          }

          final String rawName = (file.name ?? 'Audio').trim();
          final String fileFormat = _resolveFormat(rawName, file.mimeType);

          tracks.add(
            AudioTrack(
              id: _uuid.v5(Namespace.url.value, '${connection.id}:$fileId'),
              connectionId: connection.id,
              provider: connection.platform,
              title: _stripExtension(rawName),
              artist:
                  file.owners?.firstOrNull?.displayName ??
                  connection.displayName,
              format: fileFormat,
              createdAt: file.modifiedTime ?? DateTime.now(),
              remoteUrl:
                  'https://www.googleapis.com/drive/v3/files/$fileId?alt=media',
              requestHeaders: <String, String>{
                'Authorization': 'Bearer ${auth.accessToken}',
              },
            ),
          );
        }

        pageToken = response.nextPageToken;
      } while (pageToken != null && pageToken.isNotEmpty);
    } catch (error) {
      throw CloudSyncException(
        'Could not fetch Google Drive audio files.',
        debugDetails: error.toString(),
      );
    } finally {
      client.close();
    }

    return tracks;
  }

  @override
  Future<List<CloudFolderItem>> listFolder(
    CloudConnection connection,
    String? folderId,
  ) async {
    final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
    if (account == null) {
      throw CloudSyncException('Google Drive session expired. Please reconnect.');
    }

    final client = await _googleSignIn.authenticatedClient();
    if (client == null) {
      throw CloudSyncException('Google Drive client unavailable. Reconnect required.');
    }

    final GoogleSignInAuthentication auth = await account.authentication;
    if (auth.accessToken == null || auth.accessToken!.isEmpty) {
      throw CloudSyncException('Google Drive token missing. Reconnect required.');
    }

    final drive.DriveApi api = drive.DriveApi(client);
    final String parentId = folderId ?? 'root';
    final List<CloudFolderItem> items = <CloudFolderItem>[];
    String? pageToken;

    try {
      do {
        final drive.FileList response = await api.files.list(
          q: "'$parentId' in parents and trashed = false",
          $fields:
              'nextPageToken, files(id,name,mimeType,owners(displayName))',
          orderBy: 'folder,name',
          pageSize: 200,
          pageToken: pageToken,
          spaces: 'drive',
          corpora: 'user',
        );

        for (final drive.File file in response.files ?? <drive.File>[]) {
          final bool isFolder =
              file.mimeType == 'application/vnd.google-apps.folder';
          if (!isFolder && !_isAudio(file)) continue;
          final String id = file.id ?? '';
          if (id.isEmpty) continue;

          items.add(
            CloudFolderItem(
              id: id,
              name: file.name ?? 'Unknown',
              isFolder: isFolder,
              mimeType: file.mimeType,
              remoteUrl: isFolder
                  ? null
                  : 'https://www.googleapis.com/drive/v3/files/$id?alt=media',
              requestHeaders: isFolder
                  ? null
                  : <String, String>{
                      'Authorization': 'Bearer ${auth.accessToken}',
                    },
              artist: file.owners?.firstOrNull?.displayName ??
                  connection.displayName,
              format: isFolder
                  ? null
                  : _resolveFormat(file.name ?? '', file.mimeType),
            ),
          );
        }
        pageToken = response.nextPageToken;
      } while (pageToken != null && pageToken.isNotEmpty);
    } finally {
      client.close();
    }

    return items;
  }

  @override
  Future<Map<String, String>?> getFreshHeaders(
    CloudConnection connection,
  ) async {
    final GoogleSignInAccount? account =
        await _googleSignIn.signInSilently();
    if (account == null) return null;
    final GoogleSignInAuthentication auth = await account.authentication;
    if (auth.accessToken == null || auth.accessToken!.isEmpty) return null;
    return <String, String>{'Authorization': 'Bearer ${auth.accessToken}'};
  }

  @override
  Future<void> disconnect(CloudConnection connection) async {
    await _secureStore.delete(connection.id);
    await _googleSignIn.disconnect();
  }

  static String? _readDefine(String key) {
    final String value = String.fromEnvironment(key);
    if (value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }

  String _displayNameOf(
    GoogleSignInAccount account,
    String fallbackDisplayName,
  ) {
    final String? name = account.displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    if (account.email.trim().isNotEmpty) {
      return account.email.trim();
    }
    return fallbackDisplayName;
  }

  bool _isAudio(drive.File file) {
    final String? mimeType = file.mimeType?.toLowerCase();
    if (mimeType != null && mimeType.startsWith('audio/')) {
      return true;
    }

    final String? name = file.name;
    if (name == null || name.trim().isEmpty) {
      return false;
    }

    final String ext = _extension(name).toLowerCase();
    return _supportedExtensions.contains(ext);
  }

  String _resolveFormat(String name, String? mimeType) {
    final String ext = _extension(name).toUpperCase();
    if (ext.isNotEmpty) {
      return ext;
    }

    if (mimeType == null || mimeType.isEmpty) {
      return 'MP3';
    }
    if (mimeType.contains('/')) {
      return mimeType.split('/').last.toUpperCase();
    }
    return mimeType.toUpperCase();
  }

  String _stripExtension(String name) {
    final int dot = name.lastIndexOf('.');
    if (dot <= 0) {
      return name;
    }
    return name.substring(0, dot);
  }

  String _extension(String name) {
    final int dot = name.lastIndexOf('.');
    if (dot <= -1 || dot == name.length - 1) {
      return '';
    }
    return name.substring(dot + 1);
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
