import 'package:bplus_tv/common/widgets/flutter/refresh_indicator.dart';
import 'package:bplus_tv/common/widgets/loading_widget/http_error.dart';
import 'package:bplus_tv/common/skeleton/video_card_h.dart';
import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/common/widgets/view_sliver_safe_area.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models_new/sub/sub/list.dart';
import 'package:bplus_tv/pages/subscription/controller.dart';
import 'package:bplus_tv/pages/subscription/widgets/item.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class SubPage extends StatefulWidget {
  const SubPage({super.key});

  @override
  State<SubPage> createState() => _SubPageState();
}

class _SubPageState extends State<SubPage> {
  final SubController _subController = Get.put(SubController());

  @override
  Widget build(BuildContext context) {
    return SimpleScaffold(
      appBar: AppBar(title: const Text('我的订阅')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1480),
          child: refreshIndicator(
            onRefresh: _subController.onRefresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                ViewSliverSafeArea(
                  sliver: Obx(
                    () {
                      final state = _subController.loadingState.value;
                      return SliverLayoutBuilder(
                        builder: (context, constraints) => _buildBody(
                          state,
                          SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: constraints.crossAxisExtent >= 1000
                                ? 2
                                : 1,
                            mainAxisExtent: 230,
                            mainAxisSpacing: 20,
                            crossAxisSpacing: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    LoadingState<List<SubItemModel>?> loadingState,
    SliverGridDelegate delegate,
  ) {
    return switch (loadingState) {
      Loading() => SliverGrid(
        gridDelegate: delegate,
        delegate: SliverChildBuilderDelegate(
          (_, _) => const VideoCardHSkeleton(),
          childCount: 8,
        ),
      ),
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: delegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    _subController.onLoadMore();
                  }
                  final item = response[index];
                  return SubItem(
                    item: item,
                    cancelSub: () => _subController.cancelSub(item),
                  );
                },
                itemCount: response.length,
              )
            : HttpError(onReload: _subController.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _subController.onReload,
      ),
    };
  }
}
