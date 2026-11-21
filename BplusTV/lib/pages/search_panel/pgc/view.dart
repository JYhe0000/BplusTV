import 'package:bplus_tv/common/skeleton/media_bangumi.dart';
import 'package:bplus_tv/models/search/result.dart';
import 'package:bplus_tv/pages/search_panel/controller.dart';
import 'package:bplus_tv/pages/search_panel/pgc/widgets/item.dart';
import 'package:bplus_tv/pages/search_panel/view.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class SearchPgcPanel extends CommonSearchPanel {
  const SearchPgcPanel({
    super.key,
    required super.keyword,
    required super.tag,
    required super.searchType,
  });

  @override
  State<SearchPgcPanel> createState() => _SearchPgcPanelState();
}

class _SearchPgcPanelState
    extends
        CommonSearchPanelState<
          SearchPgcPanel,
          SearchPgcData,
          SearchPgcItemModel
        > {
  @override
  late final SearchPanelController<SearchPgcData, SearchPgcItemModel>
  controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      SearchPanelController<SearchPgcData, SearchPgcItemModel>(
        keyword: widget.keyword,
        searchType: widget.searchType,
        tag: widget.tag,
      ),
      tag: widget.searchType.name + widget.tag,
    );
  }

  @override
  Widget buildList(List<SearchPgcItemModel> list, double contentWidth) {
    return buildResultGrid(
      contentWidth: contentWidth,
      minItemWidth: 340,
      itemHeight: 180,
      itemBuilder: (_, index, _) {
        if (index == list.length - 1) {
          controller.onLoadMore();
        }
        return SearchPgcItem(item: list[index]);
      },
      itemCount: list.length,
    );
  }

  @override
  Widget buildLoading(double contentWidth) => buildResultGrid(
    contentWidth: contentWidth,
    minItemWidth: 340,
    itemHeight: 180,
    itemCount: 8,
    itemBuilder: (_, _, _) => const MediaPgcSkeleton(),
  );
}
