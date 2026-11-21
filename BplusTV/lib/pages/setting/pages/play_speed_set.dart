import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/pages/setting/widgets/tv_setting_tile.dart';
import 'package:bplus_tv/tv/tv_back_bar.dart';
import 'package:bplus_tv/tv/tv_page_focus.dart';
import 'package:bplus_tv/tv/tv_text_input.dart';
import 'package:bplus_tv/utils/storage.dart';
import 'package:bplus_tv/utils/storage_key.dart';
import 'package:bplus_tv/utils/storage_pref.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:material_ui/material_ui.dart';

class PlaySpeedPage extends StatefulWidget {
  const PlaySpeedPage({super.key});

  @override
  State<PlaySpeedPage> createState() => _PlaySpeedPageState();
}

class _PlaySpeedPageState extends State<PlaySpeedPage> {
  late double _defaultSpeed = Pref.playSpeedDefault;
  late final List<double> _speeds = List<double>.of(Pref.speedList)..sort();

  Future<void> _addSpeed() async {
    final input = await showTvTextInput(context, title: '添加播放倍速', maxLength: 6);
    if (input == null || !mounted) return;
    final speed = double.tryParse(input.trim());
    if (speed == null || !speed.isFinite || speed < 0.1 || speed > 8) {
      SmartDialog.showToast('请输入 0.1 到 8 之间的倍速');
      return;
    }
    if (_speeds.contains(speed)) {
      SmartDialog.showToast('该倍速已存在');
      return;
    }
    final updated = [..._speeds, speed]..sort();
    await GStorage.video.put(VideoBoxKey.speedsList, updated);
    if (mounted) {
      setState(
        () => _speeds
          ..clear()
          ..addAll(updated),
      );
    }
  }

  Future<void> _select(double speed) async {
    await GStorage.video.put(VideoBoxKey.playSpeedDefault, speed);
    if (mounted) setState(() => _defaultSpeed = speed);
  }

  Future<void> _remove(double speed) async {
    if (speed == _defaultSpeed || _speeds.length <= 1) return;
    final updated = _speeds.where((value) => value != speed).toList();
    await GStorage.video.put(VideoBoxKey.speedsList, updated);
    if (mounted) {
      setState(
        () => _speeds
          ..clear()
          ..addAll(updated),
      );
    }
  }

  @override
  Widget build(BuildContext context) => TvPageFocus(
    child: SimpleScaffold(
      appBar: tvBackBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
            children: [
              Text(
                '播放倍速',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text('确认选择默认倍速，右侧删除不需要的档位。'),
              const SizedBox(height: 18),
              for (final speed in _speeds)
                Padding(
                  key: ValueKey(speed),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TvSettingTile(
                          title: Text('$speed×'),
                          subtitle: Text(
                            speed == _defaultSpeed ? '默认播放倍速' : '设为默认',
                          ),
                          trailing: speed == _defaultSpeed
                              ? const Icon(Icons.check_rounded)
                              : null,
                          onTap: () => _select(speed),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 152,
                        child: TvSettingTile(
                          title: const Text('删除'),
                          enabled: speed != _defaultSpeed && _speeds.length > 1,
                          onTap: () => _remove(speed),
                        ),
                      ),
                    ],
                  ),
                ),
              TvSettingTile(
                title: const Text('添加倍速'),
                leading: const Icon(Icons.add_rounded),
                onTap: _addSpeed,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
