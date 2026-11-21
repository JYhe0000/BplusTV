import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/http/match.dart';
import 'package:bplus_tv/models_new/match/match_info/contest.dart';
import 'package:bplus_tv/pages/common/dyn/common_dyn_controller.dart';
import 'package:get/get.dart';

class MatchInfoController extends CommonDynController {
  @override
  final int oid = int.tryParse(Get.parameters['cid']?.toString() ?? '') ?? 0;
  @override
  final int replyType = 27;

  @override
  dynamic get sourceId => oid.toString();

  final Rx<LoadingState<MatchContest?>> infoState =
      LoadingState<MatchContest?>.loading().obs;

  @override
  void onInit() {
    super.onInit();
    getMatchInfo();
  }

  Future<void> getMatchInfo() async {
    final res = await MatchHttp.matchInfo(oid);
    if (res.isSuccess) {
      queryData();
    }
    infoState.value = res;
  }
}
