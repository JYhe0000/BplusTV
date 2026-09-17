import 'package:PiliPlus/common/widgets/progress_bar/audio_video_progress_bar.dart';
import 'package:PiliPlus/pages/common/common_intro_controller.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/tv/tv_focus.dart';
import 'package:PiliPlus/utils/duration_utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

/// TV-native player control bar. Large, D-pad focusable buttons only; it does
/// not reuse the mobile control layout.
class TvBottomControl extends StatelessWidget {
  const TvBottomControl({
    super.key,
    required this.controller,
    required this.isFullScreen,
    this.introController,
  });

  final PlPlayerController controller;
  final bool isFullScreen;
  final CommonIntroController? introController;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(48, 24, 48, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0xD9000000)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!controller.isLive)
            Obx(
              () => ProgressBar(
                progress: controller.progress,
                buffered: controller.buffered.value,
                total: controller.duration.value,
                progressBarColor: colorScheme.primary,
                baseBarColor: const Color(0x40FFFFFF),
                bufferedBarColor: colorScheme.primary.withValues(alpha: 0.4),
                thumbColor: colorScheme.primary,
                thumbGlowColor: colorScheme.primary.withValues(alpha: 0.3),
                barHeight: 6,
                thumbRadius: 10,
                thumbGlowRadius: 30,
                onSeek: (milliseconds) {
                  controller
                    ..position.value = milliseconds ~/ 1000
                    ..onSeekEnd()
                    ..seekTo(Duration(milliseconds: milliseconds), isSeek: false);
                },
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              _TvControlButton(
                icon: Icons.play_arrow_rounded,
                tooltip: '播放/暂停',
                size: 40,
                onTap: controller.onDoubleTapCenter,
              ),
              if (introController != null) ...[
                _TvControlButton(
                  icon: Icons.skip_previous_rounded,
                  tooltip: '上一集',
                  onTap: () => introController!.prevPlay(),
                ),
                _TvControlButton(
                  icon: Icons.skip_next_rounded,
                  tooltip: '下一集',
                  onTap: () => introController!.nextPlay(),
                ),
              ],
              const SizedBox(width: 16),
              Obx(
                () => Text(
                  '${DurationUtils.formatDuration(controller.position.value)}'
                  ' / ${DurationUtils.formatDuration(controller.duration.value)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Obx(
                () => _TvControlButton(
                  icon: controller.enableShowDanmaku.value
                      ? Icons.subtitles_rounded
                      : Icons.subtitles_off_rounded,
                  tooltip: '弹幕开关',
                  onTap: () => controller.enableShowDanmaku.value =
                      !controller.enableShowDanmaku.value,
                ),
              ),
              _TvControlButton(
                icon: isFullScreen
                    ? Icons.fullscreen_exit_rounded
                    : Icons.fullscreen_rounded,
                tooltip: isFullScreen ? '退出全屏' : '全屏',
                size: 36,
                onTap: () =>
                    controller.triggerFullScreen(status: !isFullScreen),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TvControlButton extends StatelessWidget {
  const _TvControlButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 32,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: TvFocusable(
        onTap: onTap,
        builder: (context, focused, hovered) => TvFocusHighlight(
          radius: 14,
          focused: focused,
          child: Container(
            width: size + 28,
            height: size + 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: focused
                  ? Colors.white.withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: size),
          ),
        ),
      ),
    );
  }
}
