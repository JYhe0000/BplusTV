import 'package:bplus_tv/http/api.dart';

enum WebSsType {
  season(Api.seasonArchives),
  series(Api.seriesArchives),
  ;

  final String api;
  const WebSsType(this.api);
}
