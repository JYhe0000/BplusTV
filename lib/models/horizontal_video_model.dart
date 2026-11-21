import 'package:bplus_tv/models/model_video.dart';
import 'package:bplus_tv/models_new/video/video_detail/dimension.dart';

abstract class HorizontalVideoModel extends BaseVideoItemModel {
  bool? isPugv;
  int? seasonId;

  int? roomId;
  bool? isLive;

  Dimension? dimension;

  String? badge;

  num? progress;

  String? redirectUrl;

  // search
  List<({bool isEm, String text})>? titleList;
}
