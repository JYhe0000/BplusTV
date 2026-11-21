import 'dart:async';

import 'package:bplus_tv/pages/common/common_intro_controller.dart';
import 'package:bplus_tv/pages/video/controller.dart';
import 'package:bplus_tv/plugin/pl_player/controller.dart';
import 'package:bplus_tv/models/common/video/video_quality.dart';
import 'package:bplus_tv/models/video/play/url.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_dialog.dart';
import 'package:bplus_tv/tv/tv_option_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

/// TV-native player gesture handler with remote control support
/// 替代播放器中的手势，提供 TV 遥控器按键操作
class TvPlayerGestureHandler extends StatefulWidget {
  const TvPlayerGestureHandler({
    super.key,
    required this.controller,
    required this.child,
    this.videoDetailController,
    this.introController,
  });

  final PlPlayerController controller;
  final Widget child;
  final VideoDetailController? videoDetailController;
  final CommonIntroController? introController;

  @override
  State<TvPlayerGestureHandler> createState() => _TvPlayerGestureHandlerState();
}

class _TvPlayerGestureHandlerState extends State<TvPlayerGestureHandler> {
  final FocusNode _focusNode = FocusNode(
    debugLabel: 'TvPlayerGestureHandler',
    skipTraversal: true,
  );
  final FocusNode _playbackFocus = FocusNode(debugLabel: 'TvPlayback');
  bool _showControls = false;
  StreamSubscription<bool>? _controlsSub;

  @override
  void initState() {
    super.initState();
    _showControls = widget.controller.showControls.value;

    _controlsSub = widget.controller.showControls.listen((visible) {
      if (mounted) {
        setState(() => _showControls = visible);
        if (!visible) _restorePlaybackFocus();
      }
    });
  }

