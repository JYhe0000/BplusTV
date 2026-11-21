import 'package:bplus_tv/common/style.dart';
import 'package:bplus_tv/common/widgets/image/image_save.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/models_new/space/space_fav/list.dart';
import 'package:bplus_tv/tv/tv_focus_card.dart';
import 'package:bplus_tv/utils/utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class MemberFavItem extends StatelessWidget {
  const MemberFavItem({super.key, required this.item});

  final SpaceFavItemModel item;

  @override
  Widget build(BuildContext context) {
    void onLongPress() => imageSaveDialog(
      title: item.title,
      cover: item.cover,
    );
    void onTap() {
      Get.toNamed(
        '/favDetail',
        parameters: {
          'mediaId': item.mediaId.toString(),
          'heroTag': Utils.makeHeroTag(item.mediaId),
        },
      );
    }

    return TvFocusCard(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          canRequestFocus: false,
          onTap: onTap,
          onLongPress: onLongPress,
          onSecondaryTap: onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Style.safeSpace,
              vertical: 5,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NetworkImgLayer(
                  src: item.cover,
                  width: 160,
                  height: 100,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        '${item.count}个内容 · ${item.isPublic == 1 ? '私密' : '公开'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.outline,
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
