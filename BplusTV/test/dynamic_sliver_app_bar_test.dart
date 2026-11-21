import 'package:bplus_tv/common/widgets/dynamic_sliver_app_bar/dynamic_sliver_app_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Regression test: the member page header is a pinned-only
/// [DynamicSliverAppBar] whose toolbar box is exactly
/// `topPadding + kToolbarHeight` tall. Its delegate must never report
/// `minExtent > maxExtent` (trips `FlexibleSpaceBarSettings` asserts in
/// debug, which the framework then turns into an `ErrorWidget` sitting
/// directly in the outer viewport -> "RenderErrorBox did not match the
/// expected child type").
Widget _page(String title) {
  return MaterialApp(
    home: Scaffold(
      body: CustomScrollView(
        slivers: [
          DynamicSliverAppBar.medium(
            title: Text(title),
            flexibleSpace: const SizedBox.shrink(),
          ),
          SliverList.builder(
            itemCount: 50,
            itemBuilder: (_, index) => SizedBox(
              height: 40,
              child: Text('item $index'),
            ),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('header survives rebuild after layout (update path)', (
    tester,
  ) async {
    await tester.pumpWidget(_page('one'));
    // First layout measures the finite maxExtent of the pinned header.
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Rebuilding the page updates the existing header element, which calls
    // the delegate's build() with the measured finite maxExtent. This must
    // not throw (used to trip `minExtent <= maxExtent`).
    await tester.pumpWidget(_page('two'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('two'), findsOneWidget);
  });

  testWidgets('header survives scroll after layout', (tester) async {
    await tester.pumpWidget(_page('one'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.drag(find.text('item 0'), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