  void _restorePlaybackFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          widget.controller.showControls.value ||
          TvDialogScopes.hasOpenDialog ||
          ModalRoute.of(context)?.isCurrent == false) {
        return;
      }
      final primary = FocusManager.instance.primaryFocus;
      // 选集、海报按钮等有自己的焦点，不能因为控制条隐藏就把它抢回来。
      if (TvFocusUtils.isFocusable(primary) &&
          primary != _focusNode &&
          !primary!.descendants.contains(_playbackFocus)) {
        return;
      }
      _playbackFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controlsSub?.cancel();
    _focusNode.dispose();
    _playbackFocus.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (widget.controller.playerStatus.value.isPlaying) {
      widget.controller.pause();
    } else {
      widget.controller.play();
    }
  }

  void _seek(int seconds) {
    final controller = widget.controller;
    if (controller.isLive || controller.videoPlayerController == null) return;
    // position.value 的单位是秒，不能直接与毫秒偏移相加。
    final newPosition = Duration(
      milliseconds: (controller.positionInMilliseconds + seconds * 1000).clamp(
        0,
        controller.durationInMilliseconds,
      ),
    );
    controller.seekTo(newPosition);
  }

  void _toggleDanmaku() {
    widget.controller.enableShowDanmaku.value =
        !widget.controller.enableShowDanmaku.value;
  }

  Future<void> _showQualityPicker() async {
    final ctr = widget.videoDetailController;
    if (ctr == null) {
      // 没有详情控制器时退化为显示控制条（保持旧行为）。
      widget.controller.controls = true;
      return;
    }
    final formats = ctr.data.supportFormats;
    if (formats == null || formats.isEmpty) {
      widget.controller.controls = true;
      return;
    }
    final availableQa =
        ctr.data.dash?.video?.availableVideoQualities ?? const <int>{};
    final current = ctr.currentVideoQa.value?.code;
    // 与控制条「画质」按钮共用同一选择器（TvOptionPicker）。
    final selected = await showTvOptionPicker<int>(
      context: context,
      title: '选择画质',
      current: current,
      options: [
        for (final item in formats)
          if (item.quality case final code?)
            TvOption(
              value: code,
              label: VideoQuality.fromCode(code).desc,
              enabled: availableQa.isEmpty || availableQa.contains(code),
            ),
      ],
    );
    if (!mounted || selected == null) return;
    final newQa = VideoQuality.fromCode(selected);
    ctr
      ..plPlayerController.cacheVideoQa = newQa.code
      ..currentVideoQa.value = newQa
      ..updatePlayer();
    SmartDialog.showToast('画质：${newQa.shortDesc}');
  }

  void _showSpeedPicker() {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final currentIndex = speeds.indexOf(widget.controller.playbackSpeed);
    if (currentIndex >= 0) {
      final nextIndex = (currentIndex + 1) % speeds.length;
      widget.controller.setPlaybackSpeed(speeds[nextIndex]);
    }
  }

  void _prevEpisode() {
    widget.introController?.prevPlay();
  }

  void _nextEpisode() {
    widget.introController?.nextPlay();
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      focusNode: _focusNode,
      // 初始焦点交给内层 TvFocusable（见下方），避免同一子树两个 autofocus 竞争。
      autofocus: false,
      shortcuts: const {
        // 播放控制：遥控器长按 OK 会持续发送 KeyRepeatEvent，必须关闭连发，
        // 否则播放/暂停会高频抖动。
        SingleActivator(
          LogicalKeyboardKey.space,
          includeRepeats: false,
        ): _PlayPauseIntent(),
        SingleActivator(
          LogicalKeyboardKey.enter,
          includeRepeats: false,
        ): _PlayPauseIntent(),
        SingleActivator(
          LogicalKeyboardKey.select,
          includeRepeats: false,
        ): _PlayPauseIntent(),
        SingleActivator(
          LogicalKeyboardKey.numpadEnter,
          includeRepeats: false,
        ): _PlayPauseIntent(),
        SingleActivator(
          LogicalKeyboardKey.gameButtonA,
          includeRepeats: false,
        ): _PlayPauseIntent(),

        // 快进快退：保留连发（长按持续快进/快退是预期行为）
        SingleActivator(LogicalKeyboardKey.arrowLeft): _SeekIntent(-10),
        SingleActivator(LogicalKeyboardKey.arrowRight): _SeekIntent(10),

        // 功能按键：同样关闭连发，避免长按反复切换
        SingleActivator(
          LogicalKeyboardKey.keyD,
          includeRepeats: false,
        ): _ToggleDanmakuIntent(),
        SingleActivator(
          LogicalKeyboardKey.keyQ,
          includeRepeats: false,
        ): _ShowQualityIntent(),
        SingleActivator(
          LogicalKeyboardKey.keyS,
          includeRepeats: false,
        ): _ShowSpeedIntent(),
        SingleActivator(
          LogicalKeyboardKey.keyZ,
          includeRepeats: false,
        ): _PrevEpisodeIntent(),
        SingleActivator(
          LogicalKeyboardKey.keyX,
          includeRepeats: false,
        ): _NextEpisodeIntent(),
        SingleActivator(
          LogicalKeyboardKey.keyH,
          includeRepeats: false,
        ): _ToggleControlsIntent(),
      },
      actions: {
        _PlayPauseIntent: CallbackAction<_PlayPauseIntent>(
          onInvoke: (_) => _togglePlayPause(),
        ),
        _SeekIntent: CallbackAction<_SeekIntent>(
          onInvoke: (intent) => _seek(intent.seconds),
        ),
        _ToggleDanmakuIntent: CallbackAction<_ToggleDanmakuIntent>(
          onInvoke: (_) => _toggleDanmaku(),
        ),
        _ShowQualityIntent: CallbackAction<_ShowQualityIntent>(
          onInvoke: (_) => _showQualityPicker(),
        ),
        _ShowSpeedIntent: CallbackAction<_ShowSpeedIntent>(
          onInvoke: (_) => _showSpeedPicker(),
        ),
        _PrevEpisodeIntent: CallbackAction<_PrevEpisodeIntent>(
          onInvoke: (_) => _prevEpisode(),
        ),
        _NextEpisodeIntent: CallbackAction<_NextEpisodeIntent>(
          onInvoke: (_) => _nextEpisode(),
        ),
        _ToggleControlsIntent: CallbackAction<_ToggleControlsIntent>(
          onInvoke: (_) => widget.controller.controls =
              !widget.controller.showControls.value,
        ),
      },
      child: TvFocusable(
        focusNode: _playbackFocus,
        // 控制栏显示时，只遍历可见按钮，避免方向键落到无焦点提示的视频层。
        canRequestFocus: !_showControls,
        // 自动播放时由播放器接管初始焦点；未自动播放时让海报上的播放按钮抢焦点。
        autofocus: widget.videoDetailController?.autoPlay ?? true,
        onFocusChange: (focused) {
          if (focused && _showControls) {
            // 获取焦点时显示控制条
            widget.controller.controls = true;
          }
        },
        builder: (context, focused, hovered) {
          return widget.child;
        },
      ),
    );
  }
}

// Intent classes for TV controls
class _PlayPauseIntent extends Intent {
  const _PlayPauseIntent();
}

class _SeekIntent extends Intent {
  final int seconds;
  const _SeekIntent(this.seconds);
}

class _ToggleDanmakuIntent extends Intent {
  const _ToggleDanmakuIntent();
}

class _ShowQualityIntent extends Intent {
  const _ShowQualityIntent();
}

class _ShowSpeedIntent extends Intent {
  const _ShowSpeedIntent();
}

class _PrevEpisodeIntent extends Intent {
  const _PrevEpisodeIntent();
}

class _NextEpisodeIntent extends Intent {
  const _NextEpisodeIntent();
}

class _ToggleControlsIntent extends Intent {
  const _ToggleControlsIntent();
}
