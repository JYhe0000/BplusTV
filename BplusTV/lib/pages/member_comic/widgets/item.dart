import 'package:bplus_tv/common/style.dart';
import 'package:bplus_tv/common/widgets/image/image_save.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/models_new/space/space_archive/item.dart';
import 'package:bplus_tv/tv/tv_focus_card.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class MemberComicItem extends StatelessWidget {
  const MemberComicItem({super.key, required this.item});

  final SpaceArchiveItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    late final style = TextStyle(
      fontSize: 13,
      color: theme.colorScheme.onSurfaceVariant,
    );
    void onLongPress() => imageSaveDialog(title: item.title, cover: item.cover);
    void onTap() {
      Get.toNamed(
        '/webview',
        parameters: {
          'url': 'https://manga.bilibili.com/detail/mc${item.param}',
        },
      );
    }

    final card = Material(
      type: MaterialType.transparency,
      child: InkWell(
        canRequestFocus: false,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Style.safeSpace,
            vertical: 5,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 3 / 4,
                child: LayoutBuilder(
                  builder:
                      (BuildContext context, BoxConstraints boxConstraints) {
                        return NetworkImgLayer(
                          src: item.cover,
                          width: boxConstraints.maxWidth,
                          height: boxConstraints.maxHeight,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(4),
                          ),
                        );
                      },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title),
                    if (item.styles != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.styles!,
                        style: style,
                      ),
                    ],
                    if (item.label != null) ...[
                      Text(
                        item.label!,
                        style: style,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return TvFocusCard(
      onTap: onTap,
      onLongPress: onLongPress,
      child: card,
    );
  }
}
