import 'package:bplus_tv/tv/tv_constants.dart';
import 'package:flutter/widgets.dart';

/// A fixed paint gutter outside a scrollable's reveal/layout bounds.
///
/// The child scrollable must use Clip.none: its focused cards may paint into
/// this gutter, but the outer clip still keeps content out of adjacent bars.
/// Unlike SliverPadding, this space survives scrolling to any middle row.
class TvFocusViewport extends StatelessWidget {
  const TvFocusViewport({
    super.key,
    required this.maxCardSize,
    required this.child,
  });

  final Size maxCardSize;
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: TvConstants.focusPaintOutset(maxCardSize.width),
        vertical: TvConstants.focusPaintOutset(maxCardSize.height),
      ),
      child: child,
    ),
  );
}
