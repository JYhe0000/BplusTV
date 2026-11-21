import 'package:bplus_tv/models_new/pgc/pgc_info_model/episode.dart';

class Section {
  int? id;
  String? title;
  int? type;
  List<EpisodeItem>? episodes;

  Section({
    this.id,
    this.title,
    this.type,
    this.episodes,
  });

  factory Section.fromJson(Map<String, dynamic> json) => Section(
    id: json['id'] as int?,
    title: json['title'] as String?,
    type: json['type'] as int?,
    episodes: (json['episodes'] as List<dynamic>?)
        ?.map((e) => EpisodeItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
