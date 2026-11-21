import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/http/member.dart';
import 'package:bplus_tv/models_new/follow/data.dart';
import 'package:bplus_tv/models_new/follow/list.dart';
import 'package:bplus_tv/pages/common/search/common_search_controller.dart';

class FollowSearchController
    extends CommonSearchController<FollowData, FollowItemModel> {
  FollowSearchController(this.mid);
  final int mid;

  @override
  Future<LoadingState<FollowData>> customGetData() =>
      MemberHttp.getfollowSearch(
        mid: mid,
        ps: 20,
        pn: page,
        name: editController.value.text,
      );

  @override
  List<FollowItemModel>? getDataList(FollowData response) {
    return response.list;
  }
}
