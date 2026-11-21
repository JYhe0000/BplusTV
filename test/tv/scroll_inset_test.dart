import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_focus_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('向上切换到可见卡片不滚动，被顶栏遮挡时才显现', (tester) async {
    final nodes = List.generate(20, (_) => FocusNode());
    final scroll = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 400,
            height: 320,
            child: FocusTraversalGroup(
              policy: TvFocusTraversalPolicy(),
              child: TvScrollInset(
                top: 40,
                child: GridView.builder(
                  controller: scroll,
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisExtent: 100,
                  ),
                  itemCount: nodes.length,
                  itemBuilder: (context, index) => TvFocusCard(
                    focusNode: nodes[index],
                    child: const ColoredBox(color: Colors.blue),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    scroll.jumpTo(150);
    await tester.pump();
    nodes[3].requestFocus();
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(nodes[2].hasPrimaryFocus, isTrue);
    expect(scroll.offset, 150);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(nodes[1].hasPrimaryFocus, isTrue);
    expect(scroll.offset, closeTo(60, 0.01));

    await tester.pumpWidget(const SizedBox());
    scroll.dispose();
    for (final node in nodes) {
      node.dispose();
    }
  });
}
