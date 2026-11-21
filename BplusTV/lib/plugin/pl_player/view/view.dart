import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:bplus_tv/common/assets.dart';
import 'package:bplus_tv/common/constants.dart';
import 'package:bplus_tv/common/style.dart';
import 'package:bplus_tv/common/widgets/cropped_image.dart';
import 'package:bplus_tv/common/widgets/loading_widget.dart';
import 'package:bplus_tv/common/widgets/pair.dart';
import 'package:bplus_tv/common/widgets/progress_bar/audio_video_progress_bar.dart';
import 'package:bplus_tv/common/widgets/progress_bar/segment_progress_bar.dart';
import 'package:bplus_tv/models/common/sponsor_block/action_type.dart';
import 'package:bplus_tv/models/common/sponsor_block/post_segment_model.dart';
import 'package:bplus_tv/models/common/sponsor_block/segment_type.dart';
import 'package:bplus_tv/models/common/video/video_quality.dart';
import 'package:bplus_tv/models/video/play/url.dart';
import 'package:bplus_tv/models_new/video/video_detail/episode.dart' as ugc;
import 'package:bplus_tv/models_new/video/video_detail/ugc_season.dart';
import 'package:bplus_tv/pages/common/common_intro_controller.dart';
import 'package:bplus_tv/pages/video/controller.dart';
import 'package:bplus_tv/pages/video/post_panel/popup_menu_text.dart';
import 'package:bplus_tv/pages/video/post_panel/view.dart';
import 'package:bplus_tv/pages/video/widgets/header_control.dart';
import 'package:bplus_tv/plugin/pl_player/controller.dart';
import 'package:bplus_tv/plugin/pl_player/models/data_status.dart';
import 'package:bplus_tv/plugin/pl_player/models/play_status.dart';
import 'package:bplus_tv/plugin/pl_player/widgets/app_bar_ani.dart';
import 'package:bplus_tv/plugin/pl_player/widgets/backward_seek.dart';
import 'package:bplus_tv/plugin/pl_player/widgets/forward_seek.dart';
import 'package:bplus_tv/plugin/pl_player/widgets/mpv_convert_webp.dart';
import 'package:bplus_tv/tv/player/tv_player_gesture_handler.dart';
import 'package:bplus_tv/tv/player/tv_player_layout.dart';
import 'package:bplus_tv/utils/android/bindings.g.dart';
import 'package:bplus_tv/utils/cache_manager.dart';
import 'package:bplus_tv/utils/duration_utils.dart';
import 'package:bplus_tv/utils/extension/num_ext.dart';
import 'package:bplus_tv/utils/extension/theme_ext.dart';
import 'package:bplus_tv/utils/image_utils.dart';
import 'package:bplus_tv/utils/mobile_observer.dart';
import 'package:bplus_tv/utils/path_utils.dart';
import 'package:bplus_tv/utils/utils.dart';
import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit_video/media_kit_video.dart';

part 'widgets.dart';

class PLVideoPlayer extends StatefulWidget {
  const PLVideoPlayer({
    required this.maxWidth,
    required this.maxHeight,
    required this.plPlayerController,
    this.videoDetailController,
    this.introController,
    required this.headerControl,
    required this.bottomControl,
    this.danmuWidget,
    this.showEpisodes,
    this.showViewPoints,
    this.fill = Colors.black,
    this.alignment = Alignment.center,
    super.key,
  });

  final double maxWidth;
  final double maxHeight;
  final PlPlayerController plPlayerController;
  final VideoDetailController? videoDetailController;
  final CommonIntroController? introController;
  final Widget headerControl;
  final Widget bottomControl;
  final Widget? danmuWidget;
  final void Function([
    int?,
    UgcSeason?,
    List<ugc.BaseEpisodeItem>?,
    String?,
    int?,
    int?,
  ])?
  showEpisodes;
  final VoidCallback? showViewPoints;
  final Color fill;
  final Alignment alignment;

  @override
  State<PLVideoPlayer> createState() => _PLVideoPlayerState();
}

