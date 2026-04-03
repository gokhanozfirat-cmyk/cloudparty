class CloudFolderItem {
  const CloudFolderItem({
    required this.id,
    required this.name,
    required this.isFolder,
    this.mimeType,
    this.remoteUrl,
    this.requestHeaders,
    this.artist,
    this.format,
  });

  final String id;
  final String name;
  final bool isFolder;
  final String? mimeType;
  final String? remoteUrl;
  final Map<String, String>? requestHeaders;
  final String? artist;
  final String? format;
}
