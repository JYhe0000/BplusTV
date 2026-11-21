import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:bplus_tv/common/widgets/custom_icon.dart';
import 'package:bplus_tv/common/widgets/extra_hittest_stack.dart';
import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/models_new/live/live_superchat/item.dart';
import 'package:bplus_tv/pages/live_room/superchat/superchat_card.dart';
import 'package:bplus_tv/plugin/pl_player/utils/fullscreen.dart';
import 'package:bplus_tv/tv/tv_page_focus.dart';
import 'package:bplus_tv/tv/tv_back_bar.dart';
import 'package:bplus_tv/utils/storage.dart';
import 'package:bplus_tv/utils/storage_key.dart';
import 'package:bplus_tv/utils/storage_pref.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

const kFullScreenSCWidth = 255.0;

class FullScreenScSize extends StatefulWidget {
  const FullScreenScSize({super.key});

  @override
  State<FullScreenScSize> createState() => _FullScreenScSizeState();
}

class _FullScreenScSizeState extends State<FullScreenScSize> {
  double _width = Pref.fullScreenSCWidth;
  final _randomSC = SuperChatItem.random;
  late EdgeInsets _padding;
  late ColorScheme _colorScheme;
  final FocusNode _handleFocusNode = FocusNode();
  bool _handleFocused = false;

  @override
  void initState() {
    super.initState();
    _handleFocusNode.addListener(() {
      setState(() => _handleFocused = _handleFocusNode.hasFocus);
    });
    if (Platform.isAndroid) {
      landscapeLeftMode();
    }
  }

  @override
  void dispose() {
    _handleFocusNode.dispose();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final padding = MediaQuery.viewPaddingOf(context);
    _padding = .only(
      right: padding.right + 17,
      left: padding.left + 25,
      bottom: padding.bottom + 25,
    );
    _colorScheme = ColorScheme.of(context);
  }

  void _onReset() {
    _width = kFullScreenSCWidth;
    GStorage.setting.delete(SettingBoxKey.fullScreenSCWidth);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final content = SimpleScaffold(
      appBar: tvBackBar(
        actions: [
          TextButton(onPressed: _onReset, child: const Text('重置')),
        ],
      ),
      body: Padding(padding: _padding, child: _buildBody),
    );
    return TvPageFocus(child: content);
  }

  Widget get _buildBody {
    return Align(
      alignment: .bottomLeft,
      child: ExtraHitTestStack(
        clipBehavior: .none,
        children: [
          SizedBox(
            width: _width,
            child: IgnorePointer(
              child: SuperChatCard(
                item: _randomSC,
                persistentSC: true,
              ),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: -17,
            width: 34,
            child: _buildTvHandle,
          ),
        ],
      ),
    );
  }

  Widget get _buildTvHandle {
    return Focus(
      focusNode: _handleFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        return switch (event.logicalKey) {
          LogicalKeyboardKey.arrowLeft => _onTvResize(-5),
          LogicalKeyboardKey.arrowRight => _onTvResize(5),
          _ => KeyEventResult.ignored,
        };
      },
      child: _buildHandleIcon(_handleFocused),
    );
  }

  KeyEventResult _onTvResize(double delta) {
    _width = math.max(25.0, _width + delta);
    GStorage.setting.put(SettingBoxKey.fullScreenSCWidth, _width);
    setState(() {});
    return KeyEventResult.handled;
  }

  Widget _buildHandleIcon(bool focused) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: .circle,
        color: focused
            ? _colorScheme.primary.withValues(alpha: .9)
            : _colorScheme.secondaryContainer.withValues(alpha: .8),
        border: focused
            ? Border.all(
                color: _colorScheme.onPrimary,
                width: 2,
              )
            : null,
      ),
      child: Icon(
        size: 18,
        CustomIcons.open_in_full_rotate_45,
        color: focused
            ? _colorScheme.onPrimary
            : _colorScheme.onSecondaryContainer,
      ),
    );
  }
}
