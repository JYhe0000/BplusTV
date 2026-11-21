import 'dart:math';

import 'package:bplus_tv/common/widgets/emote_tooltip.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/common/widgets/loading_widget/loading_widget.dart';
import 'package:bplus_tv/common/widgets/scroll_physics.dart'
    show tabBarView, platformClampingPhysics;
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models/common/image_type.dart';
import 'package:bplus_tv/models_new/live/live_emote/datum.dart';
import 'package:bplus_tv/models_new/live/live_emote/emoticon.dart';
import 'package:bplus_tv/pages/live_emote/controller.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/utils/feed_back.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class LiveEmotePanel extends StatefulWidget {
  final int roomId;
  final Function(Emoticon emote, double? width, double? height) onChoose;
  final ValueChanged<Emoticon> onSendEmoticonUnique;
  const LiveEmotePanel({
    super.key,
    required this.roomId,
    required this.onChoose,
    required this.onSendEmoticonUnique,
  });

  @override
  State<LiveEmotePanel> createState() => _LiveEmotePanelState();
}

class _LiveEmotePanelState extends State<LiveEmotePanel>
    with AutomaticKeepAliveClientMixin {
  late final LiveEmotePanelController _emotePanelController;

  @override
  void initState() {
    super.initState();
    _emotePanelController = Get.put(
      LiveEmotePanelController(widget.roomId),
      tag: widget.roomId.toString(),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() => _buildBody(_emotePanelController.loadingState.value));
  }

  Widget _buildBody(LoadingState<List<LiveEmoteDatum>?> loadingState) {
    late final theme = Theme.of(context);
    return switch (loadingState) {
      Loading() => m3eLoading,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? Column(
                children: [
                  Expanded(
                    child: tabBarView(
                      controller: _emotePanelController.tabController,
                      children: response.map(
                        (item) {
                          final emote = item.emoticons;
                          if (emote == null || emote.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          final first = emote.first;
                          final widthFac = first.width == null
                              ? 1.0
                              : max(1.0, first.width! / 80);
                          final heightFac = first.height == null
                              ? 1.0
                              : max(1.0, first.height! / 80);
                          final width = widthFac * 38;
                          final height = heightFac * 38;
                          return GridView.builder(
                            physics: platformClampingPhysics,
                            padding: const .all(12),
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: widthFac * 40,
                                  mainAxisExtent: heightFac * 40,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                            itemCount: emote.length,
                            itemBuilder: (context, index) {
                              final e = emote[index];
                              return Material(
                                type: MaterialType.transparency,
                                child: InkWell(
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(6),
                                  ),
                                  onTap: () {
                                    if (item.pkgType == 3) {
                                      widget.onChoose(e, width, height);
                                    } else {
                                      widget.onSendEmoticonUnique(e);
                                    }
                                  },
                                  child: emoteTooltipBuilder(
                                    enable: true,
                                    size: 70,
                                    colorScheme: theme.colorScheme,
                                    url: e.url,
                                    emote: e.emoji,
                                    triggerMode: kTriggerMode,
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: NetworkImgLayer(
                                        fit: BoxFit.contain,
                                        src: e.url,
                                        width: width,
                                        height: height,
                                        type: ImageType.emote,
                                        quality: item.pkgType == 3 ? 1 : 80,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ).toList(),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: theme.dividerColor.withValues(alpha: 0.1),
                  ),
                  AnimatedBuilder(
                    animation: _emotePanelController.tabController!,
                    builder: (context, _) => Row(
                      children: [
                        for (int i = 0; i < response.length; i++)
                          _buildEmoteTab(i, response),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.viewPaddingOf(context).bottom),
                ],
              )
            : _errorWidget(),
      Error(:final errMsg) => _errorWidget(errMsg),
    };
  }

  Widget _errorWidget([String? errMsg]) => Center(
    child: TextButton.icon(
      onPressed: _emotePanelController.onReload,
      icon: const Icon(Icons.refresh),
      label: Text(errMsg ?? '没有数据'),
    ),
  );

  Widget _buildEmoteTab(int index, List<LiveEmoteDatum> response) {
    final selected = _emotePanelController.tabController!.index == index;
    return Expanded(
      child: TvFocusable(
        onTap: () {
          feedBack();
          if (!_emotePanelController.tabController!.indexIsChanging) {
            _emotePanelController.tabController!.animateTo(index);
          }
        },
        builder: (context, focused, hovered) => TvFocusHighlight(
          focused: focused,
          radius: 16,
          borderWidth: 2,
          // 图片 tab 无文字可着色：去选中底，改用主色描边指示选中
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: NetworkImgLayer(
              width: 24,
              height: 24,
              type: ImageType.emote,
              src: response[index].currentCover,
            ),
          ),
        ),
      ),
    );
  }
}
