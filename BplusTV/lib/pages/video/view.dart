import 'dart:io' show Platform;
import 'dart:math';
import 'dart:ui' show ImageFilter;

import 'package:bplus_tv/common/assets.dart';
import 'package:bplus_tv/common/style.dart';
import 'package:bplus_tv/common/widgets/custom_icon.dart';
import 'package:bplus_tv/common/widgets/flutter/pop_scope.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/common/widgets/keep_alive_wrapper.dart';
import 'package:bplus_tv/common/widgets/route_aware_mixin.dart';
import 'package:bplus_tv/common/widgets/scroll_physics.dart'
    show platformAlwaysClampingPhysics;
import 'package:bplus_tv/tv/tv_constants.dart';
import 'package:bplus_tv/models/common/episode_panel_type.dart';
import 'package:bplus_tv/models_new/pgc/pgc_info_model/result.dart';
import 'package:bplus_tv/models_new/video/video_detail/episode.dart' as ugc;
import 'package:bplus_tv/models_new/video/video_detail/page.dart';
import 'package:bplus_tv/models_new/video/video_detail/section.dart';
import 'package:bplus_tv/models_new/video/video_detail/ugc_season.dart';
import 'package:bplus_tv/models_new/video/video_tag/data.dart';
import 'package:bplus_tv/pages/common/common_intro_controller.dart';
import 'package:bplus_tv/pages/danmaku/view.dart';
import 'package:bplus_tv/pages/video/ai_conclusion/view.dart';
import 'package:bplus_tv/pages/video/controller.dart';
import 'package:bplus_tv/pages/video/introduction/local/controller.dart';
import 'package:bplus_tv/pages/video/introduction/local/view.dart';
import 'package:bplus_tv/pages/video/introduction/pgc/controller.dart';
import 'package:bplus_tv/pages/video/introduction/pgc/view.dart';
import 'package:bplus_tv/pages/video/introduction/pgc/widgets/intro_detail.dart';
import 'package:bplus_tv/pages/video/introduction/ugc/controller.dart';
import 'package:bplus_tv/pages/video/introduction/ugc/view.dart';
import 'package:bplus_tv/pages/video/introduction/ugc/widgets/page.dart';
import 'package:bplus_tv/pages/video/introduction/ugc/widgets/season.dart';
import 'package:bplus_tv/pages/video/member/controller.dart';
import 'package:bplus_tv/pages/video/member/view.dart';
import 'package:bplus_tv/pages/video/related/view.dart';
import 'package:bplus_tv/pages/video/reply/controller.dart';
import 'package:bplus_tv/pages/video/reply/view.dart';
import 'package:bplus_tv/pages/video/view_point/view.dart';
import 'package:bplus_tv/pages/video/widgets/intro_layout.dart';
import 'package:bplus_tv/pages/video/widgets/player_focus.dart';
import 'package:bplus_tv/plugin/pl_player/controller.dart';
import 'package:bplus_tv/plugin/pl_player/models/play_repeat.dart';
import 'package:bplus_tv/plugin/pl_player/models/play_status.dart';
import 'package:bplus_tv/plugin/pl_player/utils/fullscreen.dart';
import 'package:bplus_tv/plugin/pl_player/view/view.dart';
import 'package:bplus_tv/services/service_locator.dart';
import 'package:bplus_tv/services/shutdown_timer_service.dart'
    show shutdownTimerService;
import 'package:bplus_tv/tv/player/tv_bottom_control.dart';
import 'package:bplus_tv/tv/player/tv_header_control.dart';
import 'package:bplus_tv/tv/tv_back_bar.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/video/tv_episode_panel.dart';
import 'package:bplus_tv/tv/video/tv_episode_strip.dart';
import 'package:bplus_tv/utils/android/bindings.g.dart';
import 'package:bplus_tv/utils/extension/scroll_controller_ext.dart';
import 'package:bplus_tv/utils/max_screen_size.dart';
import 'package:bplus_tv/utils/mobile_observer.dart';
import 'package:bplus_tv/utils/num_utils.dart';
import 'package:bplus_tv/utils/page_utils.dart';
import 'package:bplus_tv/utils/storage.dart';
import 'package:bplus_tv/utils/storage_key.dart';
import 'package:bplus_tv/utils/theme_utils.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart' hide PopScope;
import 'package:screen_brightness_platform_interface/screen_brightness_platform_interface.dart';

const double _kScreenRatio = 1.2;

class VideoDetailPageV extends StatefulWidget {
  const VideoDetailPageV({super.key});

  @override
  State<VideoDetailPageV> createState() => _VideoDetailPageVState();
}

