import 'package:bplus_tv/common/skeleton/video_card_v.dart';
import 'package:bplus_tv/common/sliver_single_child_delegate.dart';
import 'package:bplus_tv/common/style.dart';
import 'package:bplus_tv/models/search/result.dart';
import 'package:bplus_tv/pages/search_panel/controller.dart';
import 'package:bplus_tv/pages/search_panel/live/widgets/item.dart';
import 'package:bplus_tv/pages/search_panel/view.dart';
import 'package:bplus_tv/utils/grid.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class SearchLivePanel extends CommonSearchPanel {
  const SearchLivePanel({
    super.key,
    required super.keyword,
    required super.tag,
    required super.searchType,
  });

  @override
  State<SearchLivePanel> createState() => _SearchLivePanelState();
}

class _SearchLivePanelState
    extends
        CommonSearchPanelState<
          SearchLivePanel,
          SearchLiveData,
          SearchLiveItemModel
        > {
  @override
  late final SearchPanelController<SearchLiveData, SearchLiveItemModel>
  controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      SearchPanelController<SearchLiveData, SearchLiveItemModel>(
        keyword: widget.keyword,
        searchType: widget.searchType,
        tag: widget.tag,
      ),
      tag: widget.searchType.name + widget.tag,
    );
  }

  late final gridDelegate = SliverGridDelegateWithExtentAndRatio(
    maxCrossAxisExtent: Grid.smallCardWidth * 1.4,
    crossAxisSpacing: 14,
    mainAxisSpacing: 14,
    childAspectRatio: Style.aspectRatio,
    mainAxisExtent: MediaQuery.textScalerOf(context).scale(
      96,
    ),
  );

  @override
  Widget buildList(List<SearchLiveItemModel> list, double contentWidth) {
    return SliverGrid.builder(
      gridDelegate: gridDelegate,
      itemBuilder: (context, index) {
        if (index == list.length - 1) {
          controller.onLoadMore();
        }
        return LiveItem(liveItem: list[index]);
      },
      itemCount: list.length,
    );
  }

  @override
  Widget buildLoading(double contentWidth) => SliverGrid(
    gridDelegate: gridDelegate,
    delegate: const SliverSingleChildDelegate(
      count: 10,
      child: VideoCardVSkeleton(),
    ),
  );
}
