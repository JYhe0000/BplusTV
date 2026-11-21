import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/models/common/rank_type.dart';
import 'package:bplus_tv/pages/rank/controller.dart';
import 'package:bplus_tv/pages/rank/zone/view.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class RankPage extends StatefulWidget {
  const RankPage({super.key});

  @override
  State<RankPage> createState() => _RankPageState();
}

class _RankPageState extends State<RankPage>
    with AutomaticKeepAliveClientMixin {
  final RankController _rankController = Get.put(RankController());

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final homeTopInset = TvScrollInset.maybeOf(context);
    return Row(
      children: [
        _buildTab(context, homeTopInset),
        Expanded(
          child: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _rankController.tabController,
            children: RankType.values
                .map(
                  (item) => ZonePage(
                    rid: item.rid,
                    seasonType: item.seasonType,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(BuildContext context, double? homeTopInset) {
    final colorScheme = ColorScheme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        8,
        homeTopInset ?? 66,
        6,
        8 + MediaQuery.paddingOf(context).bottom,
      ),
      child: netflixSurface(
        radius: 16,
        child: SizedBox(
          width: 96,
          child: AnimatedBuilder(
            animation: _rankController.tabController,
            builder: (context, _) {
              final index = _rankController.tabController.index;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: RankType.values.length,
                itemBuilder: (context, i) {
                  final selected = i == index;
                  return TvFocusable(
                    autofocus: selected,
                    onTap: () {
                      if (selected) {
                        _rankController.animateToTop();
                      } else {
                        _rankController
                          ..tabIndex.value = i
                          ..tabController.animateTo(i);
                      }
                    },
                    builder: (context, focused, hovered) => TvFocusHighlight(
                      focused: focused,
                      radius: 12,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          RankType.values[i].label,
                          style: TextStyle(
                            fontSize: 16,
                            color: selected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
