import 'package:bplus_tv/common/style.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/common/widgets/select_mask.dart';
import 'package:bplus_tv/models_new/fav/fav_note/list.dart';
import 'package:bplus_tv/pages/fav/note/controller.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/utils/page_utils.dart';

import 'package:material_ui/material_ui.dart';

class FavNoteItem extends StatelessWidget {
  const FavNoteItem({
    super.key,
    required this.item,
    required this.ctr,
    required this.onSelect,
  });

  final FavNoteItemModel item;
  final FavNoteController ctr;
  final VoidCallback onSelect;

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
      if (item.webUrl case final url? when url.isNotEmpty) {
        PageUtils.handleWebview(url, inApp: true);
      }
    }

    final body = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Style.safeSpace,
        vertical: 5,
      ),
      child: Row(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.pic?.isNotEmpty == true)
            AspectRatio(
              aspectRatio: Style.aspectRatio,
              child: LayoutBuilder(
                builder: (context, boxConstraints) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      NetworkImgLayer(
                        src: item.pic,
                        width: boxConstraints.maxWidth,
                        height: boxConstraints.maxHeight,
                      ),
                      Positioned.fill(
                        child: selectMask(
                          colorScheme,
                          item.checked,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    height: 1.3,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  item.summary ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1,
                    color: colorScheme.outline,
                  ),
                ),
                const Spacer(),
                Text(
                  item.message ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1,
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: TvFocusable(
        onTap: onTap,
        onLongPress: onLongPress,
        builder: (context, focused, hovered) => TvFocusHighlight(
          focused: focused,
          radius: 12,
          child: body,
        ),
      ),
    );
  }
}
