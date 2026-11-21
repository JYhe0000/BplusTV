import 'package:bplus_tv/common/widgets/only_layout_widget.dart';
import 'package:material_ui/material_ui.dart';

class SelfSizedHorizontalList extends StatefulWidget {
  const SelfSizedHorizontalList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.separatorBuilder,
    this.controller,
    this.padding,
  });

  final int itemCount;
  final EdgeInsets? padding;
  final IndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder separatorBuilder;
  final ScrollController? controller;

  @override
  State<SelfSizedHorizontalList> createState() =>
      _SelfSizedHorizontalListState();
}

class _SelfSizedHorizontalListState extends State<SelfSizedHorizontalList> {
  double? _height;
  double? _textScale;

  @override
  void didUpdateWidget(covariant SelfSizedHorizontalList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // itemBuilder / padding 变化会导致首项尺寸变化，需重新测量高度。
    if (oldWidget.itemBuilder != widget.itemBuilder ||
        oldWidget.padding != widget.padding) {
      _height = null;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // 文字缩放变化会改变首项高度，需失效缓存。
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    if (_textScale != textScale) {
      _textScale = textScale;
      _height = null;
    }
    if (_height == null) {
      if (widget.itemCount == 0) {
        return const SizedBox.shrink();
      }
      return OnlyLayoutWidget(
        onPerformLayout: (Size size) {
          if (!mounted) return;
          _height = size.height;
          setState(() {});
        },
        child: Padding(
          padding: widget.padding ?? .zero,
          child: widget.itemBuilder(context, 0),
        ),
      );
    }

    return SizedBox(
      height: _height,
      child: ListView.separated(
        scrollDirection: .horizontal,
        padding: widget.padding,
        itemCount: widget.itemCount,
        controller: widget.controller,
        itemBuilder: widget.itemBuilder,
        separatorBuilder: widget.separatorBuilder,
      ),
    );
  }
}
