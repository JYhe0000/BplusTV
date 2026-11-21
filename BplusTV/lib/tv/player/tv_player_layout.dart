import 'package:material_ui/material_ui.dart';

/// 向控制栏传递播放器的实际尺寸，避免用整块屏幕判断嵌入式播放器。
class TvPlayerLayout extends InheritedWidget {
  const TvPlayerLayout({
    super.key,
    required this.size,
    required super.child,
  });

  final Size size;

  static Size? maybeSizeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TvPlayerLayout>()?.size;

  @override
  bool updateShouldNotify(TvPlayerLayout oldWidget) => size != oldWidget.size;
}
