import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/http/user.dart';
import 'package:bplus_tv/models_new/follow/data.dart';
import 'package:bplus_tv/pages/follow_type/controller.dart';

class FollowSameController extends FollowTypeController {
  @override
  Future<LoadingState<FollowData>> customGetData() =>
      UserHttp.sameFollowing(mid: mid, pn: page);
}
