import 'package:bplus_tv/common/assets.dart';
import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/models/common/image_type.dart';
import 'package:bplus_tv/models_new/live/live_search/user_item.dart';
import 'package:bplus_tv/tv/tv_card.dart';
import 'package:bplus_tv/utils/extension/num_ext.dart';
import 'package:bplus_tv/utils/num_utils.dart';
import 'package:bplus_tv/utils/page_utils.dart';
import 'package:material_ui/material_ui.dart';

class LiveSearchUserItem extends StatelessWidget {
  const LiveSearchUserItem({
    super.key,
    required this.item,
  });

  final LiveSearchUserItemModel item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = TextStyle(
      fontSize: 13,
      color: theme.colorScheme.outline,
    );
    return TvCard(
      onTap: () => PageUtils.toLiveRoom(item.roomid),
      radius: 14,
      child: NetflixSegment(
        radius: 14,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 18),
            NetworkImgLayer(
              src: item.face,
              width: 54,
              height: 54,
              type: ImageType.avatar,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.name!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (item.liveStatus == 1) ...[
                        const SizedBox(width: 10),
                        Image.asset(
                          height: 14,
                          cacheHeight: 14.cacheSize(context),
                          Assets.livingRect,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '分区: ${item.areaName ?? ''}    关注数: ${NumUtils.numFormat(item.fansNum ?? 0)}',
                    style: style,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
          ],
        ),
      ),
    );
  }
}
