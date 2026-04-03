import '../../models/audio_track.dart';
import '../../models/cloud_models.dart';
import '../cloud_sync_exception.dart';
import 'cloud_provider_adapter.dart';

class GenericCloudProviderAdapter extends CloudProviderAdapter {
  GenericCloudProviderAdapter(this._platform);

  final CloudPlatform _platform;

  @override
  CloudPlatform get platform => _platform;

  @override
  Future<CloudConnection> connect({
    required String connectionId,
    required String fallbackDisplayName,
    Map<String, String> extraData = const {},
  }) async {
    throw CloudSyncException(
      '${_platform.label} henüz desteklenmiyor. Yakında eklenecek!',
    );
  }

  @override
  Future<List<AudioTrack>> fetchTracks(CloudConnection connection) async {
    return <AudioTrack>[];
  }

  @override
  Future<void> disconnect(CloudConnection connection) async {}
}
