import 'package:bplus_tv/common/widgets/marquee.dart';
import 'package:bplus_tv/models/common/video/live_quality.dart';
import 'package:bplus_tv/pages/live/widgets/live_tv_dialog.dart';
import 'package:bplus_tv/pages/live_room/controller.dart';
import 'package:bplus_tv/pages/video/widgets/header_control.dart';
import 'package:bplus_tv/plugin/pl_player/controller.dart';
import 'package:bplus_tv/plugin/pl_player/widgets/common_btn.dart';
import 'package:bplus_tv/services/shutdown_timer_service.dart'
    show shutdownTimerService;
import 'package:bplus_tv/utils/storage.dart';
import 'package:bplus_tv/utils/storage_key.dart';
import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart';

class LiveHeaderControl extends StatefulWidget {
  const LiveHeaderControl({
    super.key,
    required this.title,
    required this.upName,
    required this.plPlayerController,
    required this.onSendDanmaku,
    required this.onPlayAudio,
    required this.isPortrait,
    required this.liveController,
    required this.onlineWidget,
  });

  final String? title;
  final String? upName;
  final PlPlayerController plPlayerController;
  final VoidCallback onSendDanmaku;
  final VoidCallback onPlayAudio;
  final bool isPortrait;
  final LiveRoomController liveController;
  final Widget onlineWidget;

  @override
  State<LiveHeaderControl> createState() => _LiveHeaderControlState();
}

