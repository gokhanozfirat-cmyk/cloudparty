import 'package:uuid/uuid.dart';

import '../models/audio_track.dart';
import '../models/cloud_folder_item.dart';
import '../models/cloud_models.dart';
import 'cloud_sync_exception.dart';
import 'providers/box_provider_adapter.dart';
import 'providers/cloud_provider_adapter.dart';
import 'providers/dropbox_provider_adapter.dart';
import 'providers/generic_cloud_provider_adapter.dart';
import 'providers/google_drive_provider_adapter.dart';
import 'providers/hidrive_provider_adapter.dart';
import 'providers/onedrive_provider_adapter.dart';
import 'providers/pcloud_provider_adapter.dart';
import 'providers/oauth_provider_adapter.dart';
import 'providers/webdav_provider_adapter.dart';

class CloudSyncService {
  CloudSyncService({
    Map<CloudPlatform, CloudProviderAdapter>? providers,
    Uuid? uuid,
  }) : _providers = providers ?? _defaultProviders(),
       _uuid = uuid ?? const Uuid();

  final Map<CloudPlatform, CloudProviderAdapter> _providers;
  final Uuid _uuid;

  static Map<CloudPlatform, CloudProviderAdapter> _defaultProviders() {
    return <CloudPlatform, CloudProviderAdapter>{
      CloudPlatform.googleDrive: GoogleDriveProviderAdapter(),
      CloudPlatform.dropbox: DropboxProviderAdapter(),
      CloudPlatform.oneDrive: OneDriveProviderAdapter(CloudPlatform.oneDrive),
      CloudPlatform.oneDriveBusiness:
          OneDriveProviderAdapter(CloudPlatform.oneDriveBusiness),
      CloudPlatform.box: BoxProviderAdapter(),
      CloudPlatform.pCloud: PCloudProviderAdapter(),
      CloudPlatform.hiDrive: HiDriveProviderAdapter(),
      CloudPlatform.mediafireIos:
          GenericCloudProviderAdapter(CloudPlatform.mediafireIos),
      CloudPlatform.webDav: WebDavProviderAdapter(),
    };
  }

  Future<CloudConnection> connectPlatform(
    CloudPlatform platform, {
    required String fallbackDisplayName,
    Map<String, String> extraData = const {},
  }) async {
    final CloudProviderAdapter? adapter = _providers[platform];
    if (adapter == null) {
      throw CloudSyncException('This cloud provider is not configured.');
    }

    return adapter.connect(
      connectionId: _uuid.v4(),
      fallbackDisplayName: fallbackDisplayName,
      extraData: extraData,
    );
  }

  Future<List<AudioTrack>> fetchTracksForConnection(
    CloudConnection connection,
  ) async {
    final CloudProviderAdapter? adapter = _providers[connection.platform];
    if (adapter == null) {
      throw CloudSyncException('Provider not found for this connection.');
    }

    return adapter.fetchTracks(connection);
  }

  Future<void> disconnectConnection(CloudConnection connection) async {
    final CloudProviderAdapter? adapter = _providers[connection.platform];
    if (adapter == null) {
      return;
    }
    await adapter.disconnect(connection);
  }

  Future<Map<String, String>?> getFreshHeaders(
    CloudConnection connection,
  ) async {
    final CloudProviderAdapter? adapter = _providers[connection.platform];
    return adapter?.getFreshHeaders(connection);
  }

  Future<List<CloudFolderItem>> listFolder(
    CloudConnection connection,
    String? folderId,
  ) async {
    final CloudProviderAdapter? adapter = _providers[connection.platform];
    if (adapter == null) return <CloudFolderItem>[];
    return adapter.listFolder(connection, folderId);
  }

  /// Completes an OAuth exchange that was interrupted by a process kill.
  /// Returns the new [CloudConnection] if pending state + initial link match,
  /// or null otherwise.
  Future<CloudConnection?> completePendingOAuth() async {
    for (final CloudProviderAdapter adapter in _providers.values) {
      if (adapter is OAuthProviderAdapter) {
        final CloudConnection? result = await adapter.completePendingIfNeeded();
        if (result != null) return result;
      }
    }
    return null;
  }

  AudioTrack createManualTrack({
    required CloudConnection connection,
    required String title,
    required String url,
    String artist = 'Manual Import',
  }) {
    final String extension = _extractExtension(url);
    return AudioTrack(
      id: _uuid.v4(),
      connectionId: connection.id,
      provider: connection.platform,
      title: title,
      artist: artist,
      format: extension,
      createdAt: DateTime.now(),
      remoteUrl: url,
      isManual: true,
    );
  }

  String _extractExtension(String url) {
    final Uri parsed = Uri.tryParse(url) ?? Uri();
    final String path = parsed.path;
    final int dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) {
      return 'MP3';
    }
    return path.substring(dot + 1).toUpperCase();
  }
}
