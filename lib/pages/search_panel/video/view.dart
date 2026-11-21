import 'package:bplus_tv/common/widgets/sliver/sliver_floating_header.dart';
import 'package:bplus_tv/common/skeleton/video_card_h.dart';
import 'package:bplus_tv/models/common/search/video_search_type.dart';
import 'package:bplus_tv/models/search/result.dart';
import 'package:bplus_tv/pages/search/widgets/search_text.dart';
import 'package:bplus_tv/pages/search_panel/video/controller.dart';
import 'package:bplus_tv/pages/search_panel/video/widgets/item.dart';
import 'package:bplus_tv/pages/search_panel/view.dart';
import 'package:bplus_tv/utils/grid.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class SearchVideoPanel extends CommonSearchPanel {
  const SearchVideoPanel({
    super.key,
    required super.keyword,
    required super.tag,
    required super.searchType,
  });

  @override
  State<SearchVideoPanel> createState() => _SearchVideoPanelState();
}

class _SearchVideoPanelState
    extends
        CommonSearchPanelState<
          SearchVideoPanel,
          SearchVideoData,
          SearchVideoItemModel
        >
    with GridMixin, SearchVideoPanelMixin<SearchVideoPanel> {
  @override
  late final SearchVideoController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      SearchVideoController(
        keyword: widget.keyword,
        searchType: widget.searchType,
        tag: widget.tag,
      ),
      tag: widget.searchType.name + widget.tag,
    );
  }
}

mixin SearchVideoPanelMixin<S extends SearchVideoPanel>
    on
        CommonSearchPanelState<S, SearchVideoData, SearchVideoItemModel>,
        GridMixin {
  @override
  SearchVideoController get controller;

  @override
  Widget buildHeader() {
    return SliverFloatingHeaderWidget(
      backgroundColor: Colors.transparent,
      child: TvSearchFilterBar(
        onFilter: () => controller.onShowFilterDialog(context),
        children: [
          for (final e in ArchiveFilterType.values)
            Obx(
              () {
                final selected = controller.selectedType.value == e;
                return SearchText(
                  fontSize: 17,
                  text: e.desc,
                  bgColor: selected
                      ? colorScheme.primary.withValues(alpha: 0.14)
                      : Colors.transparent,
                  textColor: selected
                      ? colorScheme.primary
                      : colorScheme.outline,
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  onTap: (_) => controller
                    ..order = e == .totalrank ? '' : e.name
                    ..selectedType.value = e
                    ..onSortSearch(getBack: false),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget buildList(List<SearchVideoItemModel> list, double contentWidth) {
    return buildResultGrid(
      contentWidth: contentWidth,
      itemBuilder: (context, index, tileWidth) {
        if (index == list.length - 1) {
          controller.onLoadMore();
        }
        return SearchVideoResultItem(
          item: list[index],
          tileWidth: tileWidth,
        );
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
