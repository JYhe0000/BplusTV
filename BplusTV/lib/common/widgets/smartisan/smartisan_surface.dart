import 'package:bplus_tv/common/widgets/smartisan/smartisan_style.dart';
import 'package:material_ui/material_ui.dart';

/// A Smartisan-style grouped panel.
///
/// One white (or dark) rectangle, 10dp radius, a 0.8dp hairline stroke and a
/// very shallow 4% shadow. No blur, no refraction and no large gradient — the
/// surface is deliberately opaque so the grey striped page stays the only
/// background layer.
class SmartisanSurface extends StatelessWidget {
  const SmartisanSurface({
    super.key,
    required this.child,
    this.radius = SmartisanStyle.cardRadius,
    this.color,
    this.strokeColor,
    this.shadows,
    this.clip = true,
    this.nav = false,
  });

  final Widget child;

  /// Smartisan 卡片默认圆角为 10，限制传入值以保持卡片风格。
  final double radius;

  final Color? color;
  final Color? strokeColor;
  final List<BoxShadow>? shadows;
  final bool clip;

  /// Navigation rail/bar: slightly rounder, no outer shadow (it sits on the
  /// page edge).
  final bool nav;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = nav ? 12.0 : radius.clamp(6.0, 14.0);
    final fill = color ?? SmartisanStyle.cardOf(theme.brightness);
    final stroke = strokeColor ?? SmartisanStyle.strokeOf(theme.brightness);
    final shadowList =
        shadows ?? (nav ? const <BoxShadow>[] : SmartisanStyle.cardShadow);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        boxShadow: shadowList,
      ),
      child: Material(
        color: fill,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(r),
          side: BorderSide(color: stroke, width: SmartisanStyle.hairline),
        ),
        clipBehavior: clip ? Clip.antiAlias : Clip.none,
        child: child,
      ),
    );
  }
}

/// 输入框和播放器控制区使用的页面色实底面板。
class SmartisanFlatSurface extends StatelessWidget {
  const SmartisanFlatSurface({
    super.key,
    required this.child,
    this.radius = SmartisanStyle.cardRadius,
    this.color,
  });

  final Widget child;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Material(
      color: color ?? SmartisanStyle.pageOf(brightness),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius.clamp(4.0, 20.0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