class _LiveHeaderControlState extends State<LiveHeaderControl>
    with TimeBatteryMixin {
  @override
  late final plPlayerController = widget.plPlayerController;

  @override
  bool get horizontalScreen => true;

  @override
  bool get isFullScreen => plPlayerController.isFullScreen.value;

  @override
  bool get isPortrait => false;

  @override
  Widget build(BuildContext context) {
    final isFullScreen = this.isFullScreen;
    showCurrTimeIfNeeded(isFullScreen);
    final liveController = widget.liveController;
    Widget child;
    child = Obx(
      key: titleKey,
      () => MarqueeText(
        liveController.title.value,
        spacing: 30,
        velocity: 30,
        strutStyle: const StrutStyle(fontSize: 18, leading: 0),
        style: const TextStyle(fontSize: 18, height: 1, color: Colors.white),
      ),
    );
    if (isFullScreen) {
      child = Column(
        spacing: 5,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          child,
          Wrap(
            spacing: 10,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (widget.upName case final upName?)
                Text(
                  upName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              liveController.watchedWidget,
              widget.onlineWidget,
              liveController.timeWidget,
            ],
          ),
        ],
      );
    }
    child = Expanded(child: child);

    const btnHeight = 48.0;

    return Padding(
      padding: const .symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          child,
          ...?timeBatteryWidgets,
          const SizedBox(width: 10),
          ComBtn(
            width: btnHeight,
            height: btnHeight,
            tooltip: '发弹幕',
            icon: const Icon(
              size: 18,
              Icons.comment_outlined,
              color: Colors.white,
            ),
            onTap: widget.onSendDanmaku,
          ),
          Obx(
            () => ComBtn(
              width: btnHeight,
              height: btnHeight,
              tooltip: '仅播放音频',
              onTap: () {
                plPlayerController.onlyPlayAudio.toggle();
                widget.onPlayAudio();
              },
              icon: plPlayerController.onlyPlayAudio.value
                  ? const Icon(
                      size: 18,
                      MdiIcons.musicCircle,
                      color: Colors.white,
                    )
                  : const Icon(
                      size: 18,
                      MdiIcons.musicCircleOutline,
                      color: Colors.white,
                    ),
            ),
          ),
          ComBtn(
            width: btnHeight,
            height: btnHeight,
            tooltip: '定时关闭',
            onTap: () => shutdownTimerService.showScheduleExitDialog(
              context,
              isFullScreen: isFullScreen,
              isLive: true,
            ),
            icon: const Icon(
              size: 18,
              Icons.schedule,
              color: Colors.white,
            ),
          ),
          if (plPlayerController.videoPlayerController case final player?)
            SizedBox.square(
              dimension: btnHeight,
              child: PopupMenuButton(
                iconSize: 18,
                padding: .zero,
                iconColor: Colors.white,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    height: 48,
                    onTap: _showLiveStreamDialog,
                    child: const Row(
                      spacing: 8,
                      children: [
                        Icon(Icons.alt_route, size: 17),
                        Text('切换路线', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    height: 48,
                    child: const Row(
                      spacing: 8,
                      children: [
                        Icon(Icons.info_outline, size: 17),
                        Text('播放信息', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                    onTap: () => HeaderControlState.showPlayerInfo(
                      context,
                      player: player,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showLiveStreamDialog() {
    final controller = widget.liveController;
    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = ColorScheme.of(context);
        final secondary = colorScheme.secondary;
        final onSurfaceVariant = colorScheme.onSurfaceVariant;
        final currStyle = TextStyle(fontSize: 14, color: secondary);
        return LiveTvDialog(
          title: '直播线路',
          maxWidth: 760,
          maxHeight: 560,
          content: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: controller.stream.mapIndexed((si, stream) {
              final isCurrStream = si == controller.streamIndex;
              final streamColor = isCurrStream ? secondary : onSurfaceVariant;
              return _ExpansionTile(
                initiallyExpanded: isCurrStream,
                iconColor: streamColor,
                collapsedIconColor: streamColor,
                title: Text(
                  stream.protocolName ?? si.toString(),
                  style: isCurrStream
                      ? currStyle
                      : const TextStyle(fontSize: 14),
                ),
                children: stream.format.mapIndexed((fi, format) {
                  final isCurrFormat =
                      isCurrStream && fi == controller.formatIndex;
                  final formatColor = isCurrFormat
                      ? secondary
                      : onSurfaceVariant;
                  return _ExpansionTile(
                    initiallyExpanded: isCurrFormat,
                    iconColor: formatColor,
                    collapsedIconColor: formatColor,
                    title: Text(
                      format.formatName ?? fi.toString(),
                      style: isCurrFormat
                          ? currStyle
                          : const TextStyle(fontSize: 14),
                    ),
                    children: format.codec.mapIndexed((ci, codec) {
                      final isCurrCodec =
                          isCurrFormat && ci == controller.codecIndex;
                      final codecColor = isCurrCodec
                          ? secondary
                          : onSurfaceVariant;
                      return _ExpansionTile(
                        initiallyExpanded: isCurrCodec,
                        iconColor: codecColor,
                        collapsedIconColor: codecColor,
                        title: Text(
                          '${codec.codecName ?? ci.toString()} (${LiveQuality.fromCode(codec.currentQn)?.desc ?? codec.currentQn})',
                          style: isCurrCodec
                              ? currStyle
                              : const TextStyle(fontSize: 14),
                        ),
                        children: codec.urlInfo.mapIndexed((ui, url) {
                          final isCurrUrl =
                              isCurrCodec && ui == controller.liveUrlIndex;
                          return ListTile(
                            minTileHeight: 48,
                            title: Text(
                              '${url.host}...',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: isCurrUrl
                                  ? const TextStyle(fontSize: 14)
                                  : TextStyle(
                                      fontSize: 14,
                                      color: onSurfaceVariant,
                                    ),
                            ),
                            selected: isCurrUrl,
                            onTap: isCurrUrl
                                ? null
                                : () {
                                    Get.back();
                                    controller.initLiveUrl(
                                      streamIndex: si,
                                      formatIndex: fi,
                                      codecIndex: ci,
                                      liveUrlIndex: ui,
                                    );
                                    GStorage.setting.put(
                                      SettingBoxKey.liveStream,
                                      [
                                        stream.protocolName!,
                                        format.formatName!,
                                        codec.codecName!,
                                      ],
                                    );
                                  },
                          );
                        }).toList(),
                      );
                    }).toList(),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _ExpansionTile extends ExpansionTile {
  const _ExpansionTile({
    required super.title,
    super.initiallyExpanded,
    super.iconColor,
    super.collapsedIconColor,
    super.children,
  }) : super(
         minTileHeight: 48,
         childrenPadding: const .only(left: 20),
       );
}
