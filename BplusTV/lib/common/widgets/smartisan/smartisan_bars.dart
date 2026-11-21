import 'package:bplus_tv/smartisan/smartisan_icons.dart';
import 'package:bplus_tv/smartisan/smartisan_bars.dart' as kit;
import 'package:bplus_tv/smartisan/smartisan_motion.dart';
import 'package:bplus_tv/smartisan/smartisan_palette.dart';
import 'package:bplus_tv/smartisan/smartisan_theme.dart';
import 'package:bplus_tv/smartisan/smartisan_widgets.dart' show SIcon;
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class SmartisanAppbar extends StatelessWidget implements PreferredSizeWidget {
  const SmartisanAppbar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.onBack,
    this.showBack,
    this.autoBack = true,
  });

  factory SmartisanAppbar.fromMaterial(AppBar appBar, {Key? key}) =>
      SmartisanAppbar(
        key: key,
        title: appBar.title,
        actions: appBar.actions,
        leading: appBar.leading,
        autoBack: appBar.automaticallyImplyLeading,
      );

  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final VoidCallback? onBack;
  final bool? showBack;
  final bool autoBack;

  static const double barHeight = SDims.appBar;
  static const double fadeHeight = 14;

  @override
  Size get preferredSize => const Size.fromHeight(barHeight + fadeHeight);

  @override
  Widget build(BuildContext context) {
    final p = SPalette.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final backOn =
        showBack ??
        (leading != null || (autoBack && Navigator.of(context).canPop()));
    final back = leading ?? (backOn ? _back(context, p) : null);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: p.isDark ? .light : .dark,
        statusBarBrightness: p.isDark ? .dark : .light,
      ),
      child: ColoredBox(
        color: p.appBar,
        child: Column(
          mainAxisSize: .min,
          children: [
            if (top > 0) SizedBox(height: top),
            SizedBox(
              height: barHeight,
              child: IconTheme(
                data: IconThemeData(color: p.icon, size: 22),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      children: [
                        if (back != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: SizedBox(
                              width: 40,
                              height: barHeight,
                              child: Center(child: back),
                            ),
                          ),
                        const Spacer(),
                        if (actions case final list? when list.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: Row(
                              mainAxisSize: .min,
                              children: [for (final w in list) w],
                            ),
                          ),
                      ],
                    ),
                    if (title != null)
                      IgnorePointer(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 56),
                          child: DefaultTextStyle(
                            style: SText.barTitle.copyWith(
                              color: p.titleOther,
                            ),
                            textAlign: .center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            child: title!,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const kit.SmartisanBarShadow(height: fadeHeight),
          ],
        ),
      ),
    );
  }

  Widget _back(BuildContext context, SPalette p) =>
      SmartisanBackButton(onBack: onBack ?? Get.back);
}

/// Smartisan back chevron for top bars: the glyph darkens and pops to 1.33x
/// while held (R2 playBarIconScaleAnim); on TV the focus itself drives it.
class SmartisanBackButton extends StatelessWidget {
  const SmartisanBackButton({super.key, this.onBack, this.size = 20});

  final VoidCallback? onBack;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = SPalette.of(context);
    VoidCallback back() => onBack ?? Get.back;
    return TvFocusable(
      onTap: back,
      builder: (context, focused, hovered) =>
          _glyph(p, focused, focused ? p.icon : p.titleOther),
    );
  }

  Widget _glyph(SPalette p, bool active, Color color) {
    return Semantics(
      button: true,
      label: '返回',
      child: TvFocusHighlight(
        focused: active,
        radius: 12,
        borderWidth: 1.5,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.borderButton),
          ),
          child: AnimatedScale(
            scale: active ? SMotion.barIconScale : 1,
            duration: SMotion.barIconSpring,
            curve: Curves.easeOutBack,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: SIcon(
                SIcons.back,
                size: size,
                color: active
                    ? Color.lerp(color, const Color(0xFF000000), 0.35)
                    : color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SmartisanNavBarItem {
  const SmartisanNavBarItem({
    required this.icon,
    required this.label,
    Widget? selectedIcon,
  }) : selectedIcon = selectedIcon ?? icon;

  final Widget icon;
  final Widget selectedIcon;
  final String label;
}

class SmartisanBottomNav extends StatelessWidget {
  const SmartisanBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<SmartisanNavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final p = SPalette.of(context);
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      color: p.card,
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: SDims.bottomNav,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _item(context, i, items[i], currentIndex == i, p),
              ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    int index,
    SmartisanNavBarItem item,
    bool selected,
    SPalette p,
  ) {
    final color = selected ? p.brandSelected : p.iconDisabled;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: .center,
        spacing: 2,
        children: [
          SizedBox(
            height: 28,
            child: IconTheme.merge(
              data: IconThemeData(size: selected ? 28 : 22, color: color),
              child: selected ? item.selectedIcon : item.icon,
            ),
          ),
          Text(
            item.label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 8,
              fontWeight: .w400,
              color: color,
              fontFamilyFallback: SText.fallback,
            ),
          ),
        ],
      ),
    );
  }
}
