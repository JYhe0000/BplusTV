import 'dart:async';

import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/common/widgets/progress_bar/audio_video_progress_bar.dart';
import 'package:bplus_tv/models/common/video/video_quality.dart';
import 'package:bplus_tv/models/video/play/url.dart';
import 'package:bplus_tv/pages/common/common_intro_controller.dart';
import 'package:bplus_tv/pages/video/controller.dart';
import 'package:bplus_tv/plugin/pl_player/controller.dart';
import 'package:bplus_tv/plugin/pl_player/models/play_status.dart';
import 'package:bplus_tv/tv/player/tv_player_layout.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_dialog.dart';
import 'package:bplus_tv/tv/tv_option_picker.dart';
import 'package:bplus_tv/utils/duration_utils.dart';
import 'package:bplus_tv/utils/storage.dart';
import 'package:bplus_tv/utils/storage_key.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

/// TV-native player control bar with its own focus node and index based
/// navigation, so the remote can always reach every button.
class TvBottomControl extends StatefulWidget {
  const TvBottomControl({
    super.key,
    required this.controller,
    this.introController,
    this.videoDetailController,
  });

  final PlPlayerController controller;
  final CommonIntroController? introController;
  final VideoDetailController? videoDetailController;

  @override
  State<TvBottomControl> createState() => _TvBottomControlState();
}

