import 'dart:async';

import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/utils/extension/scroll_controller_ext.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding, SchedulerPhase;
import 'package:flutter/widgets.dart' show ScrollController;
import 'package:get/get.dart';

mixin ScrollOrRefreshMixin {
  ScrollController get scrollController;

  void animateToTop() => scrollController.animToTop();

  Future<void> onRefresh();

  void toTopOrRefresh() {
    if (scrollController.hasClients) {
      if (scrollController.position.pixels == 0) {
        EasyThrottle.throttle(
          'topOrRefresh-${identityHashCode(this)}',
          const Duration(milliseconds: 500),
          onRefresh,
        );
      } else {
        animateToTop();
      }
    }
  }
}

abstract class CommonController<R, T> extends GetxController
    with ScrollOrRefreshMixin {
  @override
  final ScrollController scrollController = ScrollController();

  bool isLoading = false;
  Future<void>? _loadMoreFuture;
  Rx<LoadingState> get loadingState;

  Future<LoadingState<R>> customGetData();

  Future<void> queryData([bool isRefresh = true]);

  bool customHandleResponse(bool isRefresh, Success<R> response) {
    return false;
  }

  bool handleError(String? errMsg) {
    return false;
  }

  @override
  Future<void> onRefresh() {
    return queryData();
  }

  Future<void> onLoadMore() {
    if (isClosed) return Future.value();
    final pending = _loadMoreFuture;
    if (pending != null) return pending;
    final completer = Completer<void>();
    _loadMoreFuture = completer.future;
    unawaited(_loadMore(completer));
    return completer.future;
  }

  Future<void> _loadMore(Completer<void> completer) async {
    try {
      // 末卡通常在布局阶段触发分页，请求准备工作放到当前帧绘制之后。
      if (SchedulerBinding.instance.schedulerPhase ==
          SchedulerPhase.persistentCallbacks) {
        await SchedulerBinding.instance.endOfFrame;
      }
      if (!isClosed) await queryData(false);
      completer.complete();
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
    } finally {
      _loadMoreFuture = null;
    }
  }

  Future<void> onReload() {
    return onRefresh();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
