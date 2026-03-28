import '../../models/audio_track.dart';
import '../../models/cloud_models.dart';
import 'cloud_provider_adapter.dart';

class GenericCloudProviderAdapter implements CloudProviderAdapter {
  GenericCloudProviderAdapter(this._platform);

  final CloudPlatform _platform;

  @override
  CloudPlatform get platform => _platform;

  @override
  Future<CloudConnection> connect({
    required String connectionId,
    required String fallbackDisplayName,
  }) async {
    return CloudConnection(
      id: connectionId,
      platform: _platform,
      displayName: fallbackDisplayName,
      connectedAt: DateTime.now(),
    );
  }

  @override
  Future<List<AudioTrack>> fetchTracks(CloudConnection connection) async {
    return <AudioTrack>[];
  }

  @override
  Future<void> disconnect(CloudConnection connection) async {}
}
