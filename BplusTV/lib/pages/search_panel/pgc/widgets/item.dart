import 'package:bplus_tv/common/style.dart';
import 'package:bplus_tv/common/widgets/badge.dart';
import 'package:bplus_tv/common/widgets/image/image_save.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/models/search/result.dart';
import 'package:bplus_tv/utils/date_utils.dart';
import 'package:bplus_tv/utils/page_utils.dart';
import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/tv/tv_card.dart';
import 'package:material_ui/material_ui.dart';

class SearchPgcItem extends StatelessWidget {
  const SearchPgcItem({
    super.key,
    required this.item,
  });

  final SearchPgcItemModel item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    const TextStyle style = TextStyle(fontSize: 14);
    void onLongPress() => imageSaveDialog(
      title: item.title.map((item) => item.text).join(),
      cover: item.cover,
    );
    return NetflixSegment(
      radius: 16,
      child: TvCard(
        radius: 16,
        scale: 1,
        onTap: () => PageUtils.viewPgc(seasonId: item.seasonId),
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Style.safeSpace,
            vertical: 5,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    NetworkImgLayer(
                      width: (constraints.maxWidth * 0.28).clamp(72.0, 120.0),
                      height: (constraints.maxWidth * 0.28 * 4 / 3).clamp(
                        96.0,
                        160.0,
                      ),
                      src: item.cover,
                    ),
                    PBadge(
                      text: item.seasonTypeName,
                      top: 6.0,
                      right: 6.0,
                      bottom: null,
                      left: null,
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text.rich(
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                          style: const TextStyle(fontSize: 17, height: 1.35),
                          TextSpan(
                            children: item.title
                                .map(
                                  (e) => TextSpan(
                                    text: e.text,
                                    style: TextStyle(
                                      color: e.isEm
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '评分：${item.mediaScore?['score'] ?? '暂无'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style,
                      ),
                      Text.rich(
                        style: style,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        TextSpan(
                          children: [
                            if (item.areas?.isNotEmpty == true)
                              TextSpan(text: '${item.areas!}  ·  '),
                            TextSpan(
                              text: DateFormatUtils.dateFormat(item.pubtime),
                            ),
                          ],
                        ),
                      ),
                      Text.rich(
                        style: style,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        TextSpan(
                          children: [
                            if (item.styles?.isNotEmpty == true)
                              TextSpan(text: '${item.styles!}  ·  '),
                            if (item.indexShow?.isNotEmpty == true)
                              TextSpan(text: item.indexShow!),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
