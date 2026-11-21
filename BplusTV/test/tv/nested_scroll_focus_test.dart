import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_focus_card.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('嵌套主页连续上下导航保留焦点，卡片显现在分类栏下方', (tester) async {
    final nestedKey = GlobalKey<ExtendedNestedScrollViewState>();
    final gridKey = GlobalKey();
    final nodes = List.generate(40, (_) => FocusNode());

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 600,
            height: 400,
            child: FocusTraversalGroup(
              policy: TvFocusTraversalPolicy(),
              child: ExtendedNestedScrollView(
                key: nestedKey,
                onlyOneScrollInBody: true,
                pinnedHeaderSliverHeightBuilder: () => kToolbarHeight,
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  const SliverAppBar(pinned: true, title: Text('用户主页')),
                  const SliverToBoxAdapter(child: SizedBox(height: 160)),
                ],
                body: Column(
                  children: [
                    const SizedBox(height: 48, child: Text('投稿分类')),
                    Expanded(
                      child: GridView.builder(
                        key: gridKey,
                        padding: EdgeInsets.zero,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisExtent: 100,
                            ),
                        itemCount: nodes.length,
                        itemBuilder: (context, index) => TvFocusCard(
                          focusNode: nodes[index],
                          child: Text('视频 $index'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    nodes.first.requestFocus();
    await tester.pumpAndSettle();

    Future<void> move(LogicalKeyboardKey key, int index) async {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
      expect(nodes[index].hasPrimaryFocus, isTrue);
      final target = find.byWidgetPredicate(
        (widget) => widget is TvFocusCard && widget.focusNode == nodes[index],
      );
      final rect = tester.getRect(target);
      final viewport = tester.getRect(find.byKey(gridKey));
      expect(rect.top, greaterThanOrEqualTo(viewport.top - 0.5));
      expect(rect.bottom, lessThanOrEqualTo(viewport.bottom + 0.5));
      expect(tester.takeException(), isNull);
    }

    for (var index = 2; index <= 20; index += 2) {
      await move(LogicalKeyboardKey.arrowDown, index);
    }
    expect(nestedKey.currentState!.outerController.offset, greaterThan(0));
    expect(nestedKey.currentState!.innerController.offset, greaterThan(0));
    for (var index = 18; index >= 0; index -= 2) {
      await move(LogicalKeyboardKey.arrowUp, index);
    }
    expect(nestedKey.currentState!.innerController.offset, closeTo(0, 0.5));

    await tester.pumpWidget(const SizedBox());
    for (final node in nodes) {
      node.dispose();
    }
  });
}
