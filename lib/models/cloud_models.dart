enum CloudPlatform {
  googleDrive,
  dropbox,
  oneDrive,
  oneDriveBusiness,
  box,
  pCloud,
  hiDrive,
  mediafireIos,
  webDav,
}

extension CloudPlatformX on CloudPlatform {
  String get label {
    switch (this) {
      case CloudPlatform.googleDrive:
        return 'Google Drive';
      case CloudPlatform.dropbox:
        return 'Dropbox';
      case CloudPlatform.oneDrive:
        return 'OneDrive';
      case CloudPlatform.oneDriveBusiness:
        return 'OneDrive Business';
      case CloudPlatform.box:
        return 'Box';
      case CloudPlatform.pCloud:
        return 'pCloud';
      case CloudPlatform.hiDrive:
        return 'HiDrive';
      case CloudPlatform.mediafireIos:
        return 'Mediafire (iOS)';
      case CloudPlatform.webDav:
        return 'WebDAV';
    }
  }

  String get shortHint {
    switch (this) {
      case CloudPlatform.googleDrive:
        return 'OAuth + Drive API';
      case CloudPlatform.dropbox:
        return 'OAuth + Dropbox API';
      case CloudPlatform.oneDrive:
      case CloudPlatform.oneDriveBusiness:
        return 'OAuth + Microsoft Graph';
      case CloudPlatform.box:
        return 'OAuth + Box API';
      case CloudPlatform.pCloud:
        return 'OAuth + pCloud API';
      case CloudPlatform.hiDrive:
        return 'OAuth + HiDrive API';
      case CloudPlatform.mediafireIos:
        return 'iOS client support';
      case CloudPlatform.webDav:
        return 'ownCloud / NextCloud / NAS';
    }
  }

  bool get isIosOnly => this == CloudPlatform.mediafireIos;

  static CloudPlatform fromName(String value) {
    return CloudPlatform.values.firstWhere((item) => item.name == value);
  }
}

class CloudConnection {
  CloudConnection({
    required this.id,
    required this.platform,
    required this.displayName,
    required this.connectedAt,
    this.externalAccountId,
  });

  final String id;
  final CloudPlatform platform;
  final String displayName;
  final DateTime connectedAt;
  final String? externalAccountId;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'platform': platform.name,
      'displayName': displayName,
      'connectedAt': connectedAt.toIso8601String(),
      'externalAccountId': externalAccountId,
    };
  }

  factory CloudConnection.fromJson(Map<String, dynamic> json) {
    return CloudConnection(
      id: json['id'] as String,
      platform: CloudPlatformX.fromName(json['platform'] as String),
      displayName: json['displayName'] as String,
      connectedAt: DateTime.parse(json['connectedAt'] as String),
      externalAccountId: json['externalAccountId'] as String?,
    );
  }
}

const List<String> supportedAudioFormats = <String>[
  'MP3',
  'M4A',
  'WAV',
  'FLAC',
  'ALAC',
];
