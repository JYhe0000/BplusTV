import 'package:bplus_tv/common/style.dart';
import 'package:bplus_tv/common/widgets/badge.dart';
import 'package:bplus_tv/common/widgets/image/image_save.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/common/widgets/stat/stat.dart';
import 'package:bplus_tv/grpc/bilibili/app/interfaces/v1.pb.dart' show Arc;
import 'package:bplus_tv/http/user.dart';
import 'package:bplus_tv/models/common/badge_type.dart';
import 'package:bplus_tv/models/common/stat_type.dart';
import 'package:bplus_tv/tv/tv_dialog.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_focus_card.dart';
import 'package:bplus_tv/utils/date_utils.dart';
import 'package:bplus_tv/utils/duration_utils.dart';
import 'package:bplus_tv/utils/em.dart';
import 'package:bplus_tv/utils/extension/dimension_ext.dart';
import 'package:bplus_tv/utils/id_utils.dart';
import 'package:bplus_tv/utils/page_utils.dart';
import 'package:bplus_tv/utils/utils.dart';
import 'package:fixnum/fixnum.dart' show Int64;
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class SearchArchiveGrpc extends StatelessWidget {
  const SearchArchiveGrpc({
    super.key,
    required this.item,
  });

  final Arc item;

  @override
  Widget build(BuildContext context) {
    final arc = item.archive;
    final bvid = IdUtils.av2bv(arc.aid.toInt());
    final regTitle = Em.regTitle(arc.title);
    final titleStr = regTitle.map((e) => e.text).join();
    void onLongPress() => imageSaveDialog(
      bvid: bvid,
      title: titleStr,
      cover: arc.pic,
    );
    void onTap() {
      if (item.isPugv) {
        PageUtils.viewPgcFromUri(item.uri, isPgc: false);
        return;
      }
      if (arc.hasRedirectUrl()) {
        PageUtils.viewPgcFromUri(arc.redirectUrl);
        return;
      }
      PageUtils.toVideoPage(
        bvid: bvid,
        cid: arc.firstCid.toInt(),
        cover: arc.pic,
        title: titleStr,
        isVertical: arc.dimension.isVertical,
      );
    }

    return TvFocusCard(
      radius: 12,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            InkWell(
              canRequestFocus: false,
              onLongPress: onLongPress,
              onTap: onTap,
              child: Padding(
                padding: const .symmetric(
                  horizontal: Style.safeSpace,
                  vertical: 5,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AspectRatio(
                      aspectRatio: Style.aspectRatio,
                      child: LayoutBuilder(
                        builder: (context, boxConstraints) {
                          final double maxWidth = boxConstraints.maxWidth;
                          final double maxHeight = boxConstraints.maxHeight;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              NetworkImgLayer(
                                src: arc.pic,
                                width: maxWidth,
                                height: maxHeight,
                              ),
                              if (item.isPugv)
                                const PBadge(
                                  text: '课堂',
                                  top: 6.0,
                                  right: 6.0,
                                ),
                              if (arc.duration > Int64.ZERO)
                                PBadge(
                                  text: DurationUtils.formatDuration(
                                    arc.duration.toInt(),
                                  ),
                                  right: 6.0,
                                  bottom: 6.0,
                                  type: PBadgeType.gray,
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    content(context, regTitle),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 12,
              width: 29,
              height: 29,
              child: TvFocusable(
                onTap: () => _showTvMenu(context, bvid),
                builder: (context, focused, hovered) => TvFocusHighlight(
                  focused: focused,
                  radius: 8,
                  child: Icon(
                    Icons.more_vert_outlined,
                    color: focused
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    size: 17,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTvMenu(BuildContext pageContext, String bvid) {
    showDialog(
      context: pageContext,
      builder: (dialogContext) => tvDialogShell(
        title: '更多',
        minWidth: 420,
        content: const SizedBox.shrink(),
        actions: [
          TvDialogAction(
            label: bvid,
            autofocus: true,
            onTap: () {
              Get.back();
              Utils.copyText(bvid);
            },
          ),
          TvDialogAction(
            label: '稍后再看',
            onTap: () {
              Get.back();
              UserHttp.toViewLater(bvid: bvid);
            },
          ),
        ],
      ),
    );
  }

  Widget content(
    BuildContext context,
    List<({bool isEm, String text})> regTitle,
  ) {
    final arc = item.archive;
    final theme = Theme.of(context);
    String pubdate = DateFormatUtils.dateFormat(arc.pubdate.toInt());
    if (pubdate != '') pubdate += '  ';
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text.rich(
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              TextSpan(
                children: regTitle
                    .map(
                      (e) => TextSpan(
                        text: e.text,
                        style: TextStyle(
                          fontSize: theme.textTheme.bodyMedium!.fontSize,
                          height: 1.42,
                          letterSpacing: 0.3,
                          color: e.isEm
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          Text(
            "$pubdate${arc.author.name}",
            maxLines: 1,
            style: TextStyle(
              fontSize: 12,
              height: 1,
              color: theme.colorScheme.outline,
              overflow: TextOverflow.clip,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            spacing: 8,
            children: [
              StatWidget(
                type: StatType.play,
                value: arc.stat.view,
              ),
              StatWidget(
                type: StatType.danmaku,
                value: arc.stat.danmaku,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
