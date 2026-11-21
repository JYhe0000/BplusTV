import 'package:bplus_tv/common/style.dart';
import 'package:bplus_tv/common/widgets/badge.dart';
import 'package:bplus_tv/common/widgets/image/image_save.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/models_new/sub/sub/list.dart';
import 'package:bplus_tv/pages/subscription_detail/view.dart';
import 'package:bplus_tv/tv/tv_focus_card.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class SubItem extends StatelessWidget {
  final SubItemModel item;
  final VoidCallback cancelSub;
  const SubItem({
    super.key,
    required this.item,
    required this.cancelSub,
  });

  @override
  Widget build(BuildContext context) {
    String heroTag = 'sub-${item.id}';
    final type = switch (item.type) {
      11 => '收藏夹',
      21 => '合集',
      _ => '其它(${item.type})',
    };
    void onLongPress() => imageSaveDialog(
      title: item.title,
      cover: item.cover,
    );
    return TvFocusRing(
      radius: 16,
      child: netflixSurface(
        radius: 16,
        child: InkWell(
          onTap: () {
            if (item.state == 1) {
              SmartDialog.showToast('该$type已失效');
              return;
            }
            if (item.type == 11) {
              Get.toNamed(
                '/favDetail',
                parameters: {
                  'mediaId': item.id!.toString(),
                  'heroTag': heroTag,
                },
              );
            } else {
              SubDetailPage.toSubDetailPage(
                item.id!,
                heroTag: heroTag,
                subInfo: item,
              );
            }
          },
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 5,
                  child: AspectRatio(
                    aspectRatio: Style.aspectRatio,
                    child: LayoutBuilder(
                      builder: (context, boxConstraints) {
                        double maxWidth = boxConstraints.maxWidth;
                        double maxHeight = boxConstraints.maxHeight;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Hero(
                              tag: heroTag,
                              child: NetworkImgLayer(
                                src: item.cover,
                                width: maxWidth,
                                height: maxHeight,
                              ),
                            ),
                            PBadge(
                              right: 6,
                              top: 6,
                              text: type,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                content(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget content(BuildContext context) {
    final theme = Theme.of(context);
    final style = TextStyle(
      fontSize: 14,
      color: theme.colorScheme.outline,
    );
    return Expanded(
      flex: 6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                item.title!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Text(
            'UP主: ${item.upper!.name!}',
            textAlign: TextAlign.start,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${item.mediaCount}个视频',
            textAlign: TextAlign.start,
            style: style,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TvFocusButton(
              onTap: cancelSub,
              child: SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  tooltip: '取消订阅',
                  onPressed: cancelSub,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.outline,
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(Icons.delete_outline, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
