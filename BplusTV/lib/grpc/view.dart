import 'package:bplus_tv/grpc/bilibili/app/viewunite/v1.pb.dart'
    show ViewReq, ViewReply;
import 'package:bplus_tv/grpc/grpc_req.dart';
import 'package:bplus_tv/grpc/url.dart';
import 'package:bplus_tv/http/loading_state.dart';

abstract final class ViewGrpc {
  static Future<LoadingState<ViewReply>> view({
    required String bvid,
  }) {
    return GrpcReq.request(
      GrpcUrl.view,
      ViewReq(bvid: bvid),
      ViewReply.fromBuffer,
    );
  }
}
