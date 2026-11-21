import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/common/widgets/loading_widget/loading_widget.dart';
import 'package:bplus_tv/models/common/member/contribute_type.dart';
import 'package:bplus_tv/models_new/space/space/tab2.dart';
import 'package:bplus_tv/pages/member_article/view.dart';
import 'package:bplus_tv/pages/member_audio/view.dart';
import 'package:bplus_tv/pages/member_comic/view.dart';
import 'package:bplus_tv/pages/member_contribute/controller.dart';
import 'package:bplus_tv/pages/member_opus/view.dart';
import 'package:bplus_tv/pages/member_season_series/view.dart';
import 'package:bplus_tv/pages/member_video/view.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/utils/extension/get_ext.dart';
import 'package:bplus_tv/utils/feed_back.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class MemberContribute extends StatefulWidget {
  const MemberContribute({
    super.key,
    this.heroTag,
    this.initialIndex,
    required this.mid,
  });

  final String? heroTag;
  final int? initialIndex;
  final int mid;

  @override
  State<MemberContribute> createState() => _MemberContributeState();
}

class _MemberContributeState extends State<MemberContribute>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final MemberContributeCtr _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.putOrFind(
      () => MemberContributeCtr(
        heroTag: widget.heroTag,
        initialIndex: widget.initialIndex,
      ),
      tag: widget.heroTag,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    if (_controller.tabs != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTvTabBar(theme),
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              controller: _controller.tabController,
              children: _controller.items!.asMap().entries.map((entry) {
                final index = entry.key;
                return AnimatedBuilder(
                  animation: _controller.tabController!,
                  child: _getPageFromType(entry.value),
                  builder: (context, child) => ExcludeFocus(
                    excluding: _controller.tabController!.index != index,
                    child: child!,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    }
    return _controller.items?.isNotEmpty == true
        ? _getPageFromType(_controller.items!.first)
        : scrollableError;
  }

  Widget _buildTvTabBar(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: netflixSurface(
        radius: 16,
        child: AnimatedBuilder(
          animation: _controller.tabController!,
          builder: (context, _) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _controller.tabs!.map((tab) {
                final index = _controller.tabs!.indexOf(tab);
                final selected = _controller.tabController!.index == index;
                return TvFocusable(
                  onTap: () {
                    feedBack();
                    if (!_controller.tabController!.indexIsChanging) {
                      _controller.tabController!.animateTo(index);
                    }
                  },
                  builder: (context, focused, hovered) => TvFocusHighlight(
                    focused: focused,
                    radius: 16,
                    borderWidth: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      child: Text(
                        tab.text ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: selected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _getPageFromType(SpaceTab2Item item) {
    final isSingle = _controller.tabs == null;
    return switch (item.param) {
      'video' => MemberVideo(
        type: ContributeType.video,
        heroTag: widget.heroTag,
        mid: widget.mid,
        title: item.title,
        isSingle: isSingle,
      ),
      'charging_video' => MemberVideo(
        type: ContributeType.charging,
        heroTag: widget.heroTag,
        mid: widget.mid,
        title: item.title,
      ),
      'article' => MemberArticle(
        heroTag: widget.heroTag,
        mid: widget.mid,
      ),
      'opus' => MemberOpus(
        heroTag: widget.heroTag,
        mid: widget.mid,
        isSingle: isSingle,
      ),
      'audio' => MemberAudio(
        heroTag: widget.heroTag,
        mid: widget.mid,
      ),
      'comic' => MemberComic(
        heroTag: widget.heroTag,
        mid: widget.mid,
      ),
      'season_video' => MemberVideo(
        type: ContributeType.season,
        heroTag: widget.heroTag,
        mid: widget.mid,
        seasonId: item.seasonId,
        title: item.title,
      ),
      'series' => MemberVideo(
        type: ContributeType.series,
        heroTag: widget.heroTag,
        mid: widget.mid,
        seriesId: item.seriesId,
        title: item.title,
      ),
      'ugcSeason' => SeasonSeriesPage(
        mid: widget.mid,
        heroTag: widget.heroTag,
      ),
      _ => Center(child: Text(item.title!)),
    };
  }
}
