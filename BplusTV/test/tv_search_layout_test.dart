import 'package:bplus_tv/tv/search/tv_search_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tvKeyboardWidthFor', () {
    test('宽屏使用紧凑的 TV 键盘比例', () {
      expect(tvKeyboardWidthFor(1280), closeTo(399.04, 0.01));
      expect(tvKeyboardWidthFor(1920), 400);
    });

    test('空间充足时为键盘保留 320dp', () {
      expect(tvKeyboardWidthFor(900), 320);
    });

    test('shrinks the keyboard on narrow windows', () {
      expect(tvKeyboardWidthFor(720), 320);
      expect(tvKeyboardWidthFor(600), 267);
    });

    test('never starves the suggestion columns below 300dp', () {
      for (final width in [600.0, 720.0, 900.0, 1080.0, 1280.0, 1920.0]) {
        final available = width - 33;
        expect(
          available - tvKeyboardWidthFor(width),
          greaterThanOrEqualTo(300.0 - 0.01),
          reason: 'maxWidth $width leaves the suggestion columns too narrow',
        );
      }
    });
  });
}
