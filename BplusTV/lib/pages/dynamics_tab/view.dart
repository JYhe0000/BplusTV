import 'dart:async';

import 'package:bplus_tv/common/widgets/flutter/refresh_indicator.dart';
import 'package:bplus_tv/common/widgets/loading_widget/http_error.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models/common/dynamic/dynamics_type.dart';
import 'package:bplus_tv/models/dynamics/result.dart';
import 'package:bplus_tv/pages/dynamics/controller.dart';
import 'package:bplus_tv/pages/dynamics/widgets/dynamic_panel.dart';
import 'package:bplus_tv/pages/dynamics_tab/controller.dart';
import 'package:bplus_tv/utils/extension/get_ext.dart';
import 'package:bplus_tv/utils/global_data.dart';
import 'package:bplus_tv/utils/waterfall.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:waterfall_flow/waterfall_flow.dart'
    hide SliverWaterfallFlowDelegateWithMaxCrossAxisExtent;

class DynamicsTabPage extends StatefulWidget {
  const DynamicsTabPage({super.key, required this.dynamicsType});

  final DynamicsTabType dynamicsType;

  @override
  State<DynamicsTabPage> createState() => _DynamicsTabPageState();
}

class _DynamicsTabPageState extends State<DynamicsTabPage>
    with AutomaticKeepAliveClientMixin, DynMixin {
  final dynamicsController = Get.putOrFind(DynamicsController.new);
  late final DynamicsTabController controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    controller = Get.putOrFind(
      () => DynamicsTabController(dynamicsType: widget.dynamicsType),
      tag: widget.dynamicsType.name,
    );
    super.initState();
  }

  Future<void> onRefresh() {
    dynamicsController.singleRefresh();
    return controller.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return refreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: controller.scrollController,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 100),
            sliver: buildPage(
              Obx(() => _buildBody(controller.loadingState.value)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(LoadingState<List<DynamicItemModel>?> loadingState) {
    return switch (loadingState) {
      Loading() => dynSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? GlobalData().dynamicsWaterfallFlow
                  ? SliverWaterfallFlow(
                      gridDelegate: dynGridDelegate,
                      delegate: SliverChildBuilderDelegate(
                        (_, index) => _itemBuilder(response, index),
                        findChildIndexCallback: (key) =>
                            _findItemIndex(response, key),
                        childCount: response.length,
                      ),
                    )
                  : SliverList.builder(
                      findChildIndexCallback: (key) =>
                          _findItemIndex(response, key),
                      itemBuilder: (context, index) =>
                          _itemBuilder(response, index),
                      itemCount: response.length,
                    )
            : HttpError(onReload: controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: controller.onReload,
      ),
    };
  }

  Widget _itemBuilder(List<DynamicItemModel> list, int index) {
    if (index == list.length - 1) {
      controller.onLoadMore();
    }
    final item = list[index];
    return DynamicPanel(
      key: ValueKey(item.idStr),
      item: item,
      onRemove: (idStr) => controller.onRemove(index, idStr),
      onBlock: () => controller.onBlock(index),
      onUnfold: () => controller.onUnfold(item, index),
    );
  }

  int? _findItemIndex(List<DynamicItemModel> items, Key key) {
    if (key is! ValueKey) return null;
    final index = items.indexWhere((item) => item.idStr == key.value);
    return index < 0 ? null : index;
  }
}
