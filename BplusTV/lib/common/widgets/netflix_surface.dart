import 'package:bplus_tv/common/widgets/netflix_style.dart';
import 'package:bplus_tv/common/widgets/smartisan/smartisan_surface.dart';
import 'package:bplus_tv/common/widgets/smartisan/smartisan_style.dart';
import 'package:material_ui/material_ui.dart';

/// 卡片、弹窗和输入区域共用的实色面板。
Widget netflixSurface({
  required Widget child,
  double radius = NetflixStyle.radius,
  Color? color,
}) => NetflixSurface(child: child, radius: radius, color: color);

/// 导航区域共用的实色面板。
Widget netflixNavSurface({
  required Widget child,
  double radius = NetflixStyle.navRadius,
  Color? color,
}) => NetflixSegment(child: child, radius: radius, color: color);

/// 视频上方的深色控制面板。
Widget netflixPlayerSurface({
  required Widget child,
  double radius = NetflixStyle.radius,
  Color? color,
}) => NetflixPlayerSurface(child: child, radius: radius, color: color);

class NetflixSurface extends StatelessWidget {
  const NetflixSurface({
    super.key,
    required this.child,
    this.radius = NetflixStyle.radius,
    this.color,
    this.nav = false,
  });

  final Widget child;
  final double radius;
  final Color? color;
  final bool nav;

  @override
  Widget build(BuildContext context) {
    if (SmartisanStyle.of(context)) {
      return SmartisanSurface(
        radius: radius,
        color: color,
        nav: nav,
        child: child,
      );
    }
    return Material(
      color: color ?? (nav ? NetflixStyle.nav : NetflixStyle.surface),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: const BorderSide(color: NetflixStyle.stroke),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// 独立导航区块，无需额外图层或祖先组件。
class NetflixSegment extends StatelessWidget {
  const NetflixSegment({
    super.key,
    required this.child,
    this.radius = NetflixStyle.navRadius,
    this.color,
  });

  final Widget child;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) => NetflixSurface(
    radius: radius,
    color: color,
    nav: true,
    child: child,
  );
}

/// 用不透明深色确保亮色视频上的控制内容清晰可读。
class NetflixPlayerSurface extends StatelessWidget {
  const NetflixPlayerSurface({
    super.key,
    required this.child,
    this.radius = NetflixStyle.radius,
    this.color,
  });

  final Widget child;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) => NetflixSurface(
    radius: radius,
    color: color,
    child: child,
  );
}
