import 'package:bplus_tv/http/api.dart';
import 'package:bplus_tv/http/error_msg.dart';
import 'package:bplus_tv/http/init.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models_new/follow/data.dart';

abstract final class FanHttp {
  static Future<LoadingState<FollowData>> fans({
    int? vmid,
    int? pn,
    int ps = 20,
    String? orderType,
  }) async {
    final res = await Request().get(
      Api.fans,
      queryParameters: {
        'vmid': vmid,
        'pn': pn,
        'ps': ps,
        'order': 'desc',
        'order_type': orderType,
      },
    );
    if (res.data['code'] == 0) {
      return Success(FollowData.fromJson(res.data['data']));
    } else {
      return Error(errorMsg[res.data['code']] ?? res.data['message']);
    }
  }
}
