import 'package:bplus_tv/common/skeleton/video_card_h.dart';
import 'package:bplus_tv/common/widgets/sliver/sliver_floating_header.dart';
import 'package:bplus_tv/models/search/result.dart';
import 'package:bplus_tv/pages/search/widgets/search_text.dart';
import 'package:bplus_tv/pages/search_panel/article/controller.dart';
import 'package:bplus_tv/pages/search_panel/article/widgets/item.dart';
import 'package:bplus_tv/pages/search_panel/view.dart';
import 'package:bplus_tv/utils/grid.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class SearchArticlePanel extends CommonSearchPanel {
  const SearchArticlePanel({
    super.key,
    required super.keyword,
    required super.tag,
    required super.searchType,
  });

  @override
  State<SearchArticlePanel> createState() => _SearchArticlePanelState();
}

class _SearchArticlePanelState
    extends
        CommonSearchPanelState<
          SearchArticlePanel,
          SearchArticleData,
          SearchArticleItemModel
        >
    with GridMixin {
  @override
  late final SearchArticleController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      SearchArticleController(
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
              final selected = controller.articleOrderType.value.index != 0;
              return SearchText(
                text: '排序: ${controller.articleOrderType.value.label}',
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
              final selected = controller.articleZoneType!.value.index != 0;
              return SearchText(
                text: '分区: ${controller.articleZoneType!.value.label}',
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
  Widget buildList(List<SearchArticleItemModel> list, double contentWidth) {
    return buildResultGrid(
      contentWidth: contentWidth,
      itemBuilder: (_, index, _) {
        if (index == list.length - 1) {
          controller.onLoadMore();
        }
        return SearchArticleItem(item: list[index]);
      },
      itemCount: list.length,
    );
  }

  @override
  Widget buildLoading(double contentWidth) => buildResultGrid(
    contentWidth: contentWidth,
    itemCount: 8,
    itemBuilder: (_, _, _) => const VideoCardHSkeleton(),
  );
}
