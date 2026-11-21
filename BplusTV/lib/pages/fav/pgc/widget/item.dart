import 'package:bplus_tv/common/style.dart';
import 'package:bplus_tv/common/widgets/badge.dart';
import 'package:bplus_tv/common/widgets/button/icon_button.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/common/widgets/select_mask.dart';
import 'package:bplus_tv/models/common/badge_type.dart';
import 'package:bplus_tv/models_new/fav/fav_pgc/list.dart';
import 'package:bplus_tv/pages/common/multi_select/base.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/utils/page_utils.dart';

import 'package:material_ui/material_ui.dart';

class FavPgcItem extends StatelessWidget {
  const FavPgcItem({
    super.key,
    required this.item,
    required this.ctr,
    required this.onSelect,
    required this.onUpdateStatus,
  });

  final FavPgcItemModel item;
  final MultiSelectBase ctr;
  final VoidCallback onSelect;
  final VoidCallback onUpdateStatus;

  void onLongPress() {
    if (!ctr.enableMultiSelect.value) {
      ctr.enableMultiSelect.value = true;
      onSelect();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    void onTap() {
      if (ctr.enableMultiSelect.value) {
        onSelect();
        return;
      }
      PageUtils.viewPgc(seasonId: item.seasonId);
    }

    final body = Padding(
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
              builder: (context, boxConstraints) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    NetworkImgLayer(
                      src: item.cover,
                      width: boxConstraints.maxWidth,
                      height: boxConstraints.maxHeight,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(4),
                      ),
                    ),
                    PBadge(
                      right: 4,
                      top: 4,
                      text: item.badge,
                      size: PBadgeSize.small,
                      fontSize: 10,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 1,
                      ),
                    ),
                    Positioned.fill(
                      child: selectMask(
                        colorScheme,
                        item.checked,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(4),
                        ),
                      ),
                    ),
                  ],
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
                Text(
                  item.title!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.newEp?.indexShow != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${item.newEp!.indexShow}${item.isFinish == 0 && item.renewalTime?.isNotEmpty == true ? '，${item.renewalTime}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (item.progress != null) ...[
                  SizedBox(
                    height: item.newEp?.indexShow != null ? 2 : 6,
                  ),
                  Text(
                    item.progress!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          TvFocusable(
            onTap: onTap,
            onLongPress: onLongPress,
            builder: (context, focused, hovered) => TvFocusHighlight(
              focused: focused,
              radius: 12,
              child: body,
            ),
          ),
          Positioned(
            right: 12,
            bottom: 0,
            child: iconButton(
              size: 48,
              iconSize: 18,
              onPressed: onUpdateStatus,
              icon: const Icon(Icons.more_vert),
              iconColor: colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
