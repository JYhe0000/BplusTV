import 'package:bplus_tv/pages/common/common_intro_controller.dart';
import 'package:bplus_tv/plugin/pl_player/controller.dart';
import 'package:flutter/services.dart'
    show KeyDownEvent, KeyRepeatEvent, LogicalKeyboardKey;
import 'package:material_ui/material_ui.dart';

class PlayerFocus extends StatefulWidget {
  const PlayerFocus({
    super.key,
    required this.child,
    required this.plPlayerController,
    this.introController,
    required this.onSendDanmaku,
    this.canPlay,
    this.onSkipSegment,
    this.onRefresh,
    this.onOpenPanel,
    this.onClosePanel,
    this.panelOpen = false,
    this.autofocus = false,
  });

  /// 初始焦点由播放器内的 TV 遥控器处理器接管，避免多个 autofocus 竞争。
  final bool autofocus;
  final Widget child;
  final PlPlayerController plPlayerController;
  final CommonIntroController? introController;
  final VoidCallback onSendDanmaku;
  final ValueGetter<bool>? canPlay;
  final ValueGetter<bool>? onSkipSegment;
  final VoidCallback? onRefresh;
  final VoidCallback? onOpenPanel;

  /// 关闭由向下键打开的选集面板。
  final VoidCallback? onClosePanel;

  /// 面板打开时，让方向键遍历面板内的控件。
  final bool panelOpen;

  @override
  State<PlayerFocus> createState() => _PlayerFocusState();

  static bool _shouldHandle(LogicalKeyboardKey logicalKey) {
    return logicalKey == LogicalKeyboardKey.arrowLeft ||
        logicalKey == LogicalKeyboardKey.arrowRight ||
        logicalKey == LogicalKeyboardKey.arrowUp ||
        logicalKey == LogicalKeyboardKey.arrowDown;
  }

  bool get hasPlayer => plPlayerController.videoPlayerController != null;

  bool _handleKey(KeyEvent event) {
    final key = event.logicalKey;
    switch (key) {
      case LogicalKeyboardKey.mediaPlayPause:
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
      case LogicalKeyboardKey.gameButtonA:
        if (event is! KeyDownEvent) return true;
        if (canPlay != null && !canPlay!()) return true;
        // 控制条内的确认键由按钮先处理；这里处理播放器和海报上的确认键。
        if (hasPlayer) {
          plPlayerController.onDoubleTapCenter();
          if (!panelOpen) {
            plPlayerController.controls = true;
          }
        }
        return true;
      case LogicalKeyboardKey.arrowUp:
        if (event is! KeyDownEvent) return false;
        if (panelOpen) {
          if (onClosePanel != null) {
            onClosePanel!();
            return true;
          }
          return false;
        }
        if (!plPlayerController.showControls.value) {
          plPlayerController.controls = true;
          return true;
        }
        return false;
      case LogicalKeyboardKey.arrowDown:
        if (event is! KeyDownEvent) return false;
        if (plPlayerController.showControls.value) {
          plPlayerController.controls = false;
          return true;
        }
        if (onOpenPanel != null) {
          onOpenPanel!();
          return true;
        }
        return false;
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.mediaFastForward:
        if ((event is KeyDownEvent || event is KeyRepeatEvent) &&
            hasPlayer &&
            !plPlayerController.isLive) {
          plPlayerController.onForward(
            plPlayerController.fastForBackwardDuration,
          );
        }
        return true;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.mediaRewind:
        if ((event is KeyDownEvent || event is KeyRepeatEvent) &&
            hasPlayer &&
            !plPlayerController.isLive) {
          plPlayerController.onBackward(
            plPlayerController.fastForBackwardDuration,
          );
        }
        return true;
      case LogicalKeyboardKey.mediaTrackNext:
        if (event is KeyDownEvent && !plPlayerController.isLive) {
          introController?.nextPlay();
        }
        return true;
      case LogicalKeyboardKey.mediaTrackPrevious:
        if (event is KeyDownEvent && !plPlayerController.isLive) {
          introController?.prevPlay();
        }
        return true;
      case LogicalKeyboardKey.mediaStop:
        if (event is KeyDownEvent && hasPlayer) {
          plPlayerController.onDoubleTapCenter();
        }
        return true;
      case LogicalKeyboardKey.goBack:
      case LogicalKeyboardKey.escape:
      case LogicalKeyboardKey.browserBack:
        // 第一次返回收起控制条，控制条隐藏后再交给页面处理返回。
        if (event is KeyDownEvent && plPlayerController.showControls.value) {
          plPlayerController.controls = false;
          return true;
        }
        return false;
    }
    return false;
  }
}

class _PlayerFocusState extends State<PlayerFocus> {
  final FocusNode _focusNode = FocusNode(
    debugLabel: 'PlayerFocus',
    skipTraversal: true,
  );

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: (node, event) {
        final key = event.logicalKey;
        final isUpDown =
            key == LogicalKeyboardKey.arrowUp ||
            key == LogicalKeyboardKey.arrowDown;
        if ((widget.plPlayerController.showControls.value ||
                widget.panelOpen) &&
            PlayerFocus._shouldHandle(key) &&
            !(isUpDown && FocusManager.instance.primaryFocus == _focusNode)) {
          return KeyEventResult.ignored;
        }
        final handled = widget._handleKey(event);
        if (handled || PlayerFocus._shouldHandle(key)) {
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: widget.child,
    );
  }
}
