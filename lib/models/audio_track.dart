import 'cloud_models.dart';

class AudioTrack {
  AudioTrack({
    required this.id,
    required this.connectionId,
    required this.provider,
    required this.title,
    required this.artist,
    required this.format,
    required this.createdAt,
    required this.remoteUrl,
    this.durationSeconds,
    this.localPath,
    this.requestHeaders,
    this.isManual = false,
  });

  final String id;
  final String connectionId;
  final CloudPlatform provider;
  final String title;
  final String artist;
  final String format;
  final int? durationSeconds;
  final DateTime createdAt;
  final String remoteUrl;
  final String? localPath;
  final Map<String, String>? requestHeaders;
  final bool isManual;

  bool get isOffline => localPath != null && localPath!.isNotEmpty;

  Uri get playUri {
    if (isOffline) {
      return Uri.file(localPath!);
    }
    return Uri.parse(remoteUrl);
  }

  AudioTrack copyWith({
    String? localPath,
    int? durationSeconds,
    Map<String, String>? requestHeaders,
  }) {
    return AudioTrack(
      id: id,
      connectionId: connectionId,
      provider: provider,
      title: title,
      artist: artist,
      format: format,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAt: createdAt,
      remoteUrl: remoteUrl,
      localPath: localPath ?? this.localPath,
      requestHeaders: requestHeaders ?? this.requestHeaders,
      isManual: isManual,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'connectionId': connectionId,
      'provider': provider.name,
      'title': title,
      'artist': artist,
      'format': format,
      'durationSeconds': durationSeconds,
      'createdAt': createdAt.toIso8601String(),
      'remoteUrl': remoteUrl,
      'localPath': localPath,
      'isManual': isManual,
    };
  }

  factory AudioTrack.fromJson(Map<String, dynamic> json) {
    return AudioTrack(
      id: json['id'] as String,
      connectionId: json['connectionId'] as String,
      provider: CloudPlatformX.fromName(json['provider'] as String),
      title: json['title'] as String,
      artist: json['artist'] as String,
      format: json['format'] as String,
      durationSeconds: json['durationSeconds'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      remoteUrl: json['remoteUrl'] as String,
      localPath: json['localPath'] as String?,
      requestHeaders: null,
      isManual: json['isManual'] as bool? ?? false,
    );
  }
}
