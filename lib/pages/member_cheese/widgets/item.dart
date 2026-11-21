import 'package:bplus_tv/common/style.dart';
import 'package:bplus_tv/common/widgets/badge.dart';
import 'package:bplus_tv/common/widgets/button/icon_button.dart';
import 'package:bplus_tv/common/widgets/image/image_save.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/models_new/space/space_cheese/item.dart';
import 'package:bplus_tv/tv/tv_focus_card.dart';
import 'package:bplus_tv/utils/date_utils.dart';
import 'package:bplus_tv/utils/page_utils.dart';
import 'package:material_ui/material_ui.dart';

class MemberCheeseItem extends StatelessWidget {
  const MemberCheeseItem({
    super.key,
    required this.item,
    this.onRemove,
  });

  final SpaceCheeseItem item;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget child = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title!,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (item.status != null) ...[
          const SizedBox(height: 6),
          Text(
            item.status!,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (item.ctime != null) ...[
          const Spacer(),
          Text(
            '收藏于${DateFormatUtils.dateFormat(int.parse(item.ctime!))}',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ],
    );
    if (onRemove != null) {
      child = Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          Positioned(
            right: 0,
            bottom: -8,
            child: iconButton(
              tooltip: '移除',
              onPressed: onRemove,
              icon: const Icon(Icons.clear),
              iconColor: theme.colorScheme.outline,
            ),
          ),
        ],
      );
    }
    void onLongPress() => imageSaveDialog(title: item.title, cover: item.cover);
    final card = Material(
      type: MaterialType.transparency,
      child: InkWell(
        canRequestFocus: false,
        onTap: () => PageUtils.viewPugv(seasonId: item.seasonId),
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
                aspectRatio: Style.aspectRatio,
                child: LayoutBuilder(
                  builder: (context, boxConstraints) {
                    Widget child = NetworkImgLayer(
                      src: item.cover,
                      width: boxConstraints.maxWidth,
                      height: boxConstraints.maxHeight,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(4),
                      ),
                    );
                    if (item.marks?.isNotEmpty == true) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          child,
                          PBadge(
                            right: 6,
                            top: 6,
                            text: item.marks!.join('|'),
                          ),
                        ],
                      );
                    }
                    return child;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
    return TvFocusCard(
      onTap: () => PageUtils.viewPugv(seasonId: item.seasonId),
      onLongPress: onLongPress,
      child: card,
    );
  }
}
