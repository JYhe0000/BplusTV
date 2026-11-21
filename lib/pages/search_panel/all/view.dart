import 'package:bplus_tv/models/search/result.dart';
import 'package:bplus_tv/models/search/search_esports.dart';
import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/pages/search_panel/all/controller.dart';
import 'package:bplus_tv/pages/search_panel/all/widgets/activity.dart';
import 'package:bplus_tv/pages/search_panel/all/widgets/esports.dart';
import 'package:bplus_tv/pages/search_panel/all/widgets/user.dart';
import 'package:bplus_tv/pages/search_panel/pgc/widgets/item.dart';
import 'package:bplus_tv/pages/search_panel/video/view.dart';
import 'package:bplus_tv/pages/search_panel/view.dart';
import 'package:bplus_tv/utils/grid.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart'
    hide SliverGridDelegateWithMaxCrossAxisExtent;

class SearchAllPanel extends SearchVideoPanel {
  const SearchAllPanel({
    super.key,
    required super.keyword,
    required super.tag,
    required super.searchType,
  });

  @override
  State<SearchAllPanel> createState() => _SearchAllPanelState();
}

class _SearchAllPanelState
    extends
        CommonSearchPanelState<
          SearchAllPanel,
          SearchVideoData,
          SearchVideoItemModel
        >
    with GridMixin, SearchVideoPanelMixin<SearchAllPanel> {
  @override
  late final SearchAllController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      SearchAllController(
        keyword: widget.keyword,
        searchType: widget.searchType,
        tag: widget.tag,
      ),
      tag: widget.searchType.name + widget.tag,
    );
  }

  @override
  Widget buildList(List<SearchVideoItemModel> list, double contentWidth) {
    return SliverMainAxisGroup(
      slivers: [
        if (controller.searchEsports != null) ...[
          _buildEsports(controller.searchEsports!),
          SliverToBoxAdapter(
            child: Divider(
              height: 14,
              color: colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
        ],
        ...?controller.searchActivity?.map((e) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: NetflixSegment(
                radius: 16,
                child: SearchActivityItem(item: e),
              ),
            ),
          );
        }),
        ...?controller.searchUser?.map((e) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: NetflixSegment(
                radius: 16,
                child: SearchAllUserItem(item: e),
              ),
            ),
          );
        }),
        if (controller.searchMedia != null) ...[
          _buildPgc(controller.searchMedia!),
          SliverToBoxAdapter(
            child: Divider(
              height: 14,
              color: colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
        ],
        super.buildList(list, contentWidth),
      ],
    );
  }

  static Widget _buildEsports(SearchEsports item) {
    return SliverToBoxAdapter(
      child: NetflixSegment(radius: 16, child: SearchEsportsItem(item: item)),
    );
  }

  static Widget _buildPgc(List<SearchPgcItemModel> list) {
    return SliverToBoxAdapter(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth.clamp(0.0, 460.0);
          final extraTextHeight =
              (MediaQuery.textScalerOf(context).scale(17) - 17).clamp(
                0.0,
                double.infinity,
              ) *
              4;
          return SizedBox(
            height: 220 + extraTextHeight,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: list.length,
              scrollDirection: Axis.horizontal,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (context, index) => SizedBox(
                width: itemWidth,
                child: SearchPgcItem(item: list[index]),
              ),
            ),
          );
        },
      ),
    );
  }
}
