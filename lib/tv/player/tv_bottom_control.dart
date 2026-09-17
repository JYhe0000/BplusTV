import 'dart:async';

import 'package:PiliPlus/common/widgets/progress_bar/audio_video_progress_bar.dart';
import 'package:PiliPlus/pages/common/common_intro_controller.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/utils/duration_utils.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

/// TV-native player control bar with its own focus node and index based
/// navigation, so the remote can always reach every button.
class TvBottomControl extends StatefulWidget {
  const TvBottomControl({
    super.key,
    required this.controller,
    required this.isFullScreen,
    this.introController,
    this.onOpenPanel,
  });

  final PlPlayerController controller;
  final bool isFullScreen;
  final CommonIntroController? introController;
  final VoidCallback? onOpenPanel;

  @override
  State<TvBottomControl> createState() => _TvBottomControlState();
}

class _TvBottomControlState extends State<TvBottomControl> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'TvBottomControl');
  StreamSubscription<bool>? _sub;
  int _index = 0;

  List<_TvAction> get _actions => [
    _TvAction(
      icon: Icons.play_arrow_rounded,
      label: '播放/暂停',
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
    _TvAction(
      icon: Icons.subtitles_rounded,
      label: '弹幕开关',
      onTap: () => widget.controller.enableShowDanmaku.value =
          !widget.controller.enableShowDanmaku.value,
    ),
    _TvAction(
      icon: Icons.speed_rounded,
      label: '倍速',
      onTap: () {
        const speeds = [1.0, 1.25, 1.5, 2.0];
        final current = widget.controller.playbackSpeed;
        final index = speeds.indexOf(current);
        widget.controller
            .setPlaybackSpeed(speeds[(index + 1) % speeds.length]);
      },
    ),
    _TvAction(
      icon: widget.isFullScreen
          ? Icons.fullscreen_exit_rounded
          : Icons.fullscreen_rounded,
      label: widget.isFullScreen ? '退出全屏' : '全屏',
      onTap: () =>
          widget.controller.triggerFullScreen(status: !widget.isFullScreen),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _sub = widget.controller.showControls.listen((visible) {
      if (!mounted) return;
      if (visible) {
        _index = 0;
      } else if (_focusNode.hasFocus) {
        _focusNode.unfocus();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final actions = _actions;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        setState(() => _index = (_index - 1).clamp(0, actions.length - 1));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        setState(() => _index = (_index + 1).clamp(0, actions.length - 1));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.select:
        actions[_index].onTap();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        widget.controller.controls = false;
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        widget.controller.controls = false;
        widget.onOpenPanel?.call();
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Obx(() {
      final visible = widget.controller.showControls.value;
      if (visible && !_focusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.controller.showControls.value) {
            _focusNode.requestFocus();
          }
        });
      }
      return Focus(
        focusNode: _focusNode,
        canRequestFocus: visible,
        skipTraversal: !visible,
        onKeyEvent: _onKey,
        child: Container(
        padding: const EdgeInsets.fromLTRB(48, 24, 48, 28),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Color(0xD9000000)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.controller.isLive)
              Obx(
                () => ProgressBar(
                  progress: widget.controller.progress,
                  buffered: widget.controller.buffered.value,
                  total: widget.controller.duration.value,
                  progressBarColor: colorScheme.primary,
                  baseBarColor: const Color(0x40FFFFFF),
                  bufferedBarColor:
                      colorScheme.primary.withValues(alpha: 0.4),
                  thumbColor: colorScheme.primary,
                  thumbGlowColor:
                      colorScheme.primary.withValues(alpha: 0.3),
                  barHeight: 6,
                  thumbRadius: 10,
                  thumbGlowRadius: 30,
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
            const SizedBox(height: 16),
            Row(
              children: [
                for (var i = 0; i < _actions.length; i++)
                  _TvControlButton(
                    icon: _actions[i].icon,
                    focused: i == _index,
                    size: i == 0 ? 40 : 32,
                    onTap: _actions[i].onTap,
                  ),
                const SizedBox(width: 20),
                Obx(
                  () => Text(
                    '${DurationUtils.formatDuration(widget.controller.position.value)}'
                    ' / ${DurationUtils.formatDuration(widget.controller.duration.value)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      );
    });
  }
}

class _TvAction {
  const _TvAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _TvControlButton extends StatelessWidget {
  const _TvControlButton({
    required this.icon,
    required this.focused,
    required this.onTap,
    this.size = 32,
  });

  final IconData icon;
  final bool focused;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: size + 28,
          height: size + 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: focused ? 0.28 : 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: focused ? Colors.white : Colors.transparent,
              width: 2,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: size),
        ),
      ),
    );
  }
}
