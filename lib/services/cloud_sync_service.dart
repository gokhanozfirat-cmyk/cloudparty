import 'package:uuid/uuid.dart';

import '../models/audio_track.dart';
import '../models/cloud_models.dart';
import 'cloud_sync_exception.dart';
import 'providers/cloud_provider_adapter.dart';
import 'providers/generic_cloud_provider_adapter.dart';
import 'providers/google_drive_provider_adapter.dart';

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
      CloudPlatform.dropbox: GenericCloudProviderAdapter(CloudPlatform.dropbox),
      CloudPlatform.oneDrive: GenericCloudProviderAdapter(
        CloudPlatform.oneDrive,
      ),
      CloudPlatform.oneDriveBusiness: GenericCloudProviderAdapter(
        CloudPlatform.oneDriveBusiness,
      ),
      CloudPlatform.box: GenericCloudProviderAdapter(CloudPlatform.box),
      CloudPlatform.pCloud: GenericCloudProviderAdapter(CloudPlatform.pCloud),
      CloudPlatform.hiDrive: GenericCloudProviderAdapter(CloudPlatform.hiDrive),
      CloudPlatform.mediafireIos: GenericCloudProviderAdapter(
        CloudPlatform.mediafireIos,
      ),
      CloudPlatform.webDav: GenericCloudProviderAdapter(CloudPlatform.webDav),
    };
  }

  Future<CloudConnection> connectPlatform(
    CloudPlatform platform, {
    required String fallbackDisplayName,
  }) async {
    final CloudProviderAdapter? adapter = _providers[platform];
    if (adapter == null) {
      throw CloudSyncException('This cloud provider is not configured.');
    }

    return adapter.connect(
      connectionId: _uuid.v4(),
      fallbackDisplayName: fallbackDisplayName,
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