class _TvBottomControlState extends State<TvBottomControl> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'TvBottomControl');
  final List<GlobalKey> _actionKeys = [];
  final List<FocusNode> _actionNodes = [];
  StreamSubscription<bool>? _sub;
  int _index = 0;
  bool _pickerOpen = false;
  bool _focusScheduled = false;
  bool _focusRequested = false;

  List<_TvAction> get _actions => [
    _TvAction(
      icon: widget.controller.playerStatus.isPlaying
          ? Icons.pause_rounded
          : Icons.play_arrow_rounded,
      label: widget.controller.playerStatus.isPlaying ? '暂停' : '播放',
      onTap: widget.controller.onDoubleTapCenter,
    ),
    if (widget.introController != null) ...[
      _TvAction(
        icon: Icons.skip_previous_rounded,
        label: '上一集',
        onTap: () => widget.introController!.prevPlay(),
      ),
      _TvAction(
        icon: Icons.skip_next_rounded,
        label: '下一集',
        onTap: () => widget.introController!.nextPlay(),
      ),
    ],
    if (!widget.controller.isLive) ...[
      _TvAction(
        icon: Icons.fast_rewind_rounded,
        label: '后退',
        onTap: () => widget.controller.onBackward(
          widget.controller.fastForBackwardDuration,
        ),
      ),
      _TvAction(
        icon: Icons.fast_forward_rounded,
        label: '快进',
        onTap: () => widget.controller.onForward(
          widget.controller.fastForBackwardDuration,
        ),
      ),
    ],
    _TvAction(
      icon: widget.controller.enableShowDanmaku.value
          ? Icons.subtitles_rounded
          : Icons.subtitles_off_rounded,
      label: '弹幕开关',
      onTap: _toggleDanmaku,
    ),
    _TvAction(
      label: '倍速',
      onTap: _pickSpeed,
      child: _TvValueText('${widget.controller.playbackSpeed}X'),
    ),
    if (widget.videoDetailController != null)
      _TvAction(
        label: '画质',
        onTap: _pickQuality,
        child: _TvValueText(
          widget.videoDetailController!.currentVideoQa.value?.shortDesc ?? '画质',
        ),
      ),
    // TV 恒为全屏，无退出全屏概念；同位置提供遥控器可达的截图入口。
    _TvAction(
      icon: Icons.photo_camera_rounded,
      label: '截图',
      onTap: () => widget.controller.takeScreenshot(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _sub = widget.controller.showControls.listen((visible) {
      if (!mounted) return;
      if (visible) {
        if (!_pickerOpen) _index = 0;
        _focusRequested = false;
        _ensureFocused(force: true);
      } else {
        if (_focusNode.hasFocus) _focusNode.unfocus();
        _focusRequested = false;
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    for (final node in _actionNodes) {
      node.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  /// 仅在打开控制栏或关闭选择器时恢复焦点，允许向上进入标题栏。
  void _ensureFocused({bool force = false}) {
    if (_pickerOpen || _focusScheduled || TvDialogScopes.hasOpenDialog) return;
    if (!mounted || !widget.controller.showControls.value) return;
    if (_focusNode.hasFocus) return;
    if (_focusRequested && !force) return;
    _focusScheduled = true;
    _focusRequested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusScheduled = false;
      if (!mounted) return;
      if (!_pickerOpen &&
          !TvDialogScopes.hasOpenDialog &&
          ModalRoute.of(context)?.isCurrent != false &&
          widget.controller.showControls.value &&
          !_focusNode.hasFocus) {
        if (_actionNodes.isNotEmpty) {
          _actionNodes[_index.clamp(0, _actionNodes.length - 1)].requestFocus();
          _revealAction(_index);
        }
      } else if (!widget.controller.showControls.value) {
        _focusRequested = false;
      }
    });
  }

  void _revealAction(int index) {
    if (index < 0 || index >= _actionKeys.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || index >= _actionKeys.length) return;
      final actionContext = _actionKeys[index].currentContext;
      if (actionContext == null) return;
      final renderObject = actionContext.findRenderObject();
      final scrollable = Scrollable.maybeOf(
        actionContext,
        axis: Axis.horizontal,
      );
      if (renderObject == null ||
          !renderObject.attached ||
          scrollable == null) {
        return;
      }
      scrollable.position.ensureVisible(
        renderObject,
        alignment: 0.5,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    // 方向键允许长按移动；激活/返回只处理首次按下，避免穿透到上层。
    final horizontal =
        event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.arrowRight;
    if (event is KeyRepeatEvent && !horizontal) {
      return KeyEventResult.handled;
    }
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final actions = _actions;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        widget.controller.controls = true;
        setState(() => _index = (_index - 1).clamp(0, actions.length - 1));
        _actionNodes[_index].requestFocus();
        _revealAction(_index);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        widget.controller.controls = true;
        setState(() => _index = (_index + 1).clamp(0, actions.length - 1));
        _actionNodes[_index].requestFocus();
        _revealAction(_index);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.numpadEnter:
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.gameButtonA:
        widget.controller.controls = true;
        actions[_index.clamp(0, actions.length - 1)].onTap();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        widget.controller.controls = true;
        _actionNodes[_index].focusInDirection(TraversalDirection.up);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        // TV: symmetric reset — the bar was summoned by up, down hides it.
        // Opening the episodes panel stays on the PlayerFocus down path
        // (bar hidden), so focus never gets stranded between the two.
        widget.controller.controls = false;
        return KeyEventResult.handled;
      case LogicalKeyboardKey.goBack:
      case LogicalKeyboardKey.escape:
      case LogicalKeyboardKey.browserBack:
        // TV: back dismisses the on-screen control bar. A second press (with
        // the bar hidden) leaves the page.
        widget.controller.controls = false;
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _toggleDanmaku() {
    final controller = widget.controller;
    final newVal = !controller.enableShowDanmaku.value;
    controller.enableShowDanmaku.value = newVal;
    if (!controller.tempPlayerConf) {
      GStorage.setting.put(SettingBoxKey.enableShowDanmaku, newVal);
    }
    SmartDialog.showToast(newVal ? '弹幕已开启' : '弹幕已关闭');
  }

  Future<void> _pickSpeed() async {
    final controller = widget.controller;
    final speeds = controller.speedList;
    if (speeds.isEmpty) return;
    final current = controller.playbackSpeed;
    _pickerOpen = true;
    final selected = await showTvOptionPicker<double>(
      context: context,
      title: '倍速',
      current: current,
      options: [
        for (final speed in speeds) TvOption(value: speed, label: '${speed}X'),
      ],
    );
    if (!mounted) return;
    controller.controls = true;
    _pickerOpen = false;
    _ensureFocused(force: true);
    if (selected == null) return;
    controller.setPlaybackSpeed(selected);
    SmartDialog.showToast('${selected}X');
  }

  Future<void> _pickQuality() async {
    final ctr = widget.videoDetailController;
    if (ctr == null) return;
    final formats = ctr.data.supportFormats;
    if (formats == null || formats.isEmpty) return;
    final availableQa =
        ctr.data.dash?.video?.availableVideoQualities ?? const <int>{};
    final current = ctr.currentVideoQa.value?.code;
    _pickerOpen = true;
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
    if (!mounted) return;
    widget.controller.controls = true;
    _pickerOpen = false;
    _ensureFocused(force: true);
    if (selected == null) return;
    final newQa = VideoQuality.fromCode(selected);
    ctr
      ..plPlayerController.cacheVideoQa = newQa.code
      ..currentVideoQa.value = newQa
      ..updatePlayer();
    SmartDialog.showToast('画质：${newQa.shortDesc}');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Obx(() {
      final visible = widget.controller.showControls.value;
      _ensureFocused();
      final actions = _actions;
      _index = _index.clamp(0, actions.length - 1);
      while (_actionKeys.length < actions.length) {
        _actionKeys.add(GlobalKey());
        _actionNodes.add(
          FocusNode(debugLabel: 'TvPlayerAction${_actionNodes.length}'),
        );
      }
      return Focus(
        focusNode: _focusNode,
        canRequestFocus: visible,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (visible && _focusNode.hasFocus) _revealAction(_index);
            final availableHeight =
                TvPlayerLayout.maybeSizeOf(context)?.height ??
                (constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : MediaQuery.sizeOf(context).height);
            final compact = constraints.maxWidth < 900 || availableHeight < 500;
            final horizontalPadding = compact ? 16.0 : 28.0;
            final verticalPadding = compact ? 8.0 : 12.0;
            final buttonWidth = compact ? 68.0 : 80.0;
            final buttonHeight = compact ? 58.0 : 66.0;

            return netflixPlayerSurface(
              radius: compact ? 14 : 20,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  verticalPadding,
                  horizontalPadding,
                  verticalPadding,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.40),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(compact ? 14 : 20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!widget.controller.isLive) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Obx(
                              () => ProgressBar(
                                progress: widget.controller.progress,
                                buffered: widget.controller.buffered.value,
                                total: widget.controller.duration.value,
                                progressBarColor: colorScheme.primary,
                                baseBarColor: const Color(0x40FFFFFF),
                                bufferedBarColor: colorScheme.primary
                                    .withValues(
                                      alpha: 0.4,
                                    ),
                                thumbColor: colorScheme.primary,
                                thumbGlowColor: colorScheme.primary.withValues(
                                  alpha: 0.3,
                                ),
                                barHeight: compact ? 3.5 : 4,
                                thumbRadius: compact ? 6 : 7,
                                thumbGlowRadius: compact ? 16 : 20,
                                onSeek: (milliseconds) {
                                  widget.controller
                                    ..position.value = milliseconds ~/ 1000
                                    ..onSeekEnd()
                                    ..seekTo(
                                      Duration(milliseconds: milliseconds),
                                      isSeek: false,
                                    );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Obx(
                            () => Text(
                              '${DurationUtils.formatDuration(widget.controller.position.value)}'
                              ' / ${DurationUtils.formatDuration(widget.controller.duration.value)}',
                              maxLines: 1,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: compact ? 14 : 16,
                                fontWeight: FontWeight.w600,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 5 : 8),
                    ],
                    SizedBox(
                      height: buttonHeight,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < actions.length; i++)
                              SizedBox(
                                key: _actionKeys[i],
                                child: _TvControlButton(
                                  icon: actions[i].icon,
                                  label: actions[i].label,
                                  focusNode: _actionNodes[i],
                                  canRequestFocus: visible,
                                  onFocusChange: (focused) {
                                    if (focused) {
                                      _index = i;
                                      _revealAction(i);
                                    }
                                  },
                                  width: buttonWidth,
                                  height: buttonHeight,
                                  compact: compact,
                                  onTap: () {
                                    widget.controller.controls = true;
                                    setState(() => _index = i);
                                    _actionNodes[i].requestFocus();
                                    actions[i].onTap();
                                  },
                                  child: actions[i].child,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

class _TvAction {
  const _TvAction({
    required this.label,
    required this.onTap,
    this.icon,
    this.child,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Widget? child;
}

/// Compact current-value label used by the speed / quality buttons so the bar
/// always shows the active state instead of a static icon.
class _TvValueText extends StatelessWidget {
  const _TvValueText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _TvControlButton extends StatelessWidget {
  const _TvControlButton({
    required this.label,
    required this.focusNode,
    required this.canRequestFocus,
    required this.onFocusChange,
    required this.onTap,
    required this.width,
    required this.height,
    required this.compact,
    this.icon,
    this.child,
  });

  final String label;
  final IconData? icon;
  final Widget? child;
  final FocusNode focusNode;
  final bool canRequestFocus;
  final ValueChanged<bool> onFocusChange;
  final VoidCallback onTap;
  final double width;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: TvFocusable(
          focusNode: focusNode,
          canRequestFocus: canRequestFocus,
          onFocusChange: onFocusChange,
          onTap: onTap,
          builder: (context, focused, hovered) => TvFocusHighlight(
            focused: focused,
            radius: compact ? 12 : 14,
            borderWidth: focused ? 2.5 : 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: width,
              height: height,
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: focused ? 0.10 : 0.045),
                borderRadius: BorderRadius.circular(compact ? 12 : 14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: compact ? 23 : 28,
                    child: Center(
                      child:
                          child ??
                          Icon(
                            icon,
                            color: Colors.white,
                            size: compact ? 21 : 24,
                          ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: focused ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
