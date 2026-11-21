// 内容
import 'package:bplus_tv/common/widgets/custom_icon.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/common/widgets/image_grid/image_grid_view.dart';
import 'package:bplus_tv/common/widgets/selection_text.dart';
import 'package:bplus_tv/common/widgets/text_more/text_more.dart';
import 'package:bplus_tv/models/dynamics/result.dart';
import 'package:bplus_tv/pages/dynamics/dyn_layout.dart';
import 'package:bplus_tv/pages/dynamics/widgets/rich_node_panel.dart';
import 'package:bplus_tv/utils/extension/iterable_ext.dart';
import 'package:bplus_tv/utils/extension/selectable_region_ext.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/utils/page_utils.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

part 'package:bplus_tv/common/widgets/context_menu/dyn_menu_helper.dart';

Widget content(
  BuildContext context, {
  required int floor,
  required ThemeData theme,
  required DynamicItemModel item,
  required bool isSave,
  required bool isDetail,
}) {
  TextSpan? richNodes = richNode(
    context,
    theme: theme,
    floor: floor,
    isDetail: isDetail,
    isSave: isSave,
    item: item,
  );
  final moduleDynamic = item.modules.moduleDynamic;
  final pics = moduleDynamic?.major?.opus?.pics;
  final text =
      moduleDynamic?.desc?.text ?? moduleDynamic?.major?.opus?.summary?.text;
  return LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : MediaQuery.sizeOf(context).width;
      final fontSize = DynLayout.bodyFontSize(
        width,
        isDetail: isDetail,
        floor: floor,
        isSave: isSave,
      );
      final lineHeight = DynLayout.lineHeight(width);
      return Padding(
        padding: floor == 1
            ? const EdgeInsets.fromLTRB(16, 0, 16, 16)
            : const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (moduleDynamic?.topic case final topic?)
              TvFocusable(
                onTap: () => Get.toNamed(
                  '/dynTopic',
                  parameters: {
                    'id': topic.id!.toString(),
                    'name': topic.name!,
                  },
                ),
                builder: (context, focused, hovered) => TvFocusHighlight(
                  radius: 8,
                  focused: focused,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 4,
                    ),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                size: 18,
                                CustomIcons.topic_tag,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          TextSpan(text: topic.name),
                        ],
                      ),
                      style: TextStyle(
                        fontSize: floor == 1 ? fontSize : fontSize - 1,
                        height: 1.35,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            if (richNodes != null)
              isDetail && floor == 1
                  ? SelectionText.rich(
                      richNodes,
                      style: TextStyle(
                        fontSize: fontSize,
                        height: lineHeight,
                      ),
                      contextMenuBuilder: text == null || text.isEmpty
                          ? null
                          : (_, state) => dynTextMenuBuilder(
                              state,
                              text,
                              item.modules.moduleDynamic,
                            ),
                    )
                  : TextMore.rich(
                      style: TextStyle(
                        fontSize: fontSize,
                        height: lineHeight,
                      ),
                      richNodes,
                      maxLines: isSave ? null : 6,
                      onShowMore: () =>
                          PageUtils.pushDynDetail(item, isPush: true),
                      primary: theme.colorScheme.primary,
                    ),
            if (pics != null && pics.isNotEmpty) ...[
              if (richNodes != null) const SizedBox(height: 16),
              ImageGridView(
                fullScreen: true,
                picArr: pics
                    .map(
                      (item) => ImageModel(
                        width: item.width,
                        height: item.height,
                        url: item.url ?? '',
                        liveUrl: item.liveUrl,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      );
    },
  );
}
