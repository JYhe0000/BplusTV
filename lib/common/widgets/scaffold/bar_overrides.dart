import 'package:bplus_tv/common/widgets/netflix_style.dart';
import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/common/widgets/smartisan/smartisan_style.dart';
import 'package:bplus_tv/common/widgets/view_safe_area.dart';
import 'package:bplus_tv/smartisan/smartisan_bars.dart' show SmartisanBarShadow;
import 'package:material_ui/material_ui.dart';

/// 统一外壳材质，同时保留原 AppBar 的返回、交互标题和底部栏。
Widget overrideAppbar(BuildContext context, Widget? appBar) {
  if (appBar is AppBar) {
    final theme = Theme.of(context);
    final smartisan = SmartisanStyle.of(context);
    final defaultSurface = !smartisan && appBar.backgroundColor == null;
    final focusTarget = const Size.square(TvShellMetrics.minimumFocusTarget);
    final focusColor = theme.colorScheme.primary.withValues(alpha: 0.18);
    final iconStyle =
        IconButton.styleFrom(
          minimumSize: focusTarget,
          visualDensity: VisualDensity.standard,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.focused)) return focusColor;
            return theme.iconButtonTheme.style?.overlayColor?.resolve(states);
          }),
        );
    final textStyle =
        TextButton.styleFrom(
          minimumSize: focusTarget,
          visualDensity: VisualDensity.standard,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.focused)) return focusColor;
            return theme.textButtonTheme.style?.overlayColor?.resolve(states);
          }),
        );
    return Theme(
      data: theme.copyWith(
        focusColor: focusColor,
        iconButtonTheme: IconButtonThemeData(
          style: theme.iconButtonTheme.style?.merge(iconStyle) ?? iconStyle,
        ),
        textButtonTheme: TextButtonThemeData(
          style: theme.textButtonTheme.style?.merge(textStyle) ?? textStyle,
        ),
        appBarTheme: theme.appBarTheme.copyWith(
          backgroundColor: defaultSurface ? Colors.transparent : null,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      child: defaultSurface
          ? NetflixSurface(
              radius: NetflixStyle.panelRadius,
              child: appBar,
            )
          : smartisan
          ? Stack(
              clipBehavior: Clip.none,
              children: [
                appBar,
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: -14,
                  child: IgnorePointer(
                    child: SmartisanBarShadow(height: 14),
                  ),
                ),
              ],
            )
          : appBar,
    );
  }
  return appBar ?? const SizedBox(width: double.infinity);
}
