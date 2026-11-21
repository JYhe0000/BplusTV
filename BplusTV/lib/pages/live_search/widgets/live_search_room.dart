import 'package:bplus_tv/common/style.dart';
import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/common/widgets/image/image_save.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/models_new/live/live_search/room_item.dart';
import 'package:bplus_tv/tv/tv_card.dart';
import 'package:bplus_tv/utils/page_utils.dart';
import 'package:material_ui/material_ui.dart';

// 视频卡片 - 垂直布局
class LiveCardVSearch extends StatelessWidget {
  final LiveSearchRoomItemModel item;

  const LiveCardVSearch({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    void onLongPress() => imageSaveDialog(
      title: item.title,
      cover: item.cover,
    );
    return TvCard(
      onTap: () => PageUtils.toLiveRoom(item.roomid),
      onLongPress: onLongPress,
      radius: 14,
      child: NetflixSegment(
        radius: 14,
        child: Column(
          crossAxisAlignment: .start,
          children: [
            AspectRatio(
              aspectRatio: Style.aspectRatio16x9,
              child: LayoutBuilder(
                builder: (context, boxConstraints) {
                  double maxWidth = boxConstraints.maxWidth;
                  double maxHeight = boxConstraints.maxHeight;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      NetworkImgLayer(
                        src: item.cover!,
                        width: maxWidth,
                        height: maxHeight,
                        borderRadius: const .vertical(top: .circular(12)),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: videoStat(),
                      ),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Text(
                  item.title.toString(),
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    letterSpacing: 0.3,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget videoStat() {
    return Container(
      height: 50,
      padding: const EdgeInsets.only(top: 26, left: 10, right: 10),
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
              item.name.toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
          if (item.watchedShow?.textLarge case final textLarge?)
            Text(
              textLarge,
              style: const TextStyle(fontSize: 11, color: Colors.white),
            ),
        ],
      ),
    );
  }
}
