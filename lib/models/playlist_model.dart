class PlaylistModel {
  PlaylistModel({
    required this.id,
    required this.name,
    this.trackIds = const <String>[],
    this.autoPlay = true,
  });

  final String id;
  final String name;
  final List<String> trackIds;
  final bool autoPlay;

  PlaylistModel copyWith({
    String? name,
    List<String>? trackIds,
    bool? autoPlay,
  }) {
    return PlaylistModel(
      id: id,
      name: name ?? this.name,
      trackIds: trackIds ?? this.trackIds,
      autoPlay: autoPlay ?? this.autoPlay,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'trackIds': trackIds, 'autoPlay': autoPlay};
  }

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      id: json['id'] as String,
      name: json['name'] as String,
      trackIds: List<String>.from(
        json['trackIds'] as List<dynamic>? ?? <String>[],
      ),
      autoPlay: json['autoPlay'] as bool? ?? true,
    );
  }
}
