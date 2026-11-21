import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/http/video.dart';
import 'package:bplus_tv/models/model_hot_video_item.dart';
import 'package:bplus_tv/pages/common/common_list_controller.dart';

class HotController
    extends CommonListController<List<HotVideoItemModel>, HotVideoItemModel> {
  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  Future<LoadingState<List<HotVideoItemModel>>> customGetData() =>
      VideoHttp.hotVideoList(
        pn: page,
        ps: 20,
      );
}
