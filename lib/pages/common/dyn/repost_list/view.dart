import 'package:bplus_tv/common/widgets/flutter/refresh_indicator.dart';
import 'package:bplus_tv/common/widgets/loading_widget/http_error.dart';
import 'package:bplus_tv/common/widgets/loading_widget/loading_widget.dart';
import 'package:bplus_tv/grpc/bilibili/app/dynamic/v2.pb.dart' show DynamicItem;
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/pages/common/dyn/common_dyn_page.dart';
import 'package:bplus_tv/pages/common/dyn/repost_list/controller.dart';
import 'package:bplus_tv/pages/common/dyn/repost_list/widgets/item.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart' hide ListTile;

class DynRepostPage extends StatelessWidget {
  const DynRepostPage({
    super.key,
    required this.id,
    required this.controller,
  });

  final Object id;
  final DynRepostController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.loadingState.value == .loading()) {
      controller.queryData();
    }
    Widget buildBody(LoadingState<List<DynamicItem>?> state) {
      return switch (state) {
        Loading() => const SliverFillRemaining(child: m3eLoading),
        Success(:final response) =>
          response != null && response.isNotEmpty
              ? SliverList.builder(
                  itemCount: response.length,
                  itemBuilder: (context, index) {
                    if (index == response.length - 1) {
                      controller.onLoadMore();
                    }

                    return DynRepostItem(item: response[index]);
                  },
                )
              : HttpError(onReload: controller.onReload),
        Error(:final errMsg) => HttpError(
          errMsg: errMsg,
          onReload: controller.onReload,
        ),
      };
    }

    final child = CustomScrollView(
      key: const PageStorageKey(DynType.repost),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: .only(
            bottom: MediaQuery.viewPaddingOf(context).bottom + 100,
          ),
          sliver: Obx(() => buildBody(controller.loadingState.value)),
        ),
      ],
    );
    return refreshIndicator(onRefresh: controller.onRefresh, child: child);
  }
}
