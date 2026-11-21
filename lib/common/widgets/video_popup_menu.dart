import 'package:bplus_tv/common/widgets/custom_icon.dart';
import 'package:bplus_tv/http/user.dart';
import 'package:bplus_tv/http/video.dart';
import 'package:bplus_tv/models/home/rcmd/result.dart';
import 'package:bplus_tv/models/model_owner.dart';
import 'package:bplus_tv/models/model_video.dart';
import 'package:bplus_tv/models_new/space/space_archive/item.dart';
import 'package:bplus_tv/pages/mine/controller.dart';
import 'package:bplus_tv/pages/search/widgets/search_text.dart';
import 'package:bplus_tv/pages/video/ai_conclusion/view.dart';
import 'package:bplus_tv/pages/video/introduction/ugc/controller.dart';
import 'package:bplus_tv/tv/tv_dialog.dart';
import 'package:bplus_tv/tv/tv_option_picker.dart';
import 'package:bplus_tv/utils/accounts.dart';
import 'package:bplus_tv/utils/storage_pref.dart';
import 'package:bplus_tv/utils/utils.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart';

class _VideoCustomAction {
  final String title;
  final Widget icon;
  final VoidCallback onTap;
  const _VideoCustomAction(this.title, this.icon, this.onTap);
}

class VideoPopupMenu extends StatelessWidget {
  final double? iconSize;
  final double menuItemHeight;
  final BaseSimpleVideoItemModel videoItem;
  final VoidCallback? onRemove;

  const VideoPopupMenu({
    super.key,
    required this.iconSize,
    required this.videoItem,
    this.onRemove,
    this.menuItemHeight = 45,
  });

