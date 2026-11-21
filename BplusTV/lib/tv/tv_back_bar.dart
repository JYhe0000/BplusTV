import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/common/widgets/smartisan/smartisan_bars.dart';
import 'package:bplus_tv/common/widgets/smartisan/smartisan_style.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/utils/storage_pref.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

/// TV 专属顶栏：透明底，只留最左侧返回圆钮（与其他 bar 按钮同规范），
/// 需要时可带右侧 [actions]（功能性按钮保留）。
PreferredSizeWidget tvBackBar({List<Widget>? actions}) {
  return _TvBackBar(actions: actions);
}

class _TvBackBar extends StatelessWidget implements PreferredSizeWidget {
  const _TvBackBar({this.actions});

  final List<Widget>? actions;

  @override
  Size get preferredSize => Size.fromHeight(
    Pref.uiStyle.isSmartisan ? SmartisanAppbar.barHeight + 14 : 56,
  );

  @override
  Widget build(BuildContext context) {
    final smartisan = SmartisanStyle.of(context);
    if (smartisan) {
      return SmartisanAppbar(showBack: true, actions: actions);
    }
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leading: const TvBackButton(),
      leadingWidth: 60,
      actions: actions,
    );
  }
}

/// 没有 AppBar 的全屏页面使用此左上返回按钮。
class TvBackOverlay extends StatelessWidget {
  const TvBackOverlay({super.key, this.padding = const EdgeInsets.all(24)});

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: padding,
          child: const SizedBox(width: 60, height: 56, child: TvBackButton()),
        ),
      ),
    );
  }
}

/// 放在滚动页首项的返回按钮，遥控器导航时作为第一个焦点目标。
class TvBackRow extends StatelessWidget {
  const TvBackRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 60,
        height: 56,
        child: TvBackButton(alignment: Alignment.centerLeft),
      ),
    );
  }
}

/// 48px 返回按钮 + 22px 图标。
class TvBackButton extends StatelessWidget {
  const TvBackButton({
    super.key,
    this.alignment = Alignment.center,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    this.tooltip = '返回',
  });

  final AlignmentGeometry alignment;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool autofocus;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Tooltip(
        message: tooltip,
        child: Semantics(
          button: true,
          label: tooltip,
          child: TvFocusable(
            focusNode: focusNode,
            autofocus: autofocus,
            onTap: onTap ?? Get.back,
            focusRadius: 12,
            builder: (context, focused, hovered) => TvFocusHighlight(
              focused: focused,
              radius: 12,
              borderWidth: 2,
              child: netflixSurface(
                radius: 12,
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: const Icon(Icons.arrow_back, size: 22),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
