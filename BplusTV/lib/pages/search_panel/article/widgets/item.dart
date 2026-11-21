import 'package:bplus_tv/common/style.dart';
import 'package:bplus_tv/common/widgets/image/image_save.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/models/search/result.dart';
import 'package:bplus_tv/utils/date_utils.dart';
import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/tv/tv_card.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class SearchArticleItem extends StatelessWidget {
  const SearchArticleItem({super.key, required this.item});

  final SearchArticleItemModel item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = TextStyle(
      fontSize: 14,
      color: theme.colorScheme.outline,
    );
    void onLongPress() => imageSaveDialog(
      title: item.title.map((item) => item.text).join(),
      cover: item.imageUrls?.firstOrNull,
    );
    return NetflixSegment(
      radius: 16,
      child: TvCard(
        radius: 16,
        scale: 1,
        onTap: () => Get.toNamed(
          '/articlePage',
          parameters: {
            'id': '${item.id}',
            'type': 'read',
          },
        ),
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Style.safeSpace,
            vertical: 5,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (item.imageUrls?.isNotEmpty == true)
                  NetworkImgLayer(
                    width: (constraints.maxWidth * 0.36).clamp(0.0, 180.0),
                    height:
                        (constraints.maxWidth * 0.36).clamp(0.0, 180.0) /
                        Style.aspectRatio,
                    src: item.imageUrls?.firstOrNull,
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                      const Spacer(),
                      Text(
                        DateFormatUtils.dateFormat(item.pubTime),
                        style: textStyle,
                      ),
                      Text(
                        '${item.view}浏览 · ${item.reply}评论',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textStyle,
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
