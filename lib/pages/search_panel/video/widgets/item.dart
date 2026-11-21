import 'package:bplus_tv/common/widgets/badge.dart';
import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/common/widgets/video_card/video_card_h.dart'
    show pushVideoH;
import 'package:bplus_tv/models/search/result.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/utils/date_utils.dart';
import 'package:bplus_tv/utils/duration_utils.dart';
import 'package:bplus_tv/utils/num_utils.dart';
import 'package:material_ui/material_ui.dart';

/// 搜索分栏使用固定阅读比例，不根据卡片高度反向扩大封面。
class SearchVideoResultItem extends StatelessWidget {
  const SearchVideoResultItem({
    super.key,
    required this.item,
    required this.tileWidth,
  });

  final SearchVideoItemModel item;
  final double tileWidth;

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.all(12);
    final coverWidth = ((tileWidth - padding.horizontal) * 0.38).clamp(
      0.0,
      220.0,
    );
    final colors = ColorScheme.of(context);
    final content = NetflixSegment(
      radius: 16,
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                NetworkImgLayer(
                  src: item.cover,
                  width: coverWidth,
                  height: coverWidth * 9 / 16,
                  borderRadius: BorderRadius.circular(10),
                ),
                if (item.badge case final badge?)
                  PBadge(text: badge, top: 6, right: 6),
                if (item.duration > 0)
                  PBadge(
                    text: DurationUtils.formatDuration(item.duration),
                    right: 6,
                    bottom: 6,
                    type: .gray,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: item.titleList?.isNotEmpty == true
                            ? item.titleList!
                                  .map(
                                    (part) => TextSpan(
                                      text: part.text,
                                      style: TextStyle(
                                        color: part.isEm
                                            ? colors.primary
                                            : colors.onSurface,
                                      ),
                                    ),
                                  )
                                  .toList()
                            : [TextSpan(text: item.title)],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    '${item.owner.name} · ${DateFormatUtils.dateFormat(item.pubdate)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${NumUtils.numFormat(item.stat.view)}播放 · ${NumUtils.numFormat(item.stat.danmu)}弹幕',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return TvFocusable(
      onTap: () => pushVideoH(item),
      builder: (context, focused, hovered) => TvFocusHighlight(
        focused: focused,
        radius: 16,
        child: content,
      ),
    );
  }
}
