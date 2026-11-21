import 'package:bplus_tv/tv/tv_focus_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('焦点动画复用卡片内容绘制，确认键及失焦通知仍正常', (
    tester,
  ) async {
    final first = FocusNode();
    final second = FocusNode();
    var paints = 0;
    var activations = 0;
    final changes = <bool>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TvFocusCard(
                focusNode: first,
                onTap: () => activations++,
                onFocusChange: changes.add,
                child: CustomPaint(
                  size: const Size(160, 90),
                  painter: _CountingPainter(() => paints++),
                ),
              ),
              const SizedBox(width: 20),
              TvFocusCard(
                focusNode: second,
                child: const SizedBox(width: 160, height: 90),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    second.requestFocus();
    await tester.pumpAndSettle();
    changes.clear();
    final initialPaints = paints;
    expect(initialPaints, greaterThan(0));

    first.requestFocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpAndSettle();
    expect(first.hasPrimaryFocus, isTrue);
    expect(paints, initialPaints);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(activations, 1);
    second.requestFocus();
    await tester.pumpAndSettle();
    expect(changes, [true, false]);
    expect(paints, initialPaints);

    await tester.pumpWidget(const SizedBox());
    first.dispose();
    second.dispose();
  });
}

class _CountingPainter extends CustomPainter {
  _CountingPainter(this.onPaint);

  final VoidCallback onPaint;

  @override
  void paint(Canvas canvas, Size size) {
    onPaint();
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.blue);
  }

  @override
  bool shouldRepaint(_CountingPainter oldDelegate) => false;
}
