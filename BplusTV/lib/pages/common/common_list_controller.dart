import 'dart:async';

import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/pages/common/common_controller.dart';
import 'package:get/get.dart';

abstract class CommonListController<R, T> extends CommonController<R, T> {
  int page = 1;
  bool isEnd = false;
  bool? hasFooter;

  /// 加载在途时触发的刷新请求标记，在 queryData 结束后补发
  bool _pendingRefresh = false;

  @override
  Rx<LoadingState<List<T>?>> loadingState =
      LoadingState<List<T>?>.loading().obs;

  void handleListResponse(List<T> dataList) {}

  List<T>? getDataList(R response) {
    return response as List<T>?;
  }

  void checkIsEnd(int length) {}

  @override
  Future<void> queryData([bool isRefresh = true]) async {
    if (isLoading || (!isRefresh && isEnd)) return;
    isLoading = true;
    try {
      final LoadingState<R> res = await customGetData();
      if (res case Success(:final response)) {
        if (!customHandleResponse(isRefresh, res)) {
          final dataList = getDataList(response);
          if (dataList == null || dataList.isEmpty) {
            isEnd = true;
            if (isRefresh) {
              loadingState.value = Success(dataList);
            } else if (hasFooter == true) {
              loadingState.refresh();
            }
            return;
          }
          handleListResponse(dataList);
          if (isRefresh) {
            checkIsEnd(dataList.length);
            loadingState.value = Success(dataList);
            page++;
          } else {
            final current = loadingState.value;
            if (current case Success(:final response)) {
              if (response == null || response.isEmpty) {
                // 缓存为空（例如之前成功但返回空列表）时本次数据直接作为新列表
                loadingState.value = Success([...dataList]);
                checkIsEnd(dataList.length);
              } else {
                response.addAll(dataList);
                loadingState.refresh();
                checkIsEnd(response.length);
              }
            } else {
              // 上次加载失败或还没有数据：不能丢弃本次数据，直接重建列表
              loadingState.value = Success([...dataList]);
              checkIsEnd(dataList.length);
            }
            // 只有数据真正合并后才推进页码，避免加载更多失败导致翻页跳号
            page++;
          }
        }
      } else {
        if (isRefresh && !handleError(res is Error ? res.errMsg : null)) {
          loadingState.value = res as Error;
        }
      }
    } finally {
      isLoading = false;
      if (_pendingRefresh) {
        _pendingRefresh = false;
        unawaited(queryData(true));
      }
    }
  }

  @override
  Future<void> onRefresh() {
    page = 1;
    isEnd = false;
    if (isLoading) {
      // 加载更多在途：记录刷新意图，当前请求结束后自动补发，避免静默丢弃
      _pendingRefresh = true;
      return Future.value();
    }
    return super.onRefresh();
  }

  @override
  Future<void> onReload() {
    loadingState.value = LoadingState<List<T>?>.loading();
    return super.onReload();
  }
}
