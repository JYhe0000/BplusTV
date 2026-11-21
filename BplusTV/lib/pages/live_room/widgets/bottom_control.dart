import 'package:bplus_tv/common/widgets/custom_icon.dart';
import 'package:bplus_tv/pages/live_room/controller.dart';
import 'package:bplus_tv/pages/video/widgets/header_mixin.dart';
import 'package:bplus_tv/plugin/pl_player/controller.dart';
import 'package:bplus_tv/plugin/pl_player/models/video_fit_type.dart';
import 'package:bplus_tv/plugin/pl_player/widgets/common_btn.dart';
import 'package:bplus_tv/plugin/pl_player/widgets/play_pause_btn.dart';
import 'package:bplus_tv/utils/storage.dart';
import 'package:bplus_tv/utils/storage_key.dart';
import 'package:bplus_tv/utils/theme_utils.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class BottomControl extends StatefulWidget {
  const BottomControl({
    super.key,
    required this.plPlayerController,
    required this.liveRoomCtr,
    required this.onRefresh,
    this.subTitleStyle = const TextStyle(fontSize: 12),
    this.titleStyle = const TextStyle(fontSize: 14),
  });

  final PlPlayerController plPlayerController;
  final LiveRoomController liveRoomCtr;
  final VoidCallback onRefresh;

  final TextStyle subTitleStyle;
  final TextStyle titleStyle;

  @override
  State<BottomControl> createState() => _BottomControlState();
}

class _BottomControlState extends State<BottomControl> with HeaderMixin {
  late final LiveRoomController liveRoomCtr = widget.liveRoomCtr;
  @override
  late final PlPlayerController plPlayerController = widget.plPlayerController;
  @override
  ThemeData get theme => ThemeUtils.darkTheme;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: Padding(
            padding: const .symmetric(horizontal: 14, vertical: 13),
            child: Material(
              type: .transparency,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    child: PlayOrPauseButton(
                      plPlayerController: plPlayerController,
                    ),
                  ),
                  ComBtn(
                    width: 48,
                    height: 48,
                    tooltip: '刷新',
                    icon: const Icon(
                      Icons.refresh,
                      size: 18,
                      color: Colors.white,
                    ),
                    onTap: widget.onRefresh,
                  ),
                  const SizedBox(width: 12),
                  ComBtn(
                    width: 48,
                    height: 48,
                    tooltip: '屏蔽',
                    icon: const Icon(
                      size: 18,
                      Icons.block,
                      color: Colors.white,
                    ),
                    onTap: () {
                      if (kDebugMode || liveRoomCtr.isLogin) {
                        Get.toNamed(
                          '/liveDmBlockPage',
                          parameters: {
                            'roomId': liveRoomCtr.roomId.toString(),
                          },
                          arguments: liveRoomCtr,
                        );
                      } else {
                        SmartDialog.showToast('账号未登录');
                      }
                    },
                  ),
                  const SizedBox(width: 3),
                  Obx(
                    () {
                      final enableShowLiveDanmaku =
                          plPlayerController.enableShowLiveDanmaku.value;
                      return ComBtn(
                        width: 48,
                        height: 48,
                        tooltip: "${enableShowLiveDanmaku ? '关闭' : '开启'}弹幕",
                        icon: enableShowLiveDanmaku
                            ? const Icon(
                                size: 18,
                                CustomIcons.dm_on,
                                color: Colors.white,
                              )
                            : const Icon(
                                size: 18,
                                CustomIcons.dm_off,
                                color: Colors.white,
                              ),
                        onTap: () {
                          final newVal = !enableShowLiveDanmaku;
                          plPlayerController.enableShowLiveDanmaku.value =
                              newVal;
                          if (!plPlayerController.tempPlayerConf) {
                            GStorage.setting.put(
                              SettingBoxKey.enableShowLiveDanmaku,
                              newVal,
                            );
                          }
                        },
                      );
                    },
                  ),
                  ComBtn(
                    width: 48,
                    height: 48,
                    tooltip: '弹幕设置',
                    icon: const Icon(
                      size: 18,
                      CustomIcons.dm_settings,
                      color: Colors.white,
                    ),
                    onTap: () => showSetDanmaku(isLive: true),
                  ),
                  Obx(
                    () => PopupMenuButton<VideoFitType>(
                      tooltip: '画面比例',
                      initialValue: plPlayerController.videoFit.value,
                      color: Colors.black.withValues(alpha: 0.8),
                      itemBuilder: (context) {
                        return VideoFitType.values
                            .map(
                              (boxFit) => PopupMenuItem<VideoFitType>(
                                height: 48,
                                padding: const EdgeInsets.only(left: 30),
                                value: boxFit,
                                onTap: () =>
                                    plPlayerController.toggleVideoFit(boxFit),
                                child: Text(
                                  boxFit.desc,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            )
                            .toList();
                      },
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          plPlayerController.videoFit.value.desc,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Obx(
                    () => PopupMenuButton<int>(
                      tooltip: '画质',
                      padding: EdgeInsets.zero,
                      initialValue: liveRoomCtr.currentQn,
                      color: Colors.black.withValues(alpha: 0.8),
                      itemBuilder: (context) {
                        return liveRoomCtr.acceptQnList
                            .map(
                              (e) => PopupMenuItem<int>(
                                height: 48,
                                padding: const EdgeInsets.only(left: 30),
                                value: e.code,
                                onTap: () => liveRoomCtr.changeQn(e.code),
                                child: Text(
                                  e.desc,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            )
                            .toList();
                      },
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          liveRoomCtr.currentQnDesc.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
