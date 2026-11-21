import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/models/search/search_esports.dart';
import 'package:bplus_tv/tv/tv_card.dart';
import 'package:bplus_tv/utils/app_scheme.dart';
import 'package:bplus_tv/utils/date_utils.dart';
import 'package:bplus_tv/utils/page_utils.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:material_ui/material_ui.dart';

class SearchEsportsItem extends StatelessWidget {
  const SearchEsportsItem({
    super.key,
    required this.item,
  });

  final SearchEsports item;

  @override
  Widget build(BuildContext context) {
    // contest 可能为空列表，直接取 first 会抛 StateError
    if (item.contest.isEmpty) {
      return const SizedBox.shrink();
    }
    final colorScheme = ColorScheme.of(context);
    final configInfo = item.configInfo;
    final contest = item.contest.first;

    Widget buildTeamWidget(EsportsTeam team) {
      return Column(
        spacing: 6,
        mainAxisSize: .min,
        children: [
          NetworkImgLayer(
            src: team.logoFull,
            width: 50,
            height: 50,
            type: .emote,
            fit: .contain,
          ),
          Text(
            team.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      );
    }

    Widget btn;
    if (contest.contestStatus == 2) {
      btn = FilledButton.tonal(
        style: const ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(96, 48)),
          visualDensity: .standard,
          tapTargetSize: .shrinkWrap,
          padding: WidgetStatePropertyAll(.symmetric(horizontal: 16)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: .all(.circular(6))),
          ),
        ),
        onPressed: () => PageUtils.toLiveRoom(contest.liveRoom),
        child: const Text('观看直播'),
      );
    } else {
      final style = ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(96, 48)),
        visualDensity: .standard,
        tapTargetSize: .shrinkWrap,
        padding: const WidgetStatePropertyAll(.symmetric(horizontal: 16)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: const .all(.circular(6)),
            side: BorderSide(color: colorScheme.outline),
          ),
        ),
        foregroundColor: WidgetStatePropertyAll(colorScheme.onSurfaceVariant),
      );

      btn = OutlinedButton(
        style: style,
        onPressed: () => PageUtils.toLiveRoom(contest.liveRoom),
        child: const Text('直播间'),
      );

      if (contest.playback?.isNotEmpty ?? false) {
        btn = Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            OutlinedButton(
              style: style,
              onPressed: () => PiliScheme.routePushFromUrl(contest.playback!),
              child: const Text('回放'),
            ),
            btn,
          ],
        );
      }
    }

    return Padding(
      padding: const .symmetric(vertical: 5),
      child: Center(
        child: TvCard(
          onTap: () => Get.toNamed(
            '/matchInfo',
            parameters: {'cid': contest.id.toString()},
          ),
          radius: 16,
          child: Padding(
            padding: const .symmetric(vertical: 12, horizontal: 16),
            child: Column(
              mainAxisSize: .min,
              children: [
                Text(
                  configInfo.esportTitle,
                  style: const TextStyle(fontWeight: .bold, fontSize: 16),
                ),
                Padding(
                  padding: const .only(top: 4),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        if (contest.gameStage != null)
                          TextSpan(text: contest.gameStage),
                        if (contest.contestStatus == 1 && contest.stime != null)
                          TextSpan(
                            text: '  ${DateFormatUtils.format(contest.stime)}',
                          ),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.outline,
                    ),
                  ),
                ),
                Row(
                  spacing: 20,
                  mainAxisSize: .max,
                  mainAxisAlignment: .center,
                  children: [
                    Expanded(child: buildTeamWidget(contest.homeTeam)),
                    Text(
                      contest.contestStatus == 1
                          ? 'VS'
                          : '${contest.homeScore} : ${contest.awayScore}',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: .bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Expanded(child: buildTeamWidget(contest.awayTeam)),
                  ],
                ),
                const SizedBox(height: 10),
                btn,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
