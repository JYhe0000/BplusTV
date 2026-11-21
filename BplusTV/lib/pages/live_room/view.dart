import 'dart:io';
import 'dart:math';

import 'package:bplus_tv/common/assets.dart';
import 'package:bplus_tv/common/widgets/button/icon_button.dart';
import 'package:bplus_tv/common/widgets/custom_icon.dart';
import 'package:bplus_tv/common/widgets/extra_hittest_stack.dart';
import 'package:bplus_tv/common/widgets/flutter/pop_scope.dart';
import 'package:bplus_tv/common/widgets/gesture/horizontal_drag_gesture_recognizer.dart';
import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/common/widgets/keep_alive_wrapper.dart';
import 'package:bplus_tv/common/widgets/route_aware_mixin.dart';
import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/common/widgets/scroll_physics.dart'
    show tabBarScrollPhysics;
import 'package:bplus_tv/models/common/live/live_contribution_rank_type.dart';
import 'package:bplus_tv/models_new/live/live_room_info_h5/data.dart';
import 'package:bplus_tv/models_new/live/live_superchat/item.dart';
import 'package:bplus_tv/pages/danmaku/danmaku_model.dart';
import 'package:bplus_tv/pages/live/widgets/live_tv_dialog.dart';
import 'package:bplus_tv/pages/live_room/contribution_rank/controller.dart';
import 'package:bplus_tv/pages/live_room/contribution_rank/view.dart';
import 'package:bplus_tv/pages/live_room/controller.dart';
import 'package:bplus_tv/pages/live_room/superchat/superchat_card.dart';
import 'package:bplus_tv/pages/live_room/superchat/superchat_panel.dart';
import 'package:bplus_tv/pages/live_room/widgets/bottom_control.dart';
import 'package:bplus_tv/pages/live_room/widgets/chat_panel.dart';
import 'package:bplus_tv/pages/live_room/widgets/header_control.dart';
import 'package:bplus_tv/pages/video/widgets/player_focus.dart';
import 'package:bplus_tv/plugin/pl_player/controller.dart';
import 'package:bplus_tv/plugin/pl_player/models/play_status.dart';
import 'package:bplus_tv/plugin/pl_player/utils/danmaku_options.dart';
import 'package:bplus_tv/plugin/pl_player/utils/fullscreen.dart';
import 'package:bplus_tv/plugin/pl_player/view/view.dart';
import 'package:bplus_tv/services/service_locator.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/utils/android/bindings.g.dart';
import 'package:bplus_tv/utils/extension/num_ext.dart';
import 'package:bplus_tv/utils/extension/theme_ext.dart';
import 'package:bplus_tv/utils/image_utils.dart';
import 'package:bplus_tv/utils/max_screen_size.dart';
import 'package:bplus_tv/utils/mobile_observer.dart';
import 'package:bplus_tv/utils/page_utils.dart';
import 'package:bplus_tv/utils/storage.dart';
import 'package:bplus_tv/utils/storage_key.dart';
import 'package:bplus_tv/utils/storage_pref.dart';
import 'package:bplus_tv/utils/theme_utils.dart';
import 'package:bplus_tv/utils/utils.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:canvas_danmaku/danmaku_screen.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:screen_brightness_platform_interface/screen_brightness_platform_interface.dart';

const baseWhite = Color(0xFFEEEEEE);

class LiveRoomPage extends StatefulWidget {
  const LiveRoomPage({super.key});

  @override
  State<LiveRoomPage> createState() => _LiveRoomPageState();
}

