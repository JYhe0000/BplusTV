import 'package:bplus_tv/common/style.dart';
import 'package:bplus_tv/common/widgets/image/image_save.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/models_new/space/space_archive/item.dart';
import 'package:bplus_tv/tv/tv_focus_card.dart';
import 'package:bplus_tv/utils/page_utils.dart';
import 'package:material_ui/material_ui.dart';

// 视频卡片 - 垂直布局
class PgcCardVMemberPgc extends StatelessWidget {
  const PgcCardVMemberPgc({
    super.key,
    required this.item,
  });

  final SpaceArchiveItem item;

  @override
  Widget build(BuildContext context) {
    void onLongPress() => imageSaveDialog(
      title: item.title,
      cover: item.cover,
    );
    final card = Card(
      shape: const RoundedRectangleBorder(borderRadius: Style.mdRadius),
      child: InkWell(
        canRequestFocus: false,
        borderRadius: Style.mdRadius,
        onTap: () => PageUtils.viewPgc(seasonId: item.param),
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 0.75,
              child: LayoutBuilder(
                builder: (context, boxConstraints) {
                  return NetworkImgLayer(
                    src: item.cover,
                    width: boxConstraints.maxWidth,
                    height: boxConstraints.maxHeight,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 5, 0, 3),
              child: Text(
                item.title,
                textAlign: TextAlign.start,
                style: const TextStyle(
                  letterSpacing: 0.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
    return TvFocusCard(
      onTap: () => PageUtils.viewPgc(seasonId: item.param),
      onLongPress: onLongPress,
      child: card,
    );
  }
}
