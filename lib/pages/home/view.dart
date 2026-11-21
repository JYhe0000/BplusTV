// 桌面端右键菜单说明（P2 指针交互）：
// 首页推荐卡片由公共组件 lib/common/widgets/video_card/video_card_h.dart /
// video_card_v.dart 等构建，本文件只负责顶部 Tab 与分段控件，按改动范围
// 约束不能修改那些公共组件文件，因此 onSecondaryTap 右键菜单未在首页接线。
// TvFocusable / TvCard / TvFocusCard 已新增 onSecondaryTap 回调，后续在
// video_card 组件中接入 showMenu（复制链接 / 刷新 / 打开新窗口）即可。
import 'package:bplus_tv/common/widgets/netflix_style.dart';
import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/common/widgets/scroll_physics.dart' show tabBarView;
import 'package:bplus_tv/common/widgets/smartisan/smartisan_style.dart';
import 'package:bplus_tv/pages/common/common_page.dart';
import 'package:bplus_tv/pages/home/controller.dart';
import 'package:bplus_tv/smartisan/smartisan_palette.dart';
import 'package:bplus_tv/smartisan/smartisan_widgets.dart' show SInsetShadow;
import 'package:bplus_tv/tv/tv_constants.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/utils/extension/get_ext.dart';
import 'package:bplus_tv/utils/feed_back.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends CommonPageState<HomePage>
    with AutomaticKeepAliveClientMixin {
  final _homeController = Get.putOrFind(HomeController.new);

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final smartisan = SmartisanStyle.of(context);
    final feed = onBuild(
      tabBarView(
        controller: _homeController.tabController,
        children: _homeController.tabs.map((tab) => tab.page).toList(),
      ),
    );
    final topBar = _buildTopBar(smartisan);
    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: SizedBox(
          width: constraints.maxWidth.clamp(0.0, 1760.0).toDouble(),
          height: constraints.maxHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: TvScrollInset(
                  top: TvConstants.homeTopBarHeight,
                  child: feed,
                ),
              ),
              Positioned(top: 0, left: 0, right: 0, child: topBar),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool smartisan) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalInset = (constraints.maxWidth * 0.025)
            .clamp(12.0, 28.0)
            .toDouble();
        final availableWidth = (constraints.maxWidth - horizontalInset * 2)
            .clamp(0.0, double.infinity)
            .toDouble();
        final barWidth = availableWidth.clamp(0.0, 720.0).toDouble();
        final tabs = smartisan ? _segmented() : _defaultTabs();

        return Padding(
          padding: EdgeInsets.fromLTRB(horizontalInset, 6, horizontalInset, 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(width: barWidth, child: tabs),
          ),
        );
      },
    );
  }

  Widget _defaultTabs() => NetflixSegment(
    radius: NetflixStyle.navRadius,
    color: const Color(0xFF181818),
    child: SizedBox(
      height: 48,
      child: AnimatedBuilder(
        animation: _homeController.tabController,
        builder: (context, _) => Row(
          children: [
            for (var i = 0; i < _homeController.tabs.length; i++) _buildTab(i),
          ],
        ),
      ),
    ),
  );

  Widget _buildTab(int index) {
    return Expanded(
      child: TvFocusable(
        onTap: () => _onTabTap(index),
        builder: (context, focused, hovered) => TvFocusHighlight(
          focused: focused,
          radius: NetflixStyle.navRadius,
          borderWidth: 2,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 48,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(NetflixStyle.navRadius),
              color: _homeController.tabController.index == index
                  ? const Color(0xFF383838)
                  : Colors.transparent,
              border: _homeController.tabController.index == index
                  ? Border.all(
                      color: const Color(0xFF555555),
                    )
                  : null,
            ),
            child: Text(
              _homeController.tabs[index].label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 16,
                fontWeight: _homeController.tabController.index == index
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: _homeController.tabController.index == index
                    ? Colors.white
                    : const Color(0xFFB3B3B3),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTabTap(int index) {
    feedBack();
    if (!_homeController.tabController.indexIsChanging) {
      if (_homeController.tabController.index == index) {
        _homeController.animateToTop();
      } else {
        // The destination creates its controller when TabBarView builds
        // it. Only reselecting the current tab should scroll to the top.
        _homeController.tabController.animateTo(index);
      }
    }
  }

  /// R2 分段 Tab：浅色渐变框 + 0.8 描边，选中段内凹灰色、白字。
  Widget _segmented() {
    final p = SPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: p.tabFrame,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: p.tabFrameBorder, width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: _homeController.tabController,
        builder: (context, _) => Row(
          children: [
            for (var i = 0; i < _homeController.tabs.length; i++)
              _buildSegment(i, p, i == _homeController.tabs.length - 1),
          ],
        ),
      ),
    );
  }

  Widget _buildSegment(int index, SPalette p, bool last) {
    final tab = _homeController.tabs[index];
    final selected = _homeController.tabController.index == index;
    final label = Text(
      tab.label,
      maxLines: 1,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: selected ? Colors.white : p.tabText,
      ),
    );
    final Widget segment;
    if (selected) {
      segment = SInsetShadow(
        borderRadius: BorderRadius.circular(2),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: p.isDark ? 0.35 : 0.16),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: p.tabSelected,
            borderRadius: BorderRadius.circular(2),
          ),
          child: label,
        ),
      );
    } else {
      segment = Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(right: BorderSide(color: p.tabFrameBorder, width: 0.8)),
        ),
        child: label,
      );
    }
    return Expanded(
      child: TvFocusable(
        onTap: () => _onTabTap(index),
        builder: (context, focused, hovered) => TvFocusHighlight(
          focused: focused,
          radius: 6,
          child: segment,
        ),
      ),
    );
  }
}