class _LiveRoomPageState extends State<LiveRoomPage>
    with WidgetsBindingObserver, RouteAware, RouteAwareMixin {
  late final fullScreenSCWidth = Pref.fullScreenSCWidth;
  final String heroTag = Utils.generateRandomString(6);
  late final LiveRoomController _liveRoomController;
  late final PlPlayerController plPlayerController;
  bool get isFullScreen => plPlayerController.isFullScreen.value;

  late final GlobalKey pageKey = GlobalKey();
  late final GlobalKey chatKey = GlobalKey();
  late final GlobalKey scKey = GlobalKey();
  late final GlobalKey playerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    addObserverMobile(this);
    _liveRoomController = Get.put(
      LiveRoomController(heroTag),
      tag: heroTag,
    );
    plPlayerController = _liveRoomController.plPlayerController
      ..addStatusListener(playerListener);
    PlPlayerController.setPlayCallBack(plPlayerController.play);
    if (plPlayerController.removeSafeArea) {
      hideSystemBar();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (plPlayerController.removeSafeArea) {
      padding = .zero;
    } else {
      padding = MediaQuery.viewPaddingOf(context);
    }
    final size = MediaQuery.sizeOf(context);
    maxWidth = size.width;
    maxHeight = size.height;
    isWindowMode = MaxScreenSize.isWindowMode(
      width: maxWidth * plPlayerController.uiScale,
      height: maxHeight * plPlayerController.uiScale,
    );
    isPortrait = false;
    plPlayerController.screenRatio = maxHeight / maxWidth;
  }

  @override
  Future<void> didPopNext() async {
    if (!plPlayerController.isLive) {
      plPlayerController.isLive = true;
      _liveRoomController.isLoaded.refresh();
    }
    plPlayerController.danmakuController =
        _liveRoomController.danmakuController;
    PlPlayerController.setPlayCallBack(plPlayerController.play);
    _liveRoomController.startLiveTimer();
    if (plPlayerController.playerStatus.isPlaying &&
        plPlayerController.cid == null) {
      _liveRoomController
        ..danmakuController?.resume()
        ..startLiveMsg();
    } else {
      final shouldPlay = _liveRoomController.isPlaying ?? false;
      if (shouldPlay) {
        _liveRoomController
          ..danmakuController?.resume()
          ..startLiveMsg();
      }
      await _liveRoomController.playerInit(autoplay: shouldPlay);
    }
    if (!mounted) return;
    plPlayerController.addStatusListener(playerListener);
    super.didPopNext();
  }

  @override
  void didPushNext() {
    removeObserverMobile(this);
    plPlayerController.removeStatusListener(playerListener);
    _liveRoomController
      ..danmakuController?.clear()
      ..cancelLiveTimer()
      ..closeLiveMsg()
      ..isPlaying = plPlayerController.playerStatus.isPlaying;
    super.didPushNext();
  }

  void playerListener(PlayerStatus status) {
    if (status.isPlaying) {
      _liveRoomController
        ..danmakuController?.resume()
        ..startLiveTimer()
        ..startLiveMsg();
    } else {
      _liveRoomController
        ..danmakuController?.pause()
        ..cancelLiveTimer()
        ..closeLiveMsg();
    }
  }

  @override
  void dispose() {
    removeObserverMobile(this);
    videoPlayerServiceHandler?.onVideoDetailDispose(heroTag);
    if (Platform.isAndroid && !plPlayerController.setSystemBrightness) {
      ScreenBrightnessPlatform.instance.resetApplicationScreenBrightness();
    }
    PlPlayerController.setPlayCallBack(null);
    plPlayerController
      ..removeStatusListener(playerListener)
      ..dispose();
    for (final e in LiveContributionRankType.values) {
      Get.delete<ContributionRankController>(
        tag: '${_liveRoomController.roomId}${e.name}',
      );
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (plPlayerController.visible = state == .resumed) {
      if (!plPlayerController.showDanmaku) {
        _liveRoomController
          ..refreshMsgIfNeeded()
          ..startLiveTimer();
        plPlayerController.showDanmaku = true;
      }
    } else if (state == .paused) {
      _liveRoomController.cancelLiveTimer();
      plPlayerController
        ..showDanmaku = false
        ..danmakuController?.clear();
    }
  }

  late double maxWidth;
  late double maxHeight;
  bool isWindowMode = false;
  late EdgeInsets padding;
  late bool isPortrait;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (Platform.isAndroid && AndroidHelper.isPipMode) {
      child = videoPlayerPanel(
        isFullScreen,
        width: maxWidth,
        height: maxHeight,
        isPipMode: true,
        needDm: !plPlayerController.pipNoDanmaku,
      );
    } else {
      child = childWhenDisabled;
    }
    if (plPlayerController.keyboardControl) {
      child = PlayerFocus(
        // TV 端初始焦点由播放器手势处理器接管，避免 autofocus 竞争。
        autofocus: false,
        plPlayerController: plPlayerController,
        onSendDanmaku: _liveRoomController.onSendDanmaku,
        onRefresh: _liveRoomController.queryLiveUrl,
        child: child,
      );
    }
    return Theme(
      data: ThemeUtils.darkTheme,
      child: child,
    );
  }

  Widget videoPlayerPanel(
    bool isFullScreen, {
    required double width,
    required double height,
    bool isPipMode = false,
    Color fill = Colors.black,
    Alignment alignment = Alignment.center,
    bool needDm = true,
  }) {
    if (!isFullScreen) {
      _liveRoomController.fsSC.value = null;
    }
    _liveRoomController.isFullScreen = isFullScreen;
    Widget player = Obx(
      key: playerKey,
      () {
        if (_liveRoomController.isLoaded.value && plPlayerController.isLive) {
          final roomInfoH5 = _liveRoomController.roomInfoH5.value;
          return PLVideoPlayer(
            maxWidth: width,
            maxHeight: height,
            fill: fill,
            alignment: alignment,
            plPlayerController: plPlayerController,
            headerControl: LiveHeaderControl(
              key: _liveRoomController.headerKey,
              title: roomInfoH5?.roomInfo?.title,
              upName: roomInfoH5?.anchorInfo?.baseInfo?.uname,
              plPlayerController: plPlayerController,
              onSendDanmaku: _liveRoomController.onSendDanmaku,
              onPlayAudio: _liveRoomController.queryLiveUrl,
              isPortrait: false,
              liveController: _liveRoomController,
              onlineWidget: onlineWidget,
            ),
            bottomControl: BottomControl(
              plPlayerController: plPlayerController,
              liveRoomCtr: _liveRoomController,
              onRefresh: _liveRoomController.queryLiveUrl,
            ),
            danmuWidget: !needDm
                ? null
                : LiveDanmaku(
                    liveRoomController: _liveRoomController,
                    plPlayerController: plPlayerController,
                    isFullScreen: isFullScreen,
                    isPipMode: isPipMode,
                    size: Size(width, height),
                  ),
          );
        }
        return const SizedBox.shrink();
      },
    );
    if (_liveRoomController.showSuperChat && isFullScreen) {
      player = Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: player),
          if (kDebugMode) ...[
            Positioned(
              top: 50,
              right: 0,
              child: TextButton(
                onPressed: () {
                  final item = SuperChatItem.random;
                  _liveRoomController
                    ..fsSC.value = item
                    ..addDm(item);
                },
                child: const Text('add superchat'),
              ),
            ),
            Positioned(
              right: 0,
              top: 90,
              child: TextButton(
                onPressed: () {
                  _liveRoomController.fsSC.value = null;
                },
                child: const Text('remove superchat'),
              ),
            ),
          ],
          Positioned(
            left: padding.left + 25,
            bottom: 25,
            width: fullScreenSCWidth,
            child: Obx(() {
              final item = _liveRoomController.fsSC.value;
              if (item == null) {
                return const SizedBox.shrink();
              }
              try {
                return ExtraHitTestStack(
                  key: ValueKey(item.id),
                  clipBehavior: Clip.none,
                  children: [
                    SuperChatCard(
                      item: item,
                      onRemove: () => _liveRoomController.fsSC.value = null,
                      onReport: () => _liveRoomController.reportSC(item),
                    ),
                    Positioned(
                      right: -6,
                      top: -6,
                      child: iconButton(
                        size: 48,
                        iconSize: 20,
                        bgColor: const Color(0xEEFFFFFF),
                        iconColor: Colors.black54,
                        icon: const Icon(Icons.clear),
                        onPressed: () => _liveRoomController.fsSC.value = null,
                      ),
                    ),
                  ],
                );
              } catch (_) {
                if (kDebugMode) rethrow;
                return const SizedBox.shrink();
              }
            }),
          ),
        ],
      );
    }
    return popScope(
      canPop: !isFullScreen,
      onPopInvokedWithResult: (didPop, result) {},
      child: player,
    );
  }

  Widget get childWhenDisabled {
    return Obx(() {
      final isFullScreen = this.isFullScreen;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          const SizedBox.expand(child: ColoredBox(color: Colors.black)),
          if (!isFullScreen)
            Obx(
              () {
                final appBackground = _liveRoomController
                    .roomInfoH5
                    .value
                    ?.roomInfo
                    ?.appBackground;
                Widget child;
                if (appBackground != null && appBackground.isNotEmpty) {
                  child = CachedNetworkImage(
                    fit: BoxFit.cover,
                    width: maxWidth,
                    height: maxHeight,
                    memCacheWidth: maxWidth.cacheSize(context),
                    imageUrl: ImageUtils.safeThumbnailUrl(appBackground),
                    placeholder: (_, _) => const SizedBox.shrink(),
                  );
                } else {
                  child = Image.asset(
                    Assets.livingBackground,
                    fit: BoxFit.cover,
                    width: maxWidth,
                    height: maxHeight,
                    cacheWidth: maxWidth.cacheSize(context),
                  );
                }
                return Positioned.fill(
                  child: Opacity(opacity: 0.6, child: child),
                );
              },
            ),
          ScaffoldLayout(
            appBar: isWindowMode && isFullScreen && !isPortrait
                ? null
                : _buildAppBar(isFullScreen),
            body: isPortrait
                ? _buildPP(isFullScreen)
                : _buildBodyH(isFullScreen),
          ),
        ],
      );
    });
  }

  Widget _buildPP(bool isFullScreen) {
    final bottomHeight = 70 + padding.bottom;
    final videoHeight = isFullScreen
        ? maxHeight - (isWindowMode && !isPortrait ? 0 : padding.top)
        : maxHeight - bottomHeight;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          bottom: isFullScreen ? 0 : bottomHeight,
          child: videoPlayerPanel(
            width: maxWidth,
            height: videoHeight,
            isFullScreen,
            needDm: isFullScreen,
            alignment: isFullScreen ? Alignment.center : Alignment.topCenter,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 55 + bottomHeight,
          height: maxHeight * 0.32,
          child: Offstage(
            offstage: isFullScreen,
            child: _buildChatWidget(true),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: bottomHeight,
          child: Offstage(
            offstage: isFullScreen,
            child: _buildInputWidget,
          ),
        ),
      ],
    );
  }

  Widget get onlineWidget => TextButton(
    onPressed: _showRank,
    style: TextButton.styleFrom(
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      foregroundColor: Colors.white,
    ),
    child: Obx(() {
      if (_liveRoomController.onlineCount.value case final onlineCount?) {
        return Text(
          '高能观众($onlineCount)',
          style: const TextStyle(fontSize: 12, color: Colors.white),
        );
      }
      return const SizedBox.shrink();
    }),
  );

  void _showRank() {
    if (_liveRoomController.ruid case final ruid?) {
      {
        showDialog(
          context: context,
          builder: (_) => LiveTvDialog(
            title: '高能观众',
            maxWidth: 560,
            maxHeight: 620,
            content: ContributionRankPanel(
              ruid: ruid,
              roomId: _liveRoomController.roomId,
            ),
          ),
        );
        return;
      }
    }
  }

  PreferredSizeWidget _buildAppBar(bool isFullScreen) {
    return AppBar(
      primary: !plPlayerController.removeSafeArea,
      toolbarHeight: isFullScreen ? 0 : 64,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      titleTextStyle: const TextStyle(color: Colors.white),
      title: isFullScreen
          ? null
          : Obx(
              () {
                RoomInfoH5Data? roomInfoH5 =
                    _liveRoomController.roomInfoH5.value;
                if (roomInfoH5 == null) {
                  return const SizedBox.shrink();
                }
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () =>
                      Get.toNamed('/member?mid=${roomInfoH5.roomInfo?.uid}'),
                  child: Row(
                    spacing: 10,
                    mainAxisSize: .min,
                    children: [
                      NetworkImgLayer(
                        width: 42,
                        height: 42,
                        type: .avatar,
                        src: roomInfoH5.anchorInfo!.baseInfo!.face,
                      ),
                      Flexible(
                        child: Column(
                          spacing: 1,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              spacing: 10,
                              mainAxisSize: .min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: Text(
                                    roomInfoH5.anchorInfo!.baseInfo!.uname!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                onlineWidget,
                              ],
                            ),
                            Row(
                              spacing: 10,
                              mainAxisSize: .min,
                              children: [
                                _liveRoomController.watchedWidget,
                                _liveRoomController.timeWidget,
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      actions: [
        // IconButton(
        //   tooltip: '刷新',
        //   onPressed: _liveRoomController.queryLiveUrl,
        //   icon: const Icon(Icons.refresh, size: 20),
        // ),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert, size: 20),
          itemBuilder: (BuildContext context) {
            final liveUrl =
                'https://live.bilibili.com/${_liveRoomController.roomId}';
            return <PopupMenuEntry>[
              PopupMenuItem(
                onTap: () => Utils.copyText(liveUrl),
                child: const Row(
                  spacing: 10,
                  mainAxisSize: .min,
                  children: [
                    Icon(Icons.copy, size: 19),
                    Text('复制链接'),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: () => PageUtils.inAppWebview(liveUrl, off: true),
                child: const Row(
                  spacing: 10,
                  mainAxisSize: .min,
                  children: [
                    Icon(Icons.open_in_browser, size: 19),
                    Text('浏览器打开'),
                  ],
                ),
              ),
              if (_liveRoomController.roomInfoH5.value != null)
                PopupMenuItem(
                  onTap: () {
                    try {
                      RoomInfoH5Data roomInfo =
                          _liveRoomController.roomInfoH5.value!;
                      PageUtils.pmShare(
                        this.context,
                        content: {
                          "cover": roomInfo.roomInfo!.cover!,
                          "sourceID": _liveRoomController.roomId.toString(),
                          "title": roomInfo.roomInfo!.title!,
                          "url": liveUrl,
                          "authorID": roomInfo.roomInfo!.uid.toString(),
                          "source": "直播",
                          "desc": roomInfo.roomInfo!.title!,
                          "author": roomInfo.anchorInfo!.baseInfo!.uname,
                        },
                      );
                    } catch (e) {
                      SmartDialog.showToast(e.toString());
                    }
                  },
                  child: const Row(
                    spacing: 10,
                    mainAxisSize: .min,
                    children: [
                      Icon(Icons.forward_to_inbox, size: 19),
                      Text('分享至消息'),
                    ],
                  ),
                ),
            ];
          },
        ),
      ],
    );
  }

  Widget _buildBodyH(bool isFullScreen) {
    return Padding(
      padding: isFullScreen
          ? EdgeInsets.zero
          : EdgeInsets.only(
              left: padding.left,
              right: padding.right,
              bottom: padding.bottom,
            ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final height = constraints.maxHeight;
          final compact = availableWidth < 1000;
          final rightWidth = (availableWidth * (compact ? 0.34 : 0.28))
              .clamp(248.0, 384.0)
              .toDouble();
          final gap = isFullScreen ? 0.0 : 12.0;
          final width = isFullScreen
              ? availableWidth
              : max(0.0, availableWidth - rightWidth - gap);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: width,
                child: videoPlayerPanel(
                  isFullScreen,
                  fill: Colors.transparent,
                  width: width,
                  height: height,
                ),
              ),
              SizedBox(width: gap),
              Offstage(
                offstage: isFullScreen,
                child: ExcludeFocus(
                  excluding: isFullScreen,
                  child: SizedBox(
                    width: rightWidth,
                    child: _buildBottomWidget,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget get _buildBottomWidget => NetflixPlayerSurface(
    radius: 16,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_liveRoomController.showSuperChat)
          SizedBox(
            height: 48,
            child: Obx(
              () => Row(
                children: [
                  for (var index = 0; index < 2; index++)
                    Expanded(
                      child: TextButton(
                        onPressed: () =>
                            _liveRoomController.pageController?.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                            ),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          foregroundColor:
                              _liveRoomController.pageIndex.value == index
                              ? Colors.white
                              : Colors.white54,
                        ),
                        child: Text(index == 0 ? '聊天' : '醒目留言'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        Expanded(child: _buildChatWidget()),
        _buildInputWidget,
      ],
    ),
  );

  Widget _buildChatWidget([bool isPP = false]) {
    Widget chat() => LiveRoomChatPanel(
      key: chatKey,
      isPP: isPP,
      liveRoomController: _liveRoomController,
    );
    return Padding(
      padding: .only(bottom: 12, top: isPortrait ? 12 : 0),
      child: _liveRoomController.showSuperChat
          ? PageView(
              key: pageKey,
              controller: _liveRoomController.pageController,
              physics: tabBarScrollPhysics,
              onPageChanged: _liveRoomController.pageIndex.call,
              horizontalDragGestureRecognizer:
                  CustomHorizontalDragGestureRecognizer.new,
              children: [
                KeepAliveWrapper(child: chat()),
                SuperChatPanel(
                  key: scKey,
                  controller: _liveRoomController,
                ),
              ],
            )
          : chat(),
    );
  }

  Widget get _buildInputWidget {
    final child = Container(
      padding: const EdgeInsets.only(top: 5, left: 10, right: 10),
      height: 70,
      decoration: const BoxDecoration(
        borderRadius: .vertical(top: .circular(20)),
        border: Border(top: BorderSide(color: Color(0x1AFFFFFF))),
        color: Color(0x1AFFFFFF),
      ),
      child: Padding(
        padding: const .only(top: 5, bottom: 10),
        child: Align(
          alignment: .topCenter,
          child: Row(
            spacing: 6,
            children: [
              Obx(
                () {
                  final enableShowLiveDanmaku =
                      plPlayerController.enableShowLiveDanmaku.value;
                  return SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      style: IconButton.styleFrom(padding: .zero),
                      onPressed: () {
                        final newVal = !enableShowLiveDanmaku;
                        plPlayerController.enableShowLiveDanmaku.value = newVal;
                        if (!plPlayerController.tempPlayerConf) {
                          GStorage.setting.put(
                            SettingBoxKey.enableShowLiveDanmaku,
                            newVal,
                          );
                        }
                      },
                      icon: enableShowLiveDanmaku
                          ? const Icon(
                              size: 22,
                              CustomIcons.dm_on,
                              color: baseWhite,
                            )
                          : const Icon(
                              size: 22,
                              CustomIcons.dm_off,
                              color: baseWhite,
                            ),
                    ),
                  );
                },
              ),
              Expanded(
                child: TvFocusable(
                  onTap: _liveRoomController.onSendDanmaku,
                  builder: (context, focused, hovered) => TvFocusHighlight(
                    focused: focused,
                    radius: 10,
                    child: const SizedBox(
                      height: 48,
                      child: Center(
                        child: Text('发弹幕', style: TextStyle(color: baseWhite)),
                      ),
                    ),
                  ),
                ),
              ),
              Builder(
                builder: (context) {
                  final isLogin = kDebugMode || _liveRoomController.isLogin;
                  final colorScheme = ColorScheme.of(context);
                  return Material(
                    type: MaterialType.transparency,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        TvFocusable(
                          onTap: isLogin
                              ? () {
                                  _liveRoomController.onLikeTapDown(null);
                                  _liveRoomController.onLikeTapUp();
                                }
                              : _liveRoomController.toastNotLogin,
                          builder: (context, focused, hovered) =>
                              TvFocusHighlight(
                                focused: focused,
                                radius: 24,
                                child: const SizedBox.square(
                                  dimension: 48,
                                  child: Icon(
                                    size: 22,
                                    color: baseWhite,
                                    Icons.thumb_up_off_alt,
                                  ),
                                ),
                              ),
                        ),
                        Positioned(
                          left: 30,
                          top: -12,
                          child: Obx(() {
                            final likeClickTime =
                                _liveRoomController.likeClickTime.value;
                            if (likeClickTime == 0) {
                              return const SizedBox.shrink();
                            }
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 160),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: child,
                                );
                              },
                              child: Text(
                                key: ValueKey(likeClickTime),
                                'x$likeClickTime',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: colorScheme.isDark
                                      ? colorScheme.primary
                                      : colorScheme.inversePrimary,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  style: IconButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () => _liveRoomController.onSendDanmaku(true),
                  icon: const Icon(
                    size: 22,
                    color: baseWhite,
                    Icons.emoji_emotions_outlined,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (_liveRoomController.showSuperChat) {
      return Stack(
        children: [
          child,
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            child: Obx(
              () => _BorderIndicator(
                radius: const Radius.circular(20),
                isLeft: _liveRoomController.pageIndex.value == 0,
              ),
            ),
          ),
        ],
      );
    }
    return child;
  }
}

class _BorderIndicator extends LeafRenderObjectWidget {
  const _BorderIndicator({
    required this.radius,
    required this.isLeft,
  });

  final Radius radius;
  final bool isLeft;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderBorderIndicator(
      radius: radius,
      isLeft: isLeft,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderBorderIndicator renderObject,
  ) {
    renderObject
      ..radius = radius
      ..isLeft = isLeft;
  }
}

class _RenderBorderIndicator extends RenderBox {
  _RenderBorderIndicator({
    required this._radius,
    required this._isLeft,
  });

  Radius _radius;
  Radius get radius => _radius;
  set radius(Radius value) {
    if (_radius == value) return;
    _radius = value;
    markNeedsLayout();
  }

  bool _isLeft;
  bool get isLeft => _isLeft;
  set isLeft(bool value) {
    if (_isLeft == value) return;
    _isLeft = value;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    size = constraints.constrainDimensions(constraints.maxWidth, _radius.x);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final size = this.size;
    final canvas = context.canvas;
    final width = size.width / 2;

    BoxBorder.paintNonUniformBorder(
      canvas,
      Rect.fromLTWH(
        offset.dx + (_isLeft ? 0 : width),
        offset.dy,
        width,
        size.height,
      ),
      borderRadius: BorderRadius.only(
        topLeft: _isLeft ? _radius : .zero,
        topRight: _isLeft ? .zero : _radius,
      ),
      textDirection: null,
      top: const BorderSide(),
      color: Colors.white38,
    );
  }
}

class LiveDanmaku extends StatefulWidget {
  final LiveRoomController liveRoomController;
  final PlPlayerController plPlayerController;
  final bool isPipMode;
  final bool isFullScreen;
  final Size size;

  const LiveDanmaku({
    super.key,
    required this.liveRoomController,
    required this.plPlayerController,
    this.isPipMode = false,
    required this.isFullScreen,
    required this.size,
  });

  @override
  State<LiveDanmaku> createState() => _LiveDanmakuState();

  bool get notFullscreen => !isFullScreen || isPipMode;
}

class _LiveDanmakuState extends State<LiveDanmaku> {
  PlPlayerController get plPlayerController => widget.plPlayerController;

  @override
  void didUpdateWidget(LiveDanmaku oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notFullscreen != widget.notFullscreen &&
        !DanmakuOptions.sameFontScale) {
      plPlayerController.danmakuController?.updateOption(
        DanmakuOptions.get(notFullscreen: widget.notFullscreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final option = DanmakuOptions.get(notFullscreen: widget.notFullscreen);
    return Obx(
      () => AnimatedOpacity(
        opacity: plPlayerController.enableShowLiveDanmaku.value
            ? plPlayerController.danmakuOpacity.value
            : 0,
        duration: const Duration(milliseconds: 100),
        child: DanmakuScreen<DanmakuExtra>(
          createdController: (e) {
            widget.liveRoomController.danmakuController =
                plPlayerController.danmakuController = e;
          },
          option: option,
          size: widget.size,
        ),
      ),
    );
  }
}
