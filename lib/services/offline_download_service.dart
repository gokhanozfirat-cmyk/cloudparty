import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../models/audio_track.dart';

class OfflineDownloadService {
  OfflineDownloadService() : _dio = Dio();

  final Dio _dio;

  Future<AudioTrack> downloadTrack(AudioTrack track) async {
    if (track.isOffline) {
      return track;
    }

    final Directory baseDir = await getApplicationDocumentsDirectory();
    final Directory downloadsDir = Directory('${baseDir.path}/downloads');
    if (!downloadsDir.existsSync()) {
      downloadsDir.createSync(recursive: true);
    }

    final String extension = _extensionFromUrl(track.remoteUrl);
    final String outputPath = '${downloadsDir.path}/${track.id}.$extension';

    await _dio.download(
      track.remoteUrl,
      outputPath,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
        headers: track.requestHeaders,
      ),
    );

    return track.copyWith(localPath: outputPath);
  }

  String _extensionFromUrl(String url) {
    final Uri parsed = Uri.tryParse(url) ?? Uri();
    final String path = parsed.path;
    final int dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) {
      return 'mp3';
    }
    return path.substring(dot + 1).toLowerCase();
  }
}
