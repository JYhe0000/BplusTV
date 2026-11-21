import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart';

const Set<PointerDeviceKind> _dragDevices = {
  .touch,
  .stylus,
  .invertedStylus,
  .unknown,
};

class CustomScrollBehavior extends MaterialScrollBehavior {
  const CustomScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => StretchingOverscrollIndicator(
    axisDirection: details.direction,
    clipBehavior: details.decorationClipBehavior ?? .hardEdge,
    child: child,
  );

  @override
  Set<PointerDeviceKind> get dragDevices => _dragDevices;
}

class NoOverscrollIndicator extends CustomScrollBehavior {
  const NoOverscrollIndicator();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
