import '../../models/audio_track.dart';
import '../../models/cloud_folder_item.dart';
import '../../models/cloud_models.dart';

abstract class CloudProviderAdapter {
  CloudPlatform get platform;

  Future<CloudConnection> connect({
    required String connectionId,
    required String fallbackDisplayName,
    Map<String, String> extraData = const {},
  });

  Future<List<AudioTrack>> fetchTracks(CloudConnection connection);

  Future<List<CloudFolderItem>> listFolder(
    CloudConnection connection,
    String? folderId,
  ) async =>
      <CloudFolderItem>[];

  Future<Map<String, String>?> getFreshHeaders(
    CloudConnection connection,
  ) async =>
      null;

  Future<void> disconnect(CloudConnection connection) async {}
}
