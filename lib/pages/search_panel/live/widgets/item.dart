import 'package:bplus_tv/common/style.dart';
import 'package:bplus_tv/common/widgets/image/image_save.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/models/search/result.dart';
import 'package:bplus_tv/utils/num_utils.dart';
import 'package:bplus_tv/utils/page_utils.dart';
import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/tv/tv_card.dart';
import 'package:material_ui/material_ui.dart';

class LiveItem extends StatelessWidget {
  final SearchLiveItemModel liveItem;

  const LiveItem({super.key, required this.liveItem});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void onLongPress() => imageSaveDialog(
      title: liveItem.title.map((item) => item.text).join(),
      cover: liveItem.cover,
    );
    return NetflixSegment(
      radius: 12,
      child: TvCard(
        onTap: () => PageUtils.toLiveRoom(liveItem.roomid),
        onLongPress: onLongPress,
        radius: 12,
        child: Column(
          crossAxisAlignment: .start,
          children: [
            AspectRatio(
              aspectRatio: Style.aspectRatio,
              child: LayoutBuilder(
                builder: (context, boxConstraints) {
                  double maxWidth = boxConstraints.maxWidth;
                  double maxHeight = boxConstraints.maxHeight;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      NetworkImgLayer(
                        src: liveItem.cover,
                        width: maxWidth,
                        height: maxHeight,
                        borderRadius: const .vertical(top: .circular(12)),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: liveStat(
                          liveItem.online,
                          liveItem.cateName,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            liveContent(theme),
          ],
        ),
      ),
    );
  }

  Widget liveContent(ThemeData theme) => Expanded(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text.rich(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            TextSpan(
              children: liveItem.title
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
          Text(
            liveItem.uname!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: theme.textTheme.labelMedium!.fontSize,
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    ),
  );

  Widget liveStat(int? online, String? cateName) {
    return Container(
      height: 45,
      padding: const EdgeInsets.only(top: 22, left: 8, right: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.transparent,
            Colors.black54,
          ],
          tileMode: TileMode.mirror,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              cateName ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${NumUtils.numFormat(online)}围观',
            style: const TextStyle(fontSize: 11, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
