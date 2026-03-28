import '../../models/audio_track.dart';
import '../../models/cloud_models.dart';

abstract class CloudProviderAdapter {
  CloudPlatform get platform;

  Future<CloudConnection> connect({
    required String connectionId,
    required String fallbackDisplayName,
  });

  Future<List<AudioTrack>> fetchTracks(CloudConnection connection);

  Future<void> disconnect(CloudConnection connection) async {}
}
