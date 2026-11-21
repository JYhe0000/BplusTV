import 'package:bplus_tv/http/fav.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/http/pgc.dart';
import 'package:bplus_tv/models/common/home_tab_type.dart';
import 'package:bplus_tv/models_new/fav/fav_pgc/list.dart';
import 'package:bplus_tv/models_new/pgc/pgc_index_result/list.dart';
import 'package:bplus_tv/models_new/pgc/pgc_timeline/result.dart';
import 'package:bplus_tv/pages/common/common_list_controller.dart';
import 'package:bplus_tv/services/account_service.dart';
import 'package:bplus_tv/utils/extension/scroll_controller_ext.dart';
import 'package:bplus_tv/utils/storage_pref.dart';
import 'package:flutter/widgets.dart' show ScrollController;
import 'package:get/get.dart';

class PgcController
    extends CommonListController<List<PgcIndexItem>?, PgcIndexItem>
    with AccountMixin {
  PgcController({required this.tabType})
    : indexType = tabType == HomeTabType.cinema ? 102 : null;

  final HomeTabType tabType;
  final int? indexType;

  late final showPgcTimeline =
      tabType == HomeTabType.bangumi && Pref.showPgcTimeline;

  @override
  final accountService = Get.find<AccountService>();

  @override
  void onInit() {
    super.onInit();

    queryData();
    queryPgcFollow();
    if (showPgcTimeline) {
      queryPgcTimeline();
    }
  }

  @override
  Future<void> onRefresh() {
    if (accountService.isLogin.value) {
      _refreshPgcFollow();
    }
    if (showPgcTimeline) {
      queryPgcTimeline();
    }
    return super.onRefresh();
  }

  void _refreshPgcFollow() {
    followPage = 1;
    followEnd = false;
    queryPgcFollow();
  }

  // follow
  late int followPage = 1;
  late RxInt followCount = (-1).obs;
  late bool followLoading = false;
  late bool followEnd = false;
  late Rx<LoadingState<List<FavPgcItemModel>?>> followState =
      LoadingState<List<FavPgcItemModel>?>.loading().obs;
  final followController = ScrollController();

  // timeline
  late Rx<LoadingState<List<TimelineResult>?>> timelineState =
      LoadingState<List<TimelineResult>?>.loading().obs;

  Future<void> queryPgcTimeline() async {
    final res = await Future.wait([
      PgcHttp.pgcTimeline(types: 1, before: 6, after: 6),
      PgcHttp.pgcTimeline(types: 4, before: 6, after: 6),
    ]);
    final list1 = res.first.dataOrNull;
    final list2 = res[1].dataOrNull;
    if (list1 != null && list2 != null) {
      // 按 dateTs 匹配合并；两个接口的日期分组数量/顺序可能不一致，不能按下标合并
      final map2 = {for (final item in list2) item.dateTs: item};
      for (final item in list1) {
        final other = map2[item.dateTs];
        if (other != null) {
          item.addAll(other);
        }
      }
    }
    timelineState.value = Success(list1 ?? list2);
  }

  // 我的订阅
  Future<void> queryPgcFollow([bool isRefresh = true]) async {
    if (!accountService.isLogin.value ||
        followLoading ||
        (!isRefresh && followEnd)) {
      return;
    }
    followLoading = true;
    final res = await FavHttp.favPgc(
      type: tabType == HomeTabType.bangumi ? 1 : 2,
      pn: followPage,
    );

    if (res case Success(:final response)) {
      final list = response.list;
      followCount.value = response.total ?? -1;

      if (list == null || list.isEmpty) {
        followEnd = true;
        if (isRefresh) {
          followState.value = Success(list);
        }
        followLoading = false;
        return;
      }

      if (isRefresh) {
        if (list.length >= followCount.value) {
          followEnd = true;
        }
        followState.value = Success(list);
        followController.jumpToTop();
      } else if (followState.value case Success(:final response)) {
        final currentList = response!..addAll(list);
        if (currentList.length >= followCount.value) {
          followEnd = true;
        }
        followState.refresh();
      }
      followPage++;
    } else if (isRefresh) {
      followState.value = res as Error;
    }
    followLoading = false;
  }

  @override
  Future<LoadingState<List<PgcIndexItem>?>> customGetData() => PgcHttp.pgcIndex(
    page: page,
    indexType: indexType,
  );

  @override
  void onClose() {
    followController.dispose();
    super.onClose();
  }

  @override
  void onChangeAccount(bool isLogin) {
    if (isLogin) {
      _refreshPgcFollow();
    } else {
      followState.value = LoadingState.loading();
    }
  }
}