class _VideoDetailPageVState extends State<VideoDetailPageV>
    with RouteAware, RouteAwareMixin, WidgetsBindingObserver {
  final heroTag = Get.arguments['heroTag'];

  late final VideoDetailController videoDetailController;
  late final VideoReplyController _videoReplyController;
  PlPlayerController? plPlayerController;

  // intro ctr
  late final CommonIntroController introController =
      videoDetailController.isFileSource
      ? localIntroController
      : videoDetailController.isUgc
      ? ugcIntroController
      : pgcIntroController;
  late final UgcIntroController ugcIntroController;
  late final PgcIntroController pgcIntroController;
  late final LocalIntroController localIntroController;

  bool get autoPlayEnable =>
      videoDetailController.plPlayerController.autoPlayEnable;

  bool get enableVerticalExpand =>
      videoDetailController.plPlayerController.enableVerticalExpand;

  bool get pipNoDanmaku =>
      videoDetailController.plPlayerController.pipNoDanmaku;

  bool isShowing = true;

  /// Whether the TV bottom episode strip is open.
  bool _tvShowEpisodes = false;

  void _closeTvEpisodes() {
    if (_tvShowEpisodes) {
      setState(() => _tvShowEpisodes = false);
    }
  }

  void _openTvEpisodes() {
    if (!_tvHasEpisodes) {
      SmartDialog.showToast('暂无选集');
      return;
    }
    if (!_tvShowEpisodes) {
      setState(() => _tvShowEpisodes = true);
    }
  }

  bool get isFullScreen =>
      videoDetailController.plPlayerController.isFullScreen.value;

  bool get _shouldShowSeasonPanel {
    if (videoDetailController.isFileSource ||
        isPortrait ||
        !videoDetailController.isUgc) {
      return false;
    }
    late final videoDetail = ugcIntroController.videoDetail.value;
    return videoDetailController.plPlayerController.horizontalSeasonPanel &&
        (videoDetail.ugcSeason != null ||
            ((videoDetail.pages?.length ?? 0) > 1));
  }

  /// Whether the TV player's "选集" strip has anything to show. Mirrors the
  /// detail page's episode source (parts + season sections / PGC episodes)
  /// instead of the mobile [_shouldShowSeasonPanel] pref gate.
  bool get _tvHasEpisodes {
    if (videoDetailController.isFileSource) {
      return false;
    }
    if (videoDetailController.isUgc) {
      final detail = ugcIntroController.videoDetail.value;
      final hasSections = (detail.ugcSeason?.sections ?? const <SectionItem>[])
          .any(
            (e) => e.episodes?.isNotEmpty == true,
          );
      return hasSections || (detail.pages?.length ?? 0) > 1;
    }
    final episodes = pgcIntroController.pgcItem.episodes;
    return episodes != null && episodes.isNotEmpty;
  }

  final videoReplyPanelKey = GlobalKey();
  final videoRelatedKey = GlobalKey();
  final videoIntroKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    PlPlayerController.setPlayCallBack(playCallBack);
    videoDetailController = Get.put(VideoDetailController(), tag: heroTag);

    // TV 播放页全程沉浸式：海报态同样隐藏状态栏。
    hideSystemBar();

    if (videoDetailController.showReply) {
      _videoReplyController = Get.put(
        VideoReplyController(
          aid: videoDetailController.aid,
          videoType: videoDetailController.videoType,
          heroTag: heroTag,
        ),
        tag: heroTag,
      );
    }

    if (videoDetailController.isFileSource) {
      localIntroController = Get.put(LocalIntroController(), tag: heroTag);
    } else if (videoDetailController.isUgc) {
      ugcIntroController = Get.put(UgcIntroController(), tag: heroTag);
    } else {
      pgcIntroController = Get.put(PgcIntroController(), tag: heroTag);
    }

    videoSourceInit();

    addObserverMobile(this);
  }

  // 获取视频资源，初始化播放器
  void videoSourceInit() {
    videoDetailController.queryVideoUrl(autoFullScreenFlag: true);
    if (videoDetailController.autoPlay) {
      plPlayerController = videoDetailController.plPlayerController;
      plPlayerController!
        ..addStatusListener(playerListener)
        ..addPositionListener(positionListener);
    }
  }

  void positionListener(Duration position) {
    videoDetailController.playedTime = position;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isResume = state == .resumed;
    final ctr = videoDetailController.plPlayerController..visible = isResume;
    if (isResume) {
      if (!ctr.showDanmaku) {
        introController.startTimer();
        ctr.showDanmaku = true;
      }
    } else if (state == .paused) {
      introController.cancelTimer();
      ctr.showDanmaku = false;
    }
  }

  Future<void>? playCallBack() {
    if (!isShowing) {
      plPlayerController
        ?..addStatusListener(playerListener)
        ..addPositionListener(positionListener);
    }
    return plPlayerController?.play();
  }

  // 播放器状态监听
  Future<void> playerListener(PlayerStatus status) async {
    final isPlaying = status.isPlaying;
    try {
      if (videoDetailController.scrollCtr.hasClients) {
        if (isPlaying) {
          if (!videoDetailController.isExpanding &&
              videoDetailController.scrollCtr.offset != 0 &&
              !videoDetailController.animationController.isAnimating) {
            videoDetailController.isExpanding = true;
            videoDetailController.animationController.forward(
              from:
                  1 -
                  videoDetailController.scrollCtr.offset /
                      videoDetailController.videoHeight,
            );
          } else {
            videoDetailController.refreshPage();
          }
        } else {
          videoDetailController.refreshPage();
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('handle player status: $e');
    }

    if (status.isCompleted) {
      try {
        if (videoDetailController
                .steinEdgeInfo
                ?.edges
                ?.questions
                ?.firstOrNull
                ?.choices
                ?.isNotEmpty ==
            true) {
          videoDetailController.showSteinEdgeInfo.value = true;
          return;
        }
      } catch (_) {}

      bool exitFlag = true;

      /// 顺序播放 列表循环
      if (shutdownTimerService.isWaiting) {
        shutdownTimerService.handleWaiting();
      } else {
        switch (plPlayerController!.playRepeat) {
          case PlayRepeat.singleCycle:
            exitFlag = false;
            plPlayerController!.play(repeat: true);
          case PlayRepeat.listOrder:
          case PlayRepeat.listCycle:
          case PlayRepeat.autoPlayRelated:
            exitFlag = !introController.nextPlay();
          case PlayRepeat.pause:
        }
      }

      if (exitFlag) {
        if (plPlayerController!.controlsLock.value &&
            (!Platform.isAndroid || !AndroidHelper.isPipMode)) {
          plPlayerController!.onLockControl(false);
        }
      }
    }
  }

  // 继续播放或重新播放
  void continuePlay() {
    plPlayerController!.play();
  }

  /// 未开启自动播放时触发播放
  Future<void>? handlePlay() {
    if (!videoDetailController.isFileSource) {
      if (videoDetailController.isQuerying.value) {
        if (kDebugMode) debugPrint('handlePlay: querying, play when ready');
        // 查询已在进行：记录用户意图，地址就绪后由控制器自动起播。
        videoDetailController.userIntentPlay = true;
        return null;
      }
      if (videoDetailController.videoUrl == null ||
          videoDetailController.audioUrl == null) {
        if (kDebugMode) {
          debugPrint('handlePlay: videoUrl/audioUrl not initialized, querying');
        }
        videoDetailController.userIntentPlay = true;
        videoDetailController.queryVideoUrl();
        return null;
      }
    }
    final plPlayerController = this.plPlayerController =
        videoDetailController.plPlayerController;
    videoDetailController.autoPlay = true;
    plPlayerController
      ..addStatusListener(playerListener)
      ..addPositionListener(positionListener);
    if (plPlayerController.preInitPlayer) {
      return plPlayerController.play();
    } else {
      return videoDetailController.playerInit(
        autoplay: true,
        autoFullScreenFlag: true,
      );
    }
  }

  @override
  void dispose() {
    plPlayerController
      ?..removeStatusListener(playerListener)
      ..removePositionListener(positionListener);

    Get.delete<HorizontalMemberPageController>(
      tag: videoDetailController.heroTag,
    );

    if (!videoDetailController.isFileSource) {
      if (videoDetailController.isUgc) {
        ugcIntroController
          ..cancelTimer()
          ..videoDetail.close();
      } else {
        pgcIntroController.cancelTimer();
      }
    }

    // 退出播放页恢复系统栏（进入页面时已主动沉浸式）。
    showSystemBar();

    if (!videoDetailController.plPlayerController.isCloseAll) {
      videoPlayerServiceHandler?.onVideoDetailDispose(heroTag);
      if (plPlayerController != null) {
        videoDetailController.makeHeartBeat();
        plPlayerController!.dispose();
      } else {
        PlPlayerController.updatePlayCount();
      }
    }
    removeObserverMobile(this);

    super.dispose();
  }

  @override
  // 离开当前页面时
  void didPushNext() {
    super.didPushNext();
    isShowing = false;

    removeObserverMobile(this);

    if (Platform.isAndroid && !videoDetailController.setSystemBrightness) {
      ScreenBrightnessPlatform.instance.resetApplicationScreenBrightness();
    }

    introController.cancelTimer();

    videoDetailController
      ..videoState.value = false
      ..cancelBlockListener()
      ..playerStatus = plPlayerController?.playerStatus.value
      ..brightness = plPlayerController?.brightness.value;
    if (plPlayerController != null) {
      videoDetailController.makeHeartBeat();
      plPlayerController!
        ..removeStatusListener(playerListener)
        ..removePositionListener(positionListener)
        ..pause();
    }
  }

  @override
  // 返回当前页面时
  void didPopNext() {
    super.didPopNext();

    if (videoDetailController.plPlayerController.isCloseAll) {
      return;
    }

    isShowing = true;

    addObserverMobile(this);

    plPlayerController?.isLive = false;
    if (videoDetailController.plPlayerController.playerStatus.isPlaying &&
        videoDetailController.playerStatus != PlayerStatus.playing) {
      videoDetailController.plPlayerController.pause();
    }

    PlPlayerController.setPlayCallBack(playCallBack);

    introController.startTimer();

    if (mounted &&
        Platform.isAndroid &&
        !videoDetailController.setSystemBrightness) {
      if (videoDetailController.brightness != null) {
        plPlayerController?.brightness.value =
            videoDetailController.brightness!;
        if (videoDetailController.brightness != -1.0) {
          ScreenBrightnessPlatform.instance.setApplicationScreenBrightness(
            videoDetailController.brightness!,
          );
        } else {
          ScreenBrightnessPlatform.instance.resetApplicationScreenBrightness();
        }
      } else {
        ScreenBrightnessPlatform.instance.resetApplicationScreenBrightness();
      }
    }

    plPlayerController
      ?..addStatusListener(playerListener)
      ..addPositionListener(positionListener);
    if (videoDetailController.autoPlay) {
      videoDetailController.playerInit(
        autoplay: videoDetailController.playerStatus?.isPlaying ?? false,
      );
    } else if (videoDetailController.plPlayerController.preInitPlayer &&
        !videoDetailController.isQuerying.value &&
        videoDetailController.videoUrl != null) {
      videoDetailController.playerInit();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (videoDetailController.removeSafeArea) {
      padding = .zero;
    } else {
      padding = MediaQuery.viewPaddingOf(context);
    }

    final size = MediaQuery.sizeOf(context);
    maxWidth = size.width;
    maxHeight = size.height;
    isWindowMode = MaxScreenSize.isWindowMode(
      width: maxWidth * videoDetailController.uiScale,
      height: maxHeight * videoDetailController.uiScale,
    );
    videoDetailController.plPlayerController.screenRatio = maxHeight / maxWidth;

    final shortestSide = size.shortestSide;
    final minVideoHeight = shortestSide / Style.aspectRatio16x9;
    final maxVideoHeight = max(size.longestSide * 0.65, shortestSide);
    isPortrait = false;
    // TV 上始终为横屏，强制横屏模式
    videoDetailController
      ..minVideoHeight = minVideoHeight
      ..maxVideoHeight = maxVideoHeight
      ..videoHeight = videoDetailController.isVertical.value
          ? maxVideoHeight
          : minVideoHeight;

    theme = videoDetailController.plPlayerController.darkVideoPage
        ? ThemeUtils.darkTheme
        : Theme.of(context);
  }

  bool removeAppBar(bool isFullScreen) =>
      videoDetailController.removeSafeArea || (isWindowMode && isFullScreen);

  /// 海报态顶栏只保留返回键；返回主页、更多菜单与右下角播放浮标为触屏
  /// 遗留，遥控器场景无用（浮标还会被屏幕边缘截断）。
  Widget manualPlayerWidget() => Obx(() {
    if (!videoDetailController.autoPlay) {
      return const Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: kToolbarHeight,
        child: Row(children: [TvBackButton()]),
      );
    }
    return const SizedBox.shrink();
  });

  Widget plPlayer({
    required double width,
    required double height,
    bool isPipMode = false,
  }) => Obx(
    () => popScope(
      key: videoDetailController.videoPlayerKey,
      canPop:
          !(videoDetailController.plPlayerController.keyboardControl &&
              videoDetailController.plPlayerController.showControls.value) &&
          (videoDetailController.horizontalScreen || isPortrait) &&
          !_tvShowEpisodes,
      onPopInvokedWithResult: (didPop, result) {
        final ctr = videoDetailController.plPlayerController;
        // The bottom episode strip owns the back key: close it instead of
        // letting the player handler pop the route.
        if (!didPop && _tvShowEpisodes) {
          _closeTvEpisodes();
          return;
        }
        // While the on-screen control bar is up, back dismisses it instead of
        // leaving the player (TV remote or keyboard control).
        if (!didPop && ctr.keyboardControl && ctr.showControls.value) {
          ctr.controls = false;
          return;
        }
        videoDetailController.plPlayerController.onPopInvokedWithResult(
          didPop,
          result,
        );
      },
      child: Obx(
        () =>
            !videoDetailController.videoState.value ||
                !videoDetailController.autoPlay ||
                plPlayerController?.videoController == null
            ? const SizedBox.shrink()
            : PLVideoPlayer(
                maxWidth: width,
                maxHeight: height,
                plPlayerController: plPlayerController!,
                videoDetailController: videoDetailController,
                introController: introController,
                headerControl: TvHeaderControl(
                  title: Get.arguments['title']?.toString() ?? '',
                ),
                bottomControl: TvBottomControl(
                  controller: plPlayerController!,
                  introController: introController,
                  videoDetailController: videoDetailController,
                ),
                danmuWidget: isPipMode && pipNoDanmaku
                    ? null
                    : Obx(
                        () => PlDanmaku(
                          key: ValueKey(videoDetailController.cid.value),
                          isPipMode: isPipMode,
                          cid: videoDetailController.cid.value,
                          playerController: plPlayerController!,
                          isFullScreen: plPlayerController!.isFullScreen.value,
                          isFileSource: videoDetailController.isFileSource,
                          size: Size(width, height),
                        ),
                      ),
                showEpisodes: showEpisodes,
                showViewPoints: showViewPoints,
              ),
      ),
    ),
  );

  late ThemeData theme;
  ColorScheme get colorScheme => theme.colorScheme;
  bool isPortrait = false;
  late double maxWidth;
  late double maxHeight;
  bool isWindowMode = false;
  late EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    Widget child = _childWhenTv();
    if (videoDetailController.plPlayerController.keyboardControl) {
      child = PlayerFocus(
        // 初始焦点交给 TV 播放器手势处理器，避免 autofocus 竞争。
        autofocus: false,
        plPlayerController: videoDetailController.plPlayerController,
        introController: introController,
        onSendDanmaku: videoDetailController.showShootDanmakuSheet,
        onOpenPanel: _openTvEpisodes,
        onClosePanel: _closeTvEpisodes,
        canPlay: () {
          if (videoDetailController.autoPlay) {
            return true;
          }
          handlePlay();
          return false;
        },
        onSkipSegment: videoDetailController.onSkipSegment,
        panelOpen: _tvShowEpisodes,
        child: child,
      );
    }
    return videoDetailController.plPlayerController.darkVideoPage
        ? Theme(data: theme, child: child)
        : child;
  }

  /// Android TV layout: full-screen player. UP reveals the control bar, DOWN
  /// reveals the compact bottom episode strip; both are dismissed with back.
  Widget _childWhenTv() {
    return PopScope(
      canPop: !_tvShowEpisodes,
      // Only block the pop here. The strip is closed by the player's own
      // [PopScope] (see [plPlayer]); closing it here first would clear
      // [_tvShowEpisodes] before that handler runs, so it would fall through to
      // the player's default back action and pop the whole page.
      onPopInvokedWithResult: (didPop, _) {},
      child: Stack(
        children: [
          Positioned.fill(
            child: videoPlayer(width: maxWidth, height: maxHeight),
          ),
          Positioned.fill(
            child: Obx(
              () => videoDetailController.autoPlay
                  ? const SizedBox.shrink()
                  : _tvPoster(),
            ),
          ),
          // 手动播放的返回栏须位于海报上方，避免点击被全屏海报遮挡。
          manualPlayerWidget(),
          if (_tvShowEpisodes) Positioned.fill(child: _buildTvEpisodeStrip()),
        ],
      ),
    );
  }

  Widget _tvPoster() {
    // 封面、查询状态经外层 Obx 读取，变化时整层海报重建。
    final cover = videoDetailController.cover.value;
    return Stack(
      children: [
        if (cover.isNotEmpty)
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Opacity(
                opacity: 0.32,
                child: NetworkImgLayer(
                  src: cover,
                  width: maxWidth,
                  height: maxHeight,
                  clip: false,
                ),
              ),
            ),
          ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x55000000), Color(0xCC000000)],
              ),
            ),
            child: SizedBox.expand(),
          ),
        ),
        Center(
          child: TvPosterPlayButton(
            onTap: handlePlay,
            querying: videoDetailController.isQuerying.value,
          ),
        ),
        Positioned(
          left: 48,
          right: 48,
          bottom: 48,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Get.arguments['title']?.toString() ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              if (videoDetailController.isUgc)
                Obx(() {
                  final detail = ugcIntroController.videoDetail.value;
                  final pages = detail.pages?.length ?? 0;
                  return Text(
                    '${detail.owner?.name ?? ''}  ·  '
                    '${NumUtils.numFormat(detail.stat?.view ?? 0)} 播放'
                    '${pages > 1 ? '  ·  共$pages个分P' : ''}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 20,
                    ),
                  );
                })
              else
                Text(
                  _pgcPosterSubtitle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 20,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 番剧/影视海报副标题：季名 · 共N集 · 当前集名。
  String _pgcPosterSubtitle() {
    final pgcItem = pgcIntroController.pgcItem;
    final title = pgcItem.title ?? '';
    final episodes = pgcItem.episodes;
    if (episodes == null || episodes.isEmpty) {
      return title;
    }
    final item = episodes.firstWhereOrNull(
      (item) => item.epId == pgcIntroController.epId,
    );
    final current = item?.showTitle ?? item?.longTitle;
    return '$title  ·  共${episodes.length}集'
        '${current != null ? '  ·  $current' : ''}';
  }

  Widget buildTabBar({
    bool needIndicator = true,
    String? introText,
    bool showIntro = true,
    VoidCallback? onTap,
  }) {
    final tabs = [
      if (showIntro)
        videoDetailController.isFileSource ? '离线视频' : introText ?? '简介',
      if (videoDetailController.showReply) '评论',
      if (_shouldShowSeasonPanel) '播放列表',
    ];
    if (videoDetailController.tabCtr.length != tabs.length) {
      videoDetailController.tabCtr.dispose();
      videoDetailController.tabCtr = TabController(
        vsync: videoDetailController,
        length: tabs.length,
        initialIndex: tabs.isEmpty
            ? 0
            : videoDetailController.tabCtr.index.clamp(0, tabs.length - 1),
      );
    }

    Widget tabBar() {
      final flag = !needIndicator || tabs.length == 1;
      return TabBar(
        padding: .zero,
        dividerHeight: 0,
        labelPadding: .zero,
        dividerColor: Colors.transparent,
        controller: videoDetailController.tabCtr,
        indicator: flag ? const BoxDecoration() : null,
        labelColor: flag ? colorScheme.onSurface : null,
        labelStyle:
            TabBarTheme.of(context).labelStyle?.copyWith(fontSize: 13) ??
            const TextStyle(fontSize: 13),
        onTap: (value) {
          void animToTop() {
            if (onTap != null) {
              onTap();
              return;
            }
            String text = tabs[value];
            if (videoDetailController.isFileSource ||
                text == '简介' ||
                text == '相关视频') {
              videoDetailController.introScrollCtr?.animToTop();
            } else if (text.startsWith('评论')) {
              _videoReplyController.animateToTop();
            }
          }

          if (flag) {
            animToTop();
          } else if (!videoDetailController.tabCtr.indexIsChanging) {
            animToTop();
          }
        },
        tabs: tabs.map((text) {
          if (text == '评论') {
            return Obx(() {
              final count = _videoReplyController.count.value;
              return Tab(
                child: Text(
                  '评论${count == -1 ? '' : ' ${NumUtils.numFormat(count)}'}',
                  softWrap: false,
                  overflow: .visible,
                ),
              );
            });
          } else {
            return Tab(
              child: Text(text, softWrap: false, overflow: .visible),
            );
          }
        }).toList(),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SizedBox(
        height: 45,
        child: Row(
          children: [
            if (tabs.isEmpty)
              const Spacer()
            else
              Expanded(
                child: Align(
                  alignment: .centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 96.0 * tabs.length),
                    child: tabBar(),
                  ),
                ),
              ),
            SizedBox(
              height: 32,
              child: TextButton(
                style: const ButtonStyle(
                  padding: WidgetStatePropertyAll(.zero),
                ),
                onPressed: videoDetailController.showShootDanmakuSheet,
                child: Text(
                  '发弹幕',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            SizedBox.square(
              dimension: 38,
              child: Obx(
                () {
                  final ctr = videoDetailController.plPlayerController;
                  final enableShowDanmaku = ctr.enableShowDanmaku.value;
                  return IconButton(
                    onPressed: () {
                      final newVal = !enableShowDanmaku;
                      ctr.enableShowDanmaku.value = newVal;
                      if (!ctr.tempPlayerConf) {
                        GStorage.setting.put(
                          SettingBoxKey.enableShowDanmaku,
                          newVal,
                        );
                      }
                    },
                    icon: Icon(
                      size: 22,
                      enableShowDanmaku
                          ? CustomIcons.dm_on
                          : CustomIcons.dm_off,
                      color: enableShowDanmaku
                          ? colorScheme.secondary
                          : colorScheme.outline,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }

  Widget videoPlayer({required double width, required double height}) {
    final isFullScreen = this.isFullScreen;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned.fill(
          child: ColoredBox(
            color: Colors.black,
            isAntiAlias: false,
          ),
        ),

        plPlayer(width: width, height: height),

        Obx(() {
          if (!videoDetailController.autoPlay) {
            return Positioned.fill(
              child: GestureDetector(
                onTap: handlePlay,
                behavior: .opaque,
                child: Obx(
                  () => NetworkImgLayer(
                    type: .emote,
                    quality: 60,
                    src: videoDetailController.cover.value,
                    width: width,
                    height: height,
                    cacheWidth: true,
                    getPlaceHolder: () => Center(
                      child: Image.asset(Assets.loading),
                    ),
                  ),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
        if (videoDetailController.plPlayerController.enableBlock ||
            videoDetailController.continuePlayingPart)
          Positioned(
            left: 16,
            bottom: isFullScreen ? max(75, maxHeight * 0.25) : 75,
            width: MediaQuery.textScalerOf(context).scale(120),
            child: AnimatedList(
              padding: EdgeInsets.zero,
              key: videoDetailController.listKey,
              reverse: true,
              shrinkWrap: true,
              initialItemCount: videoDetailController.listData.length,
              itemBuilder: (context, index, animation) {
                return videoDetailController.buildItem(
                  videoDetailController.listData[index],
                  animation,
                );
              },
            ),
          ),

        // for debug
        // Positioned(
        //   right: 16,
        //   bottom: 75,
        //   child: FilledButton.tonal(
        //     onPressed: () {
        //       videoDetailController.onAddItem(
        //         SegmentModel(
        //           UUID: '',
        //           segmentType:
        //               SegmentType.values[Utils.random.nextInt(
        //                 SegmentType.values.length,
        //               )],
        //           segment: Pair(first: 0, second: 0),
        //           skipType: SkipType.alwaysSkip,
        //         ),
        //       );
        //     },
        //     child: const Text('skip'),
        //   ),
        // ),
        // Positioned(
        //   right: 16,
        //   bottom: 120,
        //   child: FilledButton.tonal(
        //     onPressed: () {
        //       videoDetailController.onAddItem(2);
        //     },
        //     child: const Text('index'),
        //   ),
        // ),
        Obx(
          () {
            if (videoDetailController.showSteinEdgeInfo.value) {
              try {
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: plPlayerController?.showControls.value == true
                          ? 75
                          : 16,
                    ),
                    child: Wrap(
                      spacing: 25,
                      runSpacing: 10,
                      children: videoDetailController
                          .steinEdgeInfo!
                          .edges!
                          .questions!
                          .first
                          .choices!
                          .map((item) {
                            return FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                shape: const RoundedRectangleBorder(
                                  borderRadius: .all(.circular(6)),
                                ),
                                backgroundColor: theme
                                    .colorScheme
                                    .secondaryContainer
                                    .withValues(alpha: 0.8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 10,
                                ),
                                visualDensity: VisualDensity.compact,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                ugcIntroController.onChangeEpisode(
                                  item,
                                  isStein: true,
                                );
                                videoDetailController.getSteinEdgeInfo(item.id);
                              },
                              child: Text(item.option!),
                            );
                          })
                          .toList(),
                    ),
                  ),
                );
              } catch (e) {
                if (kDebugMode) debugPrint('build stein edges: $e');
                return const SizedBox.shrink();
              }
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget localIntroPanel({
    bool needCtr = true,
  }) {
    return CustomScrollView(
      controller: needCtr
          ? videoDetailController.effectiveIntroScrollCtr
          : null,
      physics: !needCtr ? platformAlwaysClampingPhysics : null,
      key: const PageStorageKey(CommonIntroController),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(top: 7, bottom: padding.bottom + 100),
          sliver: LocalIntroPanel(
            key: videoRelatedKey,
            heroTag: heroTag,
          ),
        ),
      ],
    );
  }

  Widget videoIntro({
    double? width,
    double? height,
    bool? isHorizontal,
    bool needRelated = true,
    bool needCtr = true,
  }) {
    if (videoDetailController.isFileSource) {
      return localIntroPanel(needCtr: needCtr);
    }

    Widget child = CustomScrollView(
      key: const PageStorageKey(CommonIntroController),
      controller: needCtr
          ? videoDetailController.effectiveIntroScrollCtr
          : null,
      physics: !needCtr ? platformAlwaysClampingPhysics : null,
      slivers: [
        if (videoDetailController.isUgc) ...[
          UgcIntroPanel(
            key: videoIntroKey,
            heroTag: heroTag,
            showAiBottomSheet: showAiBottomSheet,
            showEpisodes: showEpisodes,
            onShowMemberPage: onShowMemberPage,
            isPortrait: false,
            isHorizontal: isHorizontal ?? width! / height! >= _kScreenRatio,
          ),
          if (needRelated && videoDetailController.showRelatedVideo) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: Style.safeSpace,
                ),
                child: Divider(
                  height: 1,
                  indent: 12,
                  endIndent: 12,
                  color: colorScheme.outline.withValues(alpha: .08),
                ),
              ),
            ),
            RelatedVideoPanel(key: videoRelatedKey, heroTag: heroTag),
          ],
        ] else
          PgcIntroPage(
            key: videoIntroKey,
            heroTag: heroTag,
            cid: videoDetailController.cid.value,
            showEpisodes: showEpisodes,
            showIntroDetail: showIntroDetail,
            maxWidth: width ?? maxWidth,
            isLandscape: true,
          ),
        SliverToBoxAdapter(
          child: SizedBox(
            height:
                (videoDetailController.isPlayAll ? 80 : Style.safeSpace) +
                padding.bottom,
          ),
        ),
      ],
    );

    if (videoDetailController.isPlayAll) {
      child = IntroLayout(
        body: child,
        playlist: Padding(
          padding: .only(left: 12, right: 12, bottom: 12 + padding.bottom),
          child: Material(
            type: .transparency,
            child: InkWell(
              onTap: () => videoDetailController.showMediaListPanel(context),
              borderRadius: const .all(.circular(14)),
              child: Container(
                height: 54,
                padding: const .symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.95),
                  borderRadius: const .all(.circular(14)),
                ),
                child: Row(
                  spacing: 10,
                  children: [
                    const Icon(Icons.playlist_play, size: 24),
                    Expanded(
                      child: Text(
                        videoDetailController.watchLaterTitle,
                        style: TextStyle(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: .bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_up_rounded, size: 26),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return KeepAliveWrapper(child: child);
  }

  Widget get seasonPanel {
    final videoDetail = ugcIntroController.videoDetail.value;
    return KeepAliveWrapper(
      child: Column(
        children: [
          if ((videoDetail.pages?.length ?? 0) > 1)
            if (videoDetail.ugcSeason != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: PagesPanel(
                  heroTag: heroTag,
                  ugcIntroController: ugcIntroController,
                  bvid: ugcIntroController.bvid,
                  showEpisodes: showEpisodes,
                ),
              )
            else
              Expanded(
                child: Obx(
                  () => TvEpisodePanel(
                    heroTag: heroTag,
                    ugcIntroController: videoDetailController.isUgc
                        ? ugcIntroController
                        : null,
                    type: EpisodeType.part,
                    list: [videoDetail.pages!],
                    cover: videoDetailController.cover.value,
                    bvid: videoDetailController.bvid,
                    aid: videoDetailController.aid,
                    cid: videoDetailController.cid.value,
                    isReversed: videoDetail.isPageReversed,
                    onChangeEpisode: videoDetailController.isUgc
                        ? ugcIntroController.onChangeEpisode
                        : pgcIntroController.onChangeEpisode,
                    isSupportReverse: videoDetailController.isUgc,
                    onReverse: () => onReversePlay(isSeason: false),
                    onClose: _closeTvEpisodes,
                  ),
                ),
              ),
          if (videoDetail.ugcSeason != null) ...[
            if ((videoDetail.pages?.length ?? 0) > 1) ...[
              const SizedBox(height: 8),
              Divider(
                height: 1,
                color: colorScheme.outline.withValues(alpha: 0.1),
              ),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Obx(
                () => SeasonPanel(
                  key: ValueKey(introController.videoDetail.value),
                  heroTag: heroTag,
                  canTap: false,
                  showEpisodes: showEpisodes,
                  ugcIntroController: ugcIntroController,
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                final detail = ugcIntroController.videoDetail.value;
                final sections = detail.ugcSeason?.sections;
                if (sections == null || sections.isEmpty) {
                  return const SizedBox.shrink();
                }
                final seasonIndex = videoDetailController.seasonIndex.value
                    .clamp(0, sections.length - 1);
                final isReversed = sections[seasonIndex].isReversed;
                return TvEpisodePanel(
                  heroTag: heroTag,
                  ugcIntroController: videoDetailController.isUgc
                      ? ugcIntroController
                      : null,
                  type: EpisodeType.season,
                  initialTabIndex: videoDetailController.seasonIndex.value,
                  cover: videoDetailController.cover.value,
                  seasonId: detail.ugcSeason!.id,
                  list: sections,
                  bvid: videoDetailController.bvid,
                  aid: videoDetailController.aid,
                  cid: videoDetailController.seasonCid ?? 0,
                  isReversed: isReversed,
                  onChangeEpisode: videoDetailController.isUgc
                      ? ugcIntroController.onChangeEpisode
                      : pgcIntroController.onChangeEpisode,
                  isSupportReverse: videoDetailController.isUgc,
                  onReverse: () => onReversePlay(isSeason: true),
                  onClose: _closeTvEpisodes,
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget videoReplyPanel({bool isNested = false}) => VideoReplyPanel(
    key: videoReplyPanelKey,
    isNested: isNested,
    heroTag: heroTag,
  );

  // ai总结
  void showAiBottomSheet() {
    videoDetailController.childKey.currentState?.showBottomSheet(
      constraints: const BoxConstraints(),
      (context) =>
          AiConclusionPanel(item: ugcIntroController.aiConclusionResult!),
    );
  }

  void showIntroDetail(
    PgcInfoModel videoDetail,
    List<VideoTagItem>? videoTags,
  ) {
    videoDetailController.childKey.currentState?.showBottomSheet(
      constraints: const BoxConstraints(),
      (context) => PgcIntroPanel(
        item: videoDetail,
        videoTags: videoTags,
      ),
    );
  }

  /// TV-native "选集" body: a compact bottom strip with thumbnail previews.
  /// For UGC it shows the video's own parts plus the section it currently
  /// belongs to (not the whole big collection).
  Widget _buildTvEpisodeStrip() {
    if (videoDetailController.isFileSource) {
      return const SizedBox.shrink();
    }
    final cid = videoDetailController.cid.value;
    if (!videoDetailController.isUgc) {
      final episodes = pgcIntroController.pgcItem.episodes ?? const [];
      if (episodes.isEmpty) return const SizedBox.shrink();
      return TvEpisodeStrip(
        heroTag: heroTag,
        groups: [
          TvEpisodeGroup(
            title: '选集',
            episodes: episodes.cast<ugc.BaseEpisodeItem>(),
          ),
        ],
        cover: videoDetailController.cover.value,
        cid: cid,
        onChangeEpisode: pgcIntroController.onChangeEpisode,
        onClose: _closeTvEpisodes,
      );
    }
    return Obx(() {
      final videoDetail = ugcIntroController.videoDetail.value;
      final pages = videoDetail.pages ?? const <Part>[];
      final groups = <TvEpisodeGroup>[];
      if (pages.length > 1) {
        groups.add(TvEpisodeGroup(title: '分P', episodes: pages));
      }
      final sections = videoDetail.ugcSeason?.sections ?? const <SectionItem>[];
      if (sections.isNotEmpty) {
        final index = videoDetailController.seasonIndex.value.clamp(
          0,
          sections.length - 1,
        );
        final section = sections[index];
        if (section.episodes?.isNotEmpty == true) {
          groups.add(
            TvEpisodeGroup(
              title: section.title ?? '选集',
              episodes: section.episodes!.cast<ugc.BaseEpisodeItem>(),
              isSeason: true,
            ),
          );
        }
      }
      if (groups.isEmpty) return const SizedBox.shrink();
      var initialTab = 0;
      for (var i = 0; i < groups.length; i++) {
        if (groups[i].episodes.any((e) => e.cid == cid)) {
          initialTab = i;
          break;
        }
      }
      return TvEpisodeStrip(
        heroTag: heroTag,
        groups: groups,
        title: groups.length == 1 ? groups.first.title : '选集',
        cover: videoDetailController.cover.value,
        cid: cid,
        initialTabIndex: initialTab,
        ugcIntroController: ugcIntroController,
        onChangeEpisode: ugcIntroController.onChangeEpisode,
        onClose: _closeTvEpisodes,
      );
    });
  }

  void showEpisodes([
    int? index,
    UgcSeason? season,
    List<ugc.BaseEpisodeItem>? episodes,
    String? bvid,
    int? aid,
    int? cid,
  ]) {
    assert((cid == null) == (bvid == null));
    if (cid == null) {
      videoDetailController.showMediaListPanel(context);
      return;
    }
    _openTvEpisodes();
  }

  void onReversePlay({required bool isSeason}) {
    if (isSeason && videoDetailController.isPlayAll) {
      SmartDialog.showToast('当前为播放全部，合集不支持倒序');
      return;
    }

    final videoDetail = ugcIntroController.videoDetail.value;
    if (isSeason) {
      // reverse season
      final sections = videoDetail.ugcSeason?.sections;
      if (sections == null || sections.isEmpty) {
        return;
      }
      final seasonIndex = videoDetailController.seasonIndex.value.clamp(
        0,
        sections.length - 1,
      );
      final item = sections[seasonIndex];
      final episodes = item.episodes;
      if (episodes == null || episodes.isEmpty) {
        return;
      }
      item
        ..isReversed = !item.isReversed
        ..episodes = episodes.reversed.toList();

      if (!videoDetailController.plPlayerController.reverseFromFirst) {
        // keep current episode
        videoDetailController
          ..seasonIndex.refresh()
          ..cid.refresh();
      } else {
        // switch to first episode
        final episode = item.episodes!.first;
        if (episode.cid != videoDetailController.cid.value) {
          ugcIntroController.onChangeEpisode(episode);
          videoDetailController.seasonCid = episode.cid;
        } else {
          videoDetailController
            ..seasonIndex.refresh()
            ..cid.refresh();
        }
      }
    } else {
      // reverse part
      videoDetail
        ..isPageReversed = !videoDetail.isPageReversed
        ..pages = videoDetail.pages!.reversed.toList();
      if (!videoDetailController.plPlayerController.reverseFromFirst) {
        // keep current episode
        videoDetailController.cid.refresh();
      } else {
        // switch to first episode
        final episode = videoDetail.pages!.first;
        if (episode.cid != videoDetailController.cid.value) {
          ugcIntroController.onChangeEpisode(episode);
        } else {
          videoDetailController.cid.refresh();
        }
      }
    }
  }

  void showViewPoints() {
    final child = ViewPointsPage(
      enableSlide: false,
      videoDetailController: videoDetailController,
      plPlayerController: plPlayerController,
    );
    PageUtils.showVideoBottomSheet(
      context,
      child: videoDetailController.plPlayerController.darkVideoPage
          ? Theme(data: theme, child: child)
          : child,
    );
  }

  void onShowMemberPage(int? mid) {
    videoDetailController.childKey.currentState?.showBottomSheet(
      constraints: const BoxConstraints(),
      (context) {
        return HorizontalMemberPage(
          mid: mid,
          videoDetailController: videoDetailController,
          ugcIntroController: ugcIntroController,
        );
      },
    );
  }
}

/// 海报态播放按钮。挂载后主动请求焦点：海报的 autofocus 可能被页内其他
/// autofocus 竞争掉，整页失焦会让遥控器 OK 键完全失效。
class TvPosterPlayButton extends StatefulWidget {
  const TvPosterPlayButton({
    super.key,
    required this.onTap,
    required this.querying,
  });

  final VoidCallback onTap;
  final bool querying;

  @override
  State<TvPosterPlayButton> createState() => _TvPosterPlayButtonState();
}

class _TvPosterPlayButtonState extends State<TvPosterPlayButton> {
  late final FocusNode _focusNode = FocusNode(
    debugLabel: 'TvPosterPlayButton',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      focusNode: _focusNode,
      autofocus: true,
      onTap: widget.onTap,
      builder: (context, focused, hovered) => TvFocusHighlight(
        focused: focused,
        radius: 64,
        child: AnimatedScale(
          scale: focused ? TvConstants.focusScale : 1.0,
          duration: TvConstants.focusDuration,
          curve: Curves.easeOut,
          child: Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: widget.querying
                ? const Padding(
                    padding: EdgeInsets.all(36),
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      color: Colors.black87,
                    ),
                  )
                : const Icon(
                    Icons.play_arrow_rounded,
                    size: 76,
                    color: Colors.black,
                  ),
          ),
        ),
      ),
    );
  }
}