  List<_VideoCustomAction> _actions(
    BuildContext context, {
    bool useTvDialogs = false,
  }) {
    return [
      if (videoItem.bvid?.isNotEmpty == true) ...[
        _VideoCustomAction(
          videoItem.bvid!,
          const Icon(CustomIcons.identifier_circle, size: 16),
          () => Utils.copyText(videoItem.bvid!),
        ),
        if (Accounts.main.isLogin)
          _VideoCustomAction(
            '稍后再看',
            const Icon(MdiIcons.clockTimeEightOutline, size: 16),
            () => UserHttp.toViewLater(bvid: videoItem.bvid),
          ),
        if (videoItem.cid != null && Pref.enableAi)
          _VideoCustomAction(
            'AI总结',
            const Icon(CustomIcons.ai_circle, size: 16),
            () async {
              final res = await UgcIntroController.getAiConclusion(
                videoItem.bvid!,
                videoItem.cid!,
                videoItem.owner.mid,
              );
              if (res != null && context.mounted) {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    child: Padding(
                      padding: const .symmetric(vertical: 14),
                      child: AiConclusionPanel.buildContent(
                        context,
                        Theme.of(context),
                        res,
                        tap: false,
                      ),
                    ),
                  ),
                );
              }
            },
          ),
      ],
      if (videoItem is! SpaceArchiveItem) ...[
        _VideoCustomAction(
          '访问：${videoItem.owner.name}',
          const Icon(MdiIcons.accountCircleOutline, size: 16),
          () => Get.toNamed('/member?mid=${videoItem.owner.mid}'),
        ),
        _VideoCustomAction(
          '不感兴趣',
          const Icon(MdiIcons.thumbDownOutline, size: 16),
          () async {
            final rcmd = Accounts.get(.recommend);
            if (rcmd.accessKey == null || rcmd.accessKey == "") {
              SmartDialog.showToast(
                rcmd.isLogin ? '请退出账号后重新登录' : '账号未登录',
              );
              return;
            }
            if (videoItem case final RcmdVideoItemAppModel item) {
              ThreePoint? tp = item.threePoint;
              if (tp == null) {
                SmartDialog.showToast("未能获取threePoint");
                return;
              }
              if (tp.dislikeReasons == null && tp.feedbacks == null) {
                SmartDialog.showToast(
                  "未能获取dislikeReasons或feedbacks",
                );
                return;
              }
              Widget actionButton(Reason? r, Reason? f) {
                return SearchText(
                  text: r?.name ?? f?.name ?? '未知',
                  onTap: (_) async {
                    Get.back();
                    SmartDialog.showLoading(msg: '正在提交');
                    final res = await VideoHttp.feedDislike(
                      reasonId: r?.id,
                      feedbackId: f?.id,
                      id: item.param!,
                      goto: item.goto!,
                    );
                    SmartDialog.dismiss();
                    if (res.isSuccess) {
                      SmartDialog.showToast(
                        r?.toast ?? f!.toast!,
                      );
                      onRemove?.call();
                    } else {
                      res.toast();
                    }
                  },
                );
              }

              showDialog(
                context: context,
                builder: (context) {
                  return SimpleDialog(
                    contentPadding: const .fromLTRB(24, 16, 24, 24),
                    children: [
                      if (tp.dislikeReasons != null) ...[
                        const Text('我不想看'),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: tp.dislikeReasons!
                              .map(
                                (item) => actionButton(item, null),
                              )
                              .toList(),
                        ),
                      ],
                      if (tp.feedbacks != null) ...[
                        const SizedBox(height: 5),
                        const Text('反馈'),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: tp.feedbacks!
                              .map(
                                (item) => actionButton(null, item),
                              )
                              .toList(),
                        ),
                      ],
                      const Divider(),
                      Center(
                        child: FilledButton.tonal(
                          onPressed: () async {
                            SmartDialog.showLoading(
                              msg: '正在提交',
                            );
                            final res = await VideoHttp.feedDislikeCancel(
                              id: item.param!,
                              goto: item.goto!,
                            );
                            SmartDialog.dismiss();
                            SmartDialog.showToast(
                              res.isSuccess ? "成功" : res.toString(),
                            );
                            Get.back();
                          },
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text("撤销"),
                        ),
                      ),
                    ],
                  );
                },
              );
            } else if (useTvDialogs) {
              final dislike = await showTvOptionPicker<bool>(
                context: context,
                title: '不感兴趣',
                options: const [
                  TvOption(value: true, label: '点踩'),
                  TvOption(value: false, label: '撤销点踩'),
                ],
              );
              if (dislike != null) await _setDislike(dislike);
            } else {
              showDialog(
                context: context,
                builder: (context) => SimpleDialog(
                  contentPadding: const .all(24),
                  children: [
                    const Center(child: Text("web端暂不支持精细选择")),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 5.0,
                      runSpacing: 2.0,
                      alignment: .center,
                      children: [
                        FilledButton.tonal(
                          onPressed: () async {
                            Get.back();
                            await _setDislike(true);
                          },
                          style: FilledButton.styleFrom(
                            visualDensity: .compact,
                          ),
                          child: const Text("点踩"),
                        ),
                        FilledButton.tonal(
                          onPressed: () async {
                            Get.back();
                            await _setDislike(false);
                          },
                          style: FilledButton.styleFrom(
                            visualDensity: .compact,
                          ),
                          child: const Text("撤销"),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }
          },
        ),
        _VideoCustomAction(
          '拉黑：${videoItem.owner.name}',
          const Icon(MdiIcons.cancel, size: 16),
          () async {
            final message =
                '确定拉黑:${videoItem.owner.name}(${videoItem.owner.mid})?'
                '\n\n注：被拉黑的Up可以在隐私设置-黑名单管理中解除';
            if (useTvDialogs) {
              final confirmed = await showTvConfirm(
                context: context,
                title: '拉黑 UP 主',
                message: message,
                confirmLabel: '拉黑',
                destructive: true,
              );
              if (confirmed == true) await _blockOwner();
              return;
            }
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('提示'),
                  content: Text(message),
                  actions: [
                    TextButton(
                      onPressed: Get.back,
                      child: Text(
                        '点错了',
                        style: TextStyle(
                          color: ColorScheme.of(context).outline,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        Get.back();
                        await _blockOwner();
                      },
                      child: const Text('确认'),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
      _VideoCustomAction(
        "${MineController.anonymity.value ? '退出' : '进入'}无痕模式",
        MineController.anonymity.value
            ? const Icon(MdiIcons.incognitoOff, size: 16)
            : const Icon(MdiIcons.incognito, size: 16),
        MineController.onChangeAnonymity,
      ),
    ];
  }

  List<PopupMenuEntry<dynamic>> _entries(BuildContext context) =>
      _actions(context)
          .map(
            (e) => PopupMenuItem<dynamic>(
              height: menuItemHeight,
              onTap: e.onTap,
              child: Row(
                children: [
                  e.icon,
                  const SizedBox(width: 6),
                  Text(e.title, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          )
          .toList();

  Future<void> _setDislike(bool dislike) async {
    final bvid = videoItem.bvid;
    if (bvid == null || bvid.isEmpty) {
      SmartDialog.showToast('未能获取视频编号');
      return;
    }
    SmartDialog.showLoading(msg: '正在提交');
    final res = await VideoHttp.dislikeVideo(bvid: bvid, type: dislike);
    SmartDialog.dismiss();
    if (dislike) {
      if (res.isSuccess) {
        SmartDialog.showToast('点踩成功');
        onRemove?.call();
      } else {
        res.toast();
      }
    } else {
      SmartDialog.showToast(res.isSuccess ? '取消踩' : res.toString());
    }
  }

  Future<void> _blockOwner() async {
    final mid = videoItem.owner.mid;
    if (mid == null) {
      SmartDialog.showToast('未能获取 UP 主编号');
      return;
    }
    final res = await VideoHttp.relationMod(
      mid: mid,
      act: 5,
      reSrc: 11,
    );
    if (res.isSuccess) {
      onRemove?.call();
    } else {
      res.toast();
    }
  }

  static Future<void> showTv(
    BuildContext context, {
    required BaseSimpleVideoItemModel videoItem,
    VoidCallback? onRemove,
  }) async {
    final actions = VideoPopupMenu(
      iconSize: null,
      videoItem: videoItem,
      onRemove: onRemove,
    )._actions(context, useTvDialogs: true);
    final action = await showTvOptionPicker<_VideoCustomAction>(
      context: context,
      title: '更多操作',
      options: [
        for (final action in actions)
          TvOption(value: action, label: action.title, leading: action.icon),
      ],
    );
    if (context.mounted) action?.onTap();
  }

  static Future<void> showTvForDetails(
    BuildContext context, {
    required String title,
    String? bvid,
    int? cid,
    String? cover,
    String? ownerName,
    int? ownerMid,
  }) => showTv(
    context,
    videoItem: _VideoMenuItem(
      title: title,
      bvid: bvid,
      cid: cid,
      cover: cover,
      ownerName: ownerName,
      ownerMid: ownerMid,
    ),
  );

  /// Opens this menu for [videoItem], anchored to the widget of [context].
  /// Used by TV cards whose menu button is excluded from D-pad traversal.
  static Future<void> show(
    BuildContext context, {
    required BaseSimpleVideoItemModel videoItem,
    VoidCallback? onRemove,
    double menuItemHeight = 45,
    bool openBelow = false,
  }) async {
    final button = context.findRenderObject();
    final overlay = Navigator.of(context).overlay?.context.findRenderObject();
    if (button is! RenderBox || overlay is! RenderBox) return;
    final offset = openBelow ? Offset(0, button.size.height) : Offset.zero;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(offset, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(offset),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );
    await showMenu<dynamic>(
      context: context,
      position: position,
      items: VideoPopupMenu(
        iconSize: 17,
        videoItem: videoItem,
        onRemove: onRemove,
        menuItemHeight: menuItemHeight,
      )._entries(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The button overlaps the video card it belongs to. If it stayed
    // focusable, D-pad focus would land on it first when moving down/right,
    // hiding the card's selection highlight until the next press. Keep it
    // tappable (mouse/touch) but out of keyboard/D-pad traversal.
    return ExcludeFocus(
      child: PopupMenuButton<dynamic>(
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.more_vert_outlined,
          color: Theme.of(context).colorScheme.outline,
          size: iconSize,
        ),
        position: PopupMenuPosition.under,
        itemBuilder: _entries,
      ),
    );
  }
}

class _VideoMenuItem extends BaseSimpleVideoItemModel {
  _VideoMenuItem({
    required String title,
    required String? bvid,
    required int? cid,
    required String? cover,
    required String? ownerName,
    required int? ownerMid,
  }) {
    this.title = title;
    this.bvid = bvid;
    this.cid = cid;
    this.cover = cover;
    owner = Owner(mid: ownerMid, name: ownerName);
    stat = Stat.fromJson(const {});
  }
}