class _PLVideoPlayerState extends State<PLVideoPlayer>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late AnimationController _animationController;
  late VideoController videoController;
  late final VideoDetailController videoDetailController =
      widget.videoDetailController!;

  final _playerKey = GlobalKey();
  final _videoKey = GlobalKey();
  bool _pauseDueToPauseUponEnteringBackgroundMode = false;
  int? tmpSubtitlePaddingB;
  StreamSubscription? _controlsListener;

  PlPlayerController get plPlayerController => widget.plPlayerController;
  bool get isFullScreen => plPlayerController.isFullScreen.value;

  late ColorScheme colorScheme;
  late double maxWidth;
  late double maxHeight;

  void _onControlChanged(bool val) {
    final visible = val && !plPlayerController.controlsLock.value;

    final headerKey = widget.headerControl.key;
    if (headerKey is GlobalKey<TimeBatteryMixin>) {
      if (headerKey.currentState case final state?) {
        if (state.mounted) {
          state.getBatteryLevelIfNeeded();
          state.provider
            ?..startIfNeeded()
            ..muted = !visible;
          if (visible) {
            state.startClock();
          } else {
            state.stopClock();
          }
        }
      }
    }

    if (visible) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }

    if (widget.videoDetailController case final controller?) {
      if (controller.vttSubtitlesIndex.value != 0) {
        if (visible) {
          const int minPadding = 70;
          if (plPlayerController.subtitlePaddingB < minPadding) {
            tmpSubtitlePaddingB = plPlayerController.subtitlePaddingB;
            plPlayerController
              ..subtitlePaddingB = minPadding
              ..subtitleConfig.value = plPlayerController.getSubConfig;
          }
        } else {
          if (tmpSubtitlePaddingB != null) {
            plPlayerController
              ..subtitlePaddingB = tmpSubtitlePaddingB!
              ..subtitleConfig.value = plPlayerController.getSubConfig;
            tmpSubtitlePaddingB = null;
          }
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    addObserverMobile(this);
    _controlsListener = plPlayerController.showControls.listen(
      _onControlChanged,
    );
    _animationController = AnimationController(
      vsync: this,
      value:
          plPlayerController.showControls.value &&
              !plPlayerController.controlsLock.value
          ? 1
          : 0,
      duration: const Duration(milliseconds: 100),
    );
    videoController = plPlayerController.videoController!;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    colorScheme = ColorScheme.of(context);
  }

  @override
  void didUpdateWidget(covariant PLVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (AndroidHelper.isPipMode) {
      plPlayerController.controls = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!plPlayerController.continuePlayInBackground.value) {
      late final player = plPlayerController.videoPlayerController;
      if (const <AppLifecycleState>[.paused, .detached].contains(state)) {
        if (player != null && player.state.playing) {
          _pauseDueToPauseUponEnteringBackgroundMode = true;
          player.pause();
        }
      } else {
        if (_pauseDueToPauseUponEnteringBackgroundMode) {
          _pauseDueToPauseUponEnteringBackgroundMode = false;
          player?.play();
        }
      }
    }
  }

  @override
  void dispose() {
    removeObserverMobile(this);
    _controlsListener?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    maxWidth = widget.maxWidth;
    maxHeight = widget.maxHeight;
    final isFullScreen = this.isFullScreen;
    final primary = isFullScreen && colorScheme.isLight
        ? colorScheme.inversePrimary
        : colorScheme.primary;
    late final thumbGlowColor = primary.withAlpha(80);
    late final bufferedBarColor = primary.withValues(alpha: 0.4);
    const TextStyle textStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
    );
    final isLive = plPlayerController.isLive;

    return Stack(
      fit: StackFit.passthrough,
      key: _playerKey,
      children: <Widget>[
        _videoWidget,
        if (widget.danmuWidget case final danmaku?)
          Positioned.fill(top: 4, child: danmaku),
        if (!isLive)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !plPlayerController.enableDragSubtitle,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth.isFinite
                      ? constraints.maxWidth
                      : maxWidth;
                  final availableHeight = constraints.maxHeight.isFinite
                      ? constraints.maxHeight
                      : maxHeight;
                  // 保留用户字幕设置，仅按播放器实际可用尺寸限制过大的文字。
                  final maxFontSize = math
                      .min(availableHeight * 0.06, availableWidth * 0.045)
                      .clamp(12.0, 64.0)
                      .toDouble();

                  return Obx(() {
                    final configuration =
                        plPlayerController.subtitleConfig.value;
                    final fontSize = configuration.style.fontSize ?? 16;
                    final controlsVisible =
                        plPlayerController.showControls.value &&
                        !plPlayerController.controlsLock.value;
                    final compact =
                        availableWidth < 900 || availableHeight < 500;
                    final bottomPadding = controlsVisible
                        ? math.max(
                            configuration.padding.bottom,
                            compact ? 112.0 : 136.0,
                          )
                        : configuration.padding.bottom;
                    final effectiveConfiguration = configuration.copyWith(
                      padding: configuration.padding.copyWith(
                        left: math.min(
                          configuration.padding.left,
                          availableWidth * 0.2,
                        ),
                        right: math.min(
                          configuration.padding.right,
                          availableWidth * 0.2,
                        ),
                        bottom: math.min(bottomPadding, availableHeight * 0.6),
                      ),
                      style: configuration.style.copyWith(
                        fontSize: math.min(fontSize, maxFontSize),
                      ),
                      strokeStyle: configuration.strokeStyle?.copyWith(
                        fontSize: math.min(
                          configuration.strokeStyle!.fontSize ?? fontSize,
                          maxFontSize,
                        ),
                      ),
                    );
                    return DefaultTextStyle.merge(
                      maxLines: compact ? 3 : 4,
                      overflow: TextOverflow.ellipsis,
                      child: SubtitleView(
                        controller: videoController,
                        configuration: effectiveConfiguration,
                        enableDragSubtitle:
                            plPlayerController.enableDragSubtitle,
                        onUpdatePadding: plPlayerController.onUpdatePadding,
                      ),
                    );
                  });
                },
              ),
            ),
          ),

        /// 长按倍速 toast
        if (!isLive)
          IgnorePointer(
            ignoring: true,
            child: Align(
              alignment: Alignment.topCenter,
              child: FractionalTranslation(
                translation: isFullScreen
                    ? const Offset(0.0, 1.2)
                    : const Offset(0.0, 0.8),
                child: Obx(
                  () => AnimatedOpacity(
                    curve: Curves.easeInOut,
                    opacity: plPlayerController.longPressStatus.value
                        ? 1.0
                        : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0x88000000),
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      child: Obx(
                        () => Text(
                          '${plPlayerController.enableAutoLongPressSpeed ? (plPlayerController.longPressStatus.value ? plPlayerController.lastPlaybackSpeed : plPlayerController.playbackSpeed) * 2 : plPlayerController.longPressSpeed}倍速中',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

        /// 时间进度 toast
        if (!isLive)
          IgnorePointer(
            ignoring: true,
            child: Align(
              alignment: Alignment.topCenter,
              child: FractionalTranslation(
                translation: isFullScreen
                    ? const Offset(0.0, 1.2)
                    : const Offset(0.0, 0.8),
                child: Obx(
                  () => AnimatedOpacity(
                    curve: Curves.easeInOut,
                    opacity: plPlayerController.isSeeking.value ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0x88000000),
                        borderRadius: BorderRadius.all(Radius.circular(64)),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Row(
                        spacing: 2,
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Obx(
                            () => Text(
                              DurationUtils.formatDuration(
                                plPlayerController.seekPosition.value,
                              ),
                              style: textStyle,
                            ),
                          ),
                          const Text('/', style: textStyle),
                          Obx(
                            () => Text(
                              DurationUtils.formatDuration(
                                plPlayerController.duration.value,
                              ),
                              style: textStyle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

        /// 音量控制条展示
        IgnorePointer(
          ignoring: true,
          child: Align(
            alignment: Alignment.center,
            child: Obx(
              () {
                final volume = plPlayerController.volume.value;
                return AnimatedOpacity(
                  curve: Curves.easeInOut,
                  opacity: plPlayerController.volumeIndicator.value ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0x88000000),
                      borderRadius: BorderRadius.all(Radius.circular(64)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          volume == 0.0
                              ? Icons.volume_off
                              : volume < 0.5
                              ? Icons.volume_down
                              : Icons.volume_up,
                          color: Colors.white,
                          size: 20.0,
                        ),
                        const SizedBox(width: 2.0),
                        Text(
                          '${(volume * 100.0).round()}%',
                          style: const TextStyle(
                            fontSize: 13.0,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // 头部、底部控制条由页面提供，统一使用 TV 控件。
        Positioned.fill(
          top: -1,
          bottom: -1,
          child: ClipRect(
            child: RepaintBoundary(
              child: LayoutBuilder(
                builder: (context, constraints) => TvPlayerLayout(
                  size: constraints.biggest,
                  child: Obx(
                    () => IgnorePointer(
                      ignoring:
                          !plPlayerController.showControls.value ||
                          plPlayerController.controlsLock.value,
                      child: ExcludeFocus(
                        excluding:
                            !plPlayerController.showControls.value ||
                            plPlayerController.controlsLock.value,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppBarAni(
                              isTop: true,
                              controller: _animationController,
                              isFullScreen: isFullScreen,
                              removeSafeArea: plPlayerController.removeSafeArea,
                              child: widget.headerControl,
                            ),
                            AppBarAni(
                              isTop: false,
                              controller: _animationController,
                              isFullScreen: isFullScreen,
                              removeSafeArea: plPlayerController.removeSafeArea,
                              child: widget.bottomControl,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        /// 进度条在直播模式下禁用
        if (!isLive)
          Positioned(
            bottom: -2.2,
            left: 0,
            right: 0,
            child: Obx(
              () {
                final showControls = plPlayerController.showControls.value;
                final bool offstage;
                switch (plPlayerController.progressType) {
                  case .alwaysShow:
                    offstage = showControls;
                  case .alwaysHide:
                    if (!plPlayerController.isSeeking.value) {
                      return const SizedBox.shrink();
                    }
                    offstage = showControls;
                  case .onlyShowFullScreen:
                    offstage =
                        showControls ||
                        (!isFullScreen && !plPlayerController.isSeeking.value);
                  case .onlyHideFullScreen:
                    offstage =
                        showControls ||
                        (isFullScreen && !plPlayerController.isSeeking.value);
                }
                return Offstage(
                  offstage: offstage,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      Obx(
                        () => ProgressBar(
                          progress: plPlayerController.progress,
                          buffered: plPlayerController.buffered.value,
                          total: plPlayerController.duration.value,
                          progressBarColor: primary,
                          baseBarColor: const Color(0x33FFFFFF),
                          bufferedBarColor: bufferedBarColor,
                          thumbColor: primary,
                          thumbGlowColor: thumbGlowColor,
                          barHeight: 3.5,
                          thumbRadius: 2.5,
                        ),
                      ),
                      if (plPlayerController.enableBlock &&
                          videoDetailController.segmentProgressList.isNotEmpty)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0.75,
                          child: SegmentProgressBar(
                            segments: videoDetailController.segmentProgressList,
                          ),
                        ),
                      if (plPlayerController.showViewPoints &&
                          videoDetailController.viewPointList.isNotEmpty &&
                          videoDetailController.showVP.value)
                        Padding(
                          padding: const .only(bottom: 4.25),
                          child: ViewPointSegmentProgressBar(
                            segments: videoDetailController.viewPointList,
                          ),
                        ),
                      if (plPlayerController.showDmChart &&
                          videoDetailController.showDmTrendChart.value)
                        if (videoDetailController.dmTrend.value?.dataOrNull
                            case final list?)
                          buildDmChart(primary, list, videoDetailController),
                    ],
                  ),
                );
              },
            ),
          ),

        if (!isLive && plPlayerController.showSeekPreview)
          buildSeekPreviewWidget(
            plPlayerController,
            maxWidth,
            maxHeight,
            () => mounted,
          ),

        Obx(() {
          if (plPlayerController.dataStatus.loading ||
              (plPlayerController.isBuffering.value &&
                  plPlayerController.playerStatus.isPlaying)) {
            return Center(
              child: GestureDetector(
                onTap: plPlayerController.refreshPlayer,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Colors.black26, Colors.transparent],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        Assets.buffering,
                        height: 25,
                        cacheHeight: 25.cacheSize(context),
                        semanticLabel: '加载中',
                        color: Colors.white,
                      ),
                      if (plPlayerController.isBuffering.value)
                        Obx(() {
                          final buffered = plPlayerController.buffered.value;
                          if (buffered == 0) {
                            return const Text(
                              '加载中...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            );
                          }
                          return Text(
                            DurationUtils.formatDuration(buffered),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        }),

        /// 点击快进、快退
        if (!isLive)
          Obx(() {
            final mountSeekBackwardButton =
                plPlayerController.mountSeekBackwardButton.value;
            final mountSeekForwardButton =
                plPlayerController.mountSeekForwardButton.value;
            return mountSeekBackwardButton || mountSeekForwardButton
                ? Positioned.fill(
                    child: Row(
                      children: [
                        if (mountSeekBackwardButton)
                          Expanded(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 500),
                              builder: (context, value, child) => Opacity(
                                opacity: value,
                                child: child,
                              ),
                              child: BackwardSeekIndicator(
                                duration:
                                    plPlayerController.fastForBackwardDuration,
                                onSubmitted: (Duration value) {
                                  plPlayerController
                                    ..mountSeekBackwardButton.value = false
                                    ..onBackward(value);
                                },
                              ),
                            ),
                          ),
                        const Spacer(flex: 2),
                        if (mountSeekForwardButton)
                          Expanded(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 500),
                              builder: (context, value, child) => Opacity(
                                opacity: value,
                                child: child,
                              ),
                              child: ForwardSeekIndicator(
                                duration:
                                    plPlayerController.fastForBackwardDuration,
                                onSubmitted: (Duration value) {
                                  plPlayerController
                                    ..mountSeekForwardButton.value = false
                                    ..onForward(value);
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : const SizedBox.shrink();
          }),
      ],
    );
  }

  Widget get _videoWidget => TvPlayerGestureHandler(
    controller: plPlayerController,
    videoDetailController: widget.videoDetailController,
    introController: widget.introController,
    child: Container(
      clipBehavior: .none,
      width: maxWidth,
      height: maxHeight,
      color: widget.fill,
      child: RepaintBoundary(
        key: _videoKey,
        child: Obx(
          () {
            final videoFit = plPlayerController.videoFit.value;
            return Transform.flip(
              flipX: plPlayerController.flipX.value,
              flipY: plPlayerController.flipY.value,
              child: FittedBox(
                fit: videoFit.boxFit,
                alignment: widget.alignment,
                child: SimpleVideo(
                  controller: plPlayerController.videoController!,
                  fill: widget.fill,
                  aspectRatio: videoFit.aspectRatio,
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  Future<void> screenshotWebp() async {
    final videoInfo = videoDetailController.data;
    final ids = videoInfo.dash!.video!.availableVideoQualities;
    final video = videoDetailController.findVideoByQa(ids.min);

    VideoQuality qa = video.quality;
    String? url = video.baseUrl;
    if (url == null) return;

    final ctr = plPlayerController;
    final theme = Theme.of(context);
    final currentPos = ctr.positionInMilliseconds / 1000.0;
    final duration = ctr.durationInMilliseconds / 1000.0;
    final segment = Pair(first: currentPos, second: currentPos);
    final model = PostSegmentModel(
      segment: segment,
      category: SegmentType.sponsor,
      actionType: ActionType.skip,
    );
    final isPlay = ctr.playerStatus.isPlaying;
    if (isPlay) ctr.pause();

    WebpPreset preset = WebpPreset.def;

    final success =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('动态截图'),
            content: Column(
              spacing: 12,
              mainAxisSize: MainAxisSize.min,
              children: [
                PostPanel.segmentWidget(
                  theme,
                  item: model,
                  currentPos: () => currentPos,
                  videoDuration: duration,
                ),
                PopupMenuText(
                  title: '选择画质',
                  value: () => qa.code,
                  onSelected: (value) {
                    final video = videoDetailController.findVideoByQa(value);
                    url = video.baseUrl;
                    qa = video.quality;
                    return false;
                  },
                  itemBuilder: (context) => videoInfo.supportFormats!
                      .map(
                        (i) => PopupMenuItem(
                          enabled: ids.contains(i.quality),
                          value: i.quality,
                          child: Text(i.newDesc ?? ''),
                        ),
                      )
                      .toList(),
                  getSelectTitle: (_) => qa.shortDesc,
                ),
                PopupMenuText(
                  title: 'webp预设',
                  value: () => preset,
                  onSelected: (value) {
                    preset = value;
                    return false;
                  },
                  itemBuilder: (context) => WebpPreset.values
                      .map((i) => PopupMenuItem(value: i, child: Text(i.name)))
                      .toList(),
                  getSelectTitle: (i) => '${i.name}(${i.desc})',
                ),
                Text(
                  '*转码使用CPU，速度可能慢于播放，请不要选择过长的时间段或过高画质',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: Get.back,
                child: Text(
                  '取消',
                  style: TextStyle(color: theme.colorScheme.outline),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (segment.first < segment.second) {
                    Get.back(result: true);
                  }
                },
                child: const Text('确定'),
              ),
            ],
          ),
        ) ??
        false;
    if (!success) return;

    final progress = 0.0.obs;
    final name =
        '${ctr.cid}-${segment.first.toStringAsFixed(3)}_${segment.second.toStringAsFixed(3)}.webp';
    final file = '$tmpDirPath/$name';

    final mpv = MpvConvertWebp(
      url!,
      file,
      segment.first,
      segment.second,
      progress: progress,
      preset: preset,
    );
    final future = mpv.convert().whenComplete(
      () => SmartDialog.dismiss(status: SmartStatus.loading),
    );

    SmartDialog.showLoading(
      backType: SmartBackType.normal,
      builder: (_) => LoadingWidget(progress: progress, msg: '正在保存，可能需要较长时间'),
      onDismiss: () async {
        if (progress.value < 1.0) {
          mpv.dispose();
        }
        if (await future) {
          await ImageUtils.saveFileImg(
            filePath: file,
            fileName: name,
            needToast: true,
          );
        } else {
          SmartDialog.showToast('转码出现错误或已取消');
        }
        if (isPlay) ctr.play();
      },
    );
  }
}
