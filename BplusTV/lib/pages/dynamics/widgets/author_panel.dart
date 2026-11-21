import 'package:bplus_tv/common/assets.dart';
import 'package:bplus_tv/common/widgets/custom_icon.dart';
import 'package:bplus_tv/common/widgets/dialog/report.dart';
import 'package:bplus_tv/common/widgets/pendant_avatar.dart';
import 'package:bplus_tv/common/widgets/translucent_row.dart';
import 'package:bplus_tv/http/constants.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/http/reply.dart';
import 'package:bplus_tv/http/user.dart';
import 'package:bplus_tv/http/video.dart';
import 'package:bplus_tv/models/dynamics/result.dart';
import 'package:bplus_tv/pages/dynamics/controller.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_dialog.dart';
import 'package:bplus_tv/pages/save_panel/view.dart';
import 'package:bplus_tv/utils/accounts.dart';
import 'package:bplus_tv/utils/color_utils.dart';
import 'package:bplus_tv/utils/date_utils.dart';
import 'package:bplus_tv/utils/extension/num_ext.dart';
import 'package:bplus_tv/utils/extension/theme_ext.dart';
import 'package:bplus_tv/utils/feed_back.dart';
import 'package:bplus_tv/utils/image_utils.dart';
import 'package:bplus_tv/utils/page_utils.dart';
import 'package:bplus_tv/utils/request_utils.dart';
import 'package:bplus_tv/utils/share_utils.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class AuthorPanel extends StatelessWidget {
  final DynamicItemModel item;
  final bool isSave;
  final bool isDetail;
  final ValueChanged<Object>? onRemove;
  final void Function(bool isTop, Object dynId)? onSetTop;
  final VoidCallback? onBlock;
  final Future<LoadingState> Function(bool isPrivate, Object dynId)?
  onSetPubSetting;
  final VoidCallback? onEdit;
  final ValueChanged<int>? onSetReplySubject;

  const AuthorPanel({
    super.key,
    required this.item,
    this.isDetail = false,
    this.onRemove,
    this.isSave = false,
    this.onSetTop,
    this.onBlock,
    this.onSetPubSetting,
    this.onEdit,
    this.onSetReplySubject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moduleAuthor = item.modules.moduleAuthor!;
    final pubTime = moduleAuthor.pubTs != null
        ? isSave
              ? DateFormatUtils.format(
                  moduleAuthor.pubTs,
                  format: DateFormatUtils.longFormatDs,
                )
              : DateFormatUtils.dateFormat(moduleAuthor.pubTs)
        : moduleAuthor.pubTime;
    Widget? pubTs;
    if (pubTime != null) {
      pubTs = Text(
        '$pubTime${moduleAuthor.pubAction != null ? ' ${moduleAuthor.pubAction}' : ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: theme.colorScheme.outline,
          fontSize: 14,
          height: 1.4,
        ),
      );
      if (moduleAuthor.badgeText case final badgeText?) {
        pubTs = Row(
          mainAxisSize: .min,
          spacing: 5,
          children: [
            Flexible(child: pubTs),
            Text(
              badgeText,
              style: TextStyle(
                color: theme.colorScheme.secondary,
                fontSize: 14,
              ),
            ),
          ],
        );
      }
    }
    final children = [
      PendantAvatar(
        size: 48,
        moduleAuthor.face,
        pendantImage: moduleAuthor.pendant?.image,
      ),
      Flexible(
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Text(
              moduleAuthor.name!,
              maxLines: 1,
              overflow: .ellipsis,
              style: TextStyle(
                color:
                    moduleAuthor.vip != null &&
                        moduleAuthor.vip!.status > 0 &&
                        moduleAuthor.vip!.type == 2
                    ? theme.colorScheme.vipColor
                    : theme.colorScheme.onSurface,
                fontSize: 18,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            ?pubTs,
          ],
        ),
      ),
    ];
    Widget header;
    if (moduleAuthor.type == 'AUTHOR_TYPE_NORMAL') {
      header = TvFocusable(
        onTap: () {
          feedBack();
          Get.toNamed('/member?mid=${moduleAuthor.mid}');
        },
        builder: (context, focused, hovered) => TvFocusHighlight(
          radius: 10,
          focused: focused,
          child: TranslucentRow(
            spacing: 10,
            extraWidth: 50,
            children: children,
          ),
        ),
      );
    } else {
      header = Row(spacing: 10, children: children);
    }
    Widget? moreBtn = isSave
        ? null
        : SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              tooltip: '更多',
              style: const ButtonStyle(
                padding: WidgetStatePropertyAll(EdgeInsets.zero),
              ),
              onPressed: () => morePanel(context),
              icon: const Icon(Icons.more_vert_outlined, size: 24),
            ),
          );
    final moduleTagText = !isDetail ? item.modules.moduleTag?.text : null;
    if (moduleTagText != null) {
      header = Row(
        children: [
          Expanded(child: header),
          Container(
            padding: const .symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: const .all(.circular(4)),
              border: .all(width: 1.25, color: theme.colorScheme.primary),
            ),
            child: Text(
              moduleTagText,
              style: TextStyle(
                height: 1,
                fontSize: 12,
                color: theme.colorScheme.primary,
              ),
              strutStyle: const StrutStyle(height: 1, leading: 0, fontSize: 12),
            ),
          ),
          ?moreBtn,
        ],
      );
    } else if (moduleAuthor.decorate != null) {
      const height = 32.0;
      header = Stack(
        clipBehavior: .none,
        children: [
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: CachedNetworkImage(
                height: height,
                memCacheHeight: height.cacheSize(context),
                imageUrl: ImageUtils.safeThumbnailUrl(
                  moduleAuthor.decorate!.cardUrl,
                ),
                placeholder: (_, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          if (moduleAuthor.decorate!.fan?.numStr?.isNotEmpty == true)
            Positioned(
              top: 0,
              bottom: 0,
              right: height,
              child: Center(
                child: Text(
                  moduleAuthor.decorate!.fan!.numStr!.toString(),
                  style: TextStyle(
                    height: 1,
                    fontSize: 11,
                    fontFamily: Assets.digitalNum,
                    color: ColourUtils.parseColor(
                      moduleAuthor.decorate!.fan!.color!,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const .only(right: 80),
            child: header,
          ),
        ],
      );
      if (moreBtn != null) {
        header = Row(
          children: [
            Expanded(child: header),
            moreBtn,
          ],
        );
      }
    } else if (moreBtn != null) {
      header = Row(
        children: [
          Expanded(child: header),
          moreBtn,
        ],
      );
    }
    return header;
  }

  void morePanel(BuildContext context) {
    String? bvid;
    try {
      String? getBvid(String? type, DynamicMajorModel? major) => switch (type) {
        'DYNAMIC_TYPE_AV' => major?.archive?.bvid,
        'DYNAMIC_TYPE_UGC_SEASON' => major?.ugcSeason?.bvid,
        _ => null,
      };
      bvid = getBvid(item.type, item.modules.moduleDynamic?.major);
      if (bvid == null && item.orig != null) {
        bvid = getBvid(
          item.orig!.type,
          item.orig!.modules.moduleDynamic?.major,
        );
      }
    } catch (_) {}

    {
      showDialog(
        context: context,
        builder: (dialogContext) => tvDialogShell(
          title: '更多',
          minWidth: 460,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _moreEntries(context, bvid),
            ),
          ),
          actions: [
            TvDialogAction(
              label: '取消',
              autofocus: true,
              onTap: Get.back,
            ),
          ],
        ),
      );
      return;
    }
  }

  List<Widget> _moreEntries(BuildContext context, String? bvid) {
    final theme = Theme.of(context);
    final moduleAuthor = item.modules.moduleAuthor!;
    Widget entry({
      required bool enabled,
      required IconData icon,
      required String title,
      required Color color,
      required VoidCallback onTap,
    }) {
      final tile = ListTile(
        onTap: null,
        enabled: enabled,
        dense: false,
        minLeadingWidth: 0,
        leading: Icon(icon, color: color, size: 19),
        title: Text(
          title,
          style: theme.textTheme.titleSmall!.copyWith(
            color: color,
            fontSize: 16,
          ),
        ),
      );

      return TvFocusable(
        canRequestFocus: enabled,
        onTap: onTap,
        builder: (context, focused, hovered) => TvFocusHighlight(
          focused: focused,
          radius: 10,
          borderWidth: 2,
          child: tile,
        ),
      );
    }

    final list = <Widget>[
      if (bvid != null)
        entry(
          enabled: true,
          icon: Icons.watch_later_outlined,
          title: '稍后再看',
          color: theme.colorScheme.onSurface,
          onTap: () {
            Get.back();
            UserHttp.toViewLater(bvid: bvid);
          },
        ),
      entry(
        enabled: true,
        icon: Icons.save_alt,
        title: '保存动态',
        color: theme.colorScheme.onSurface,
        onTap: () {
          Get.back();
          SavePanel.toSavePanel(item: item);
        },
      ),
      entry(
        enabled: true,
        icon: Icons.share_outlined,
        title: '分享动态',
        color: theme.colorScheme.onSurface,
        onTap: () {
          Get.back();
          ShareUtils.shareText(
            '${HttpString.opusBaseUrl}/${item.idStr}',
          );
        },
      ),
      if ((item.basic!.commentType == 17 || item.basic!.commentType == 11) &&
          item.modules.moduleDynamic?.major?.blocked == null)
        entry(
          enabled: true,
          icon: Icons.forward_to_inbox,
          title: '分享至消息',
          color: theme.colorScheme.onSurface,
          onTap: () {
            Get.back();
            try {
              bool isDyn = item.basic!.commentType == 17;
              String id = isDyn ? item.idStr : item.basic!.ridStr!;
              int source = isDyn ? 11 : 2;
              final moduleDynamic = item.modules.moduleDynamic!;
              final title =
                  moduleDynamic.desc?.text ??
                  moduleDynamic.major!.opus!.summary!.text!;
              String? thumb = isDyn
                  ? moduleAuthor.face
                  : moduleDynamic.major?.opus?.pics?.firstOrNull?.url;
              PageUtils.pmShare(
                context,
                content: {
                  "id": id,
                  "title": title,
                  "headline": "",
                  "source": source,
                  if (thumb?.isNotEmpty == true) "thumb": thumb,
                  "author": moduleAuthor.name,
                  "author_id": moduleAuthor.mid.toString(),
                },
              );
            } catch (e) {
              SmartDialog.showToast(e.toString());
            }
          },
        ),
      entry(
        enabled: true,
        icon: Icons.visibility_off_outlined,
        title: '临时屏蔽：${moduleAuthor.name}',
        color: theme.colorScheme.onSurface,
        onTap: () {
          Get.back();
          onBlock?.call();
          try {
            Get.find<DynamicsController>().tempBannedList.add(
              moduleAuthor.mid!,
            );
            SmartDialog.showToast(
              '已临时屏蔽${moduleAuthor.name}(${moduleAuthor.mid!})，重启恢复',
            );
          } catch (_) {}
        },
      ),
    ];
    if (kDebugMode || moduleAuthor.mid == Accounts.main.mid) {
      list.addAll([
        entry(
          enabled: true,
          icon: CustomIcons.shield_published,
          title: '检查动态',
          color: theme.colorScheme.onSurface,
          onTap: () {
            Get.back();
            RequestUtils.checkCreatedDyn(
              id: item.idStr,
              isManual: true,
            );
          },
        ),
        if (onSetTop != null)
          entry(
            enabled: true,
            icon: Icons.vertical_align_top,
            title: '${moduleAuthor.isTop == true ? '取消' : ''}置顶',
            color: theme.colorScheme.onSurface,
            onTap: () {
              Get.back();
              onSetTop!(moduleAuthor.isTop ?? false, item.idStr);
            },
          ),
        if (onSetReplySubject != null)
          entry(
            enabled: true,
            icon: Icons.mark_unread_chat_alt_outlined,
            title: '互动设置',
            color: theme.colorScheme.onSurface,
            onTap: () async {
              Get.back();
              final res = await ReplyHttp.replyInteraction(
                oid: item.basic!.commentIdStr!,
                type: item.basic!.commentType!,
              );
              if (res case Success(:final response)) {
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) {
                      final selection = response.upReplySelection;
                      final enableSelection = selection.status == 1;

                      final reply = response.upReply;
                      final enableReply = reply.status == 1;

                      return SimpleDialog(
                        clipBehavior: .hardEdge,
                        contentPadding: const .symmetric(vertical: 12),
                        children: [
                          ListTile(
                            dense: true,
                            enabled: selection.canModify,
                            title: Text(
                              '${enableSelection ? '停止' : '开启'}评论精选',
                              style: const TextStyle(fontSize: 14),
                            ),
                            onTap: () {
                              Get.back();
                              onSetReplySubject!(
                                enableSelection ? 2 : 1,
                              );
                            },
                          ),
                          ListTile(
                            dense: true,
                            enabled: reply.canModify,
                            title: Text(
                              '${enableReply ? '关闭' : '恢复'}评论',
                              style: const TextStyle(fontSize: 14),
                            ),
                            onTap: () {
                              Get.back();
                              onSetReplySubject!(enableReply ? 3 : 4);
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
              } else {
                res.toast();
              }
            },
          ),
        if (onSetPubSetting != null)
          entry(
            enabled: true,
            icon: Icons.visibility,
            title: '可见范围',
            color: theme.colorScheme.onSurface,
            onTap: () {
              Get.back();

              final isPrivate = moduleAuthor.badgeText != null;
              Future<void> onTap() async {
                Get.back();
                if ((await onSetPubSetting!(
                  isPrivate,
                  item.idStr,
                )).isSuccess) {
                  if (context.mounted) {
                    (context as Element).markNeedsBuild();
                  }
                }
              }

              showDialog(
                context: context,
                builder: (context) => SimpleDialog(
                  clipBehavior: Clip.hardEdge,
                  contentPadding: const .symmetric(vertical: 12),
                  children: [
                    ListTile(
                      dense: true,
                      enabled: isPrivate,
                      title: const Text(
                        '所有用户可见',
                        style: TextStyle(fontSize: 14),
                      ),
                      onTap: onTap,
                    ),
                    ListTile(
                      dense: true,
                      enabled: !isPrivate,
                      title: const Text(
                        '仅自己可见',
                        style: TextStyle(fontSize: 14),
                      ),
                      onTap: onTap,
                    ),
                  ],
                ),
              );
            },
          ),
        if (onEdit != null)
          entry(
            enabled: true,
            icon: Icons.edit_note,
            title: '编辑动态',
            color: theme.colorScheme.onSurface,
            onTap: () {
              Get.back();
              onEdit!();
            },
          ),
        if (onRemove != null)
          entry(
            enabled: true,
            icon: Icons.delete_outline,
            title: '删除',
            color: theme.colorScheme.error,
            onTap: () {
              Get.back();
              {
                showTvConfirm(
                  context: context,
                  title: '提示',
                  message: '确定删除该动态?',
                  confirmLabel: '确定',
                ).then((res) {
                  if (res == true) onRemove!(item.idStr);
                });
                return;
              }
            },
          ),
      ]);
    }
    if (Accounts.main.isLogin) {
      list.add(
        entry(
          enabled: true,
          icon: Icons.error_outline_outlined,
          title: '举报',
          color: theme.colorScheme.error,
          onTap: () {
            Get.back();
            autoWrapReportDialog(
              context,
              ReportOptions.dynamicReport,
              (reasonType, reasonDesc, banUid) {
                if (banUid) {
                  VideoHttp.relationMod(
                    mid: moduleAuthor.mid!,
                    act: 5,
                    reSrc: 11,
                  );
                }
                return UserHttp.dynamicReport(
                  mid: moduleAuthor.mid!,
                  dynId: item.idStr,
                  reasonType: reasonType,
                  reasonDesc: reasonDesc,
                );
              },
            );
          },
        ),
      );
    }
    return list;
  }
}
