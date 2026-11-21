import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:material_ui/material_ui.dart';

abstract final class DynLayout {
  static const double compactWidth = 790;
  static const double wideWidth = 1280;
  static const double maxReadingWidth = 1120;
  static const double maxDetailWidth = 1480;
  static const double maxComposerWidth = 1040;

  static double bodyFontSize(
    double width, {
    required bool isDetail,
    required int floor,
    bool isSave = false,
  }) {
    final baseSize = floor > 1
        ? 16.0
        : isDetail && !isSave
        ? 20.0
        : isSave
        ? 15.0
        : 18.0;
    if (!isSave && width >= 700) return baseSize + 2;
    return baseSize;
  }

  static double lineHeight(double width) => width < compactWidth ? 1.48 : 1.5;
}

class DynPageContent extends StatelessWidget {
  const DynPageContent({
    super.key,
    required this.child,
    this.maxWidth = DynLayout.maxComposerWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
}

class DynFocusAction extends StatelessWidget {
  const DynFocusAction({super.key, required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => TvFocusable(
    canRequestFocus: onTap != null,
    onTap: onTap,
    builder: (context, focused, hovered) => TvFocusHighlight(
      focused: focused,
      radius: 12,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: child,
      ),
    ),
  );
}

class DynToolbarTarget extends StatelessWidget {
  const DynToolbarTarget({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 48,
    child: FittedBox(child: child),
  );
}
