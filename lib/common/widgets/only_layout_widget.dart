import 'package:flutter/rendering.dart' show RenderProxyBox;
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

typedef LayoutCallback = void Function(Size size);

class OnlyLayoutWidget extends SingleChildRenderObjectWidget {
  const OnlyLayoutWidget({
    super.key,
    super.child,
    required this.onPerformLayout,
  });

  final LayoutCallback onPerformLayout;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      NoRenderLayoutBox(onPerformLayout: onPerformLayout);

  @override
  void updateRenderObject(
    BuildContext context,
    NoRenderLayoutBox renderObject,
  ) {
    super.updateRenderObject(context, renderObject);
    renderObject.onPerformLayout = onPerformLayout;
  }
}

class NoRenderLayoutBox extends RenderProxyBox {
  NoRenderLayoutBox({required this.onPerformLayout});

  LayoutCallback onPerformLayout;

  Size? _lastSize;

  @override
  void performLayout() {
    super.performLayout();
    // 仅在尺寸变化时回调，避免「布局→setState→布局」的每帧循环。
    final currentSize = size;
    if (currentSize != _lastSize) {
      _lastSize = currentSize;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        onPerformLayout(currentSize);
      });
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {}
}
