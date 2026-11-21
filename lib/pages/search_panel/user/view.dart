import 'package:bplus_tv/common/skeleton/msg_feed_top.dart';
import 'package:bplus_tv/common/widgets/sliver/sliver_floating_header.dart';
import 'package:bplus_tv/models/search/result.dart';
import 'package:bplus_tv/pages/search/widgets/search_text.dart';
import 'package:bplus_tv/pages/search_panel/user/controller.dart';
import 'package:bplus_tv/pages/search_panel/user/widgets/item.dart';
import 'package:bplus_tv/pages/search_panel/view.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class SearchUserPanel extends CommonSearchPanel {
  const SearchUserPanel({
    super.key,
    required super.keyword,
    required super.tag,
    required super.searchType,
  });

  @override
  State<SearchUserPanel> createState() => _SearchUserPanelState();
}

class _SearchUserPanelState
    extends
        CommonSearchPanelState<
          SearchUserPanel,
          SearchUserData,
          SearchUserItemModel
        > {
  @override
  late final SearchUserController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      SearchUserController(
        keyword: widget.keyword,
        searchType: widget.searchType,
        tag: widget.tag,
      ),
      tag: widget.searchType.name + widget.tag,
    );
  }

  @override
  Widget buildHeader() {
    return SliverFloatingHeaderWidget(
      backgroundColor: Colors.transparent,
      child: TvSearchFilterBar(
        onFilter: () => controller.onShowFilterDialog(context),
        children: [
          Obx(
            () {
              final selected = controller.userOrderType!.value.index != 0;
              return SearchText(
                text: '排序: ${controller.userOrderType!.value.label}',
                fontSize: 16,
                bgColor: selected
                    ? colorScheme.primary.withValues(alpha: 0.14)
                    : Colors.transparent,
                textColor: selected ? colorScheme.primary : colorScheme.outline,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                onTap: (_) => controller.onShowFilterDialog(context),
              );
            },
          ),
          Obx(
            () {
              final selected = controller.userType!.value.index != 0;
              return SearchText(
                text: '用户类型: ${controller.userType!.value.label}',
                fontSize: 16,
                bgColor: selected
                    ? colorScheme.primary.withValues(alpha: 0.14)
                    : Colors.transparent,
                textColor: selected ? colorScheme.primary : colorScheme.outline,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                onTap: (_) => controller.onShowFilterDialog(context),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget buildList(List<SearchUserItemModel> list, double contentWidth) {
    return buildResultGrid(
      contentWidth: contentWidth,
      itemHeight: 132,
      itemBuilder: (_, index, _) {
        if (index == list.length - 1) {
          controller.onLoadMore();
        }
        return SearchUserItem(
          item: list[index],
        );
      },
      itemCount: list.length,
    );
  }

  @override
  Widget buildLoading(double contentWidth) => buildResultGrid(
    contentWidth: contentWidth,
    itemHeight: 132,
    itemCount: 8,
    itemBuilder: (_, _, _) => const MsgFeedTopSkeleton(),
  );
}
