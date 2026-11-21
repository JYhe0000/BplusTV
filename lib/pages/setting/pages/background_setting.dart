import 'dart:io';

import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/models/common/theme/background_scene.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_page_focus.dart';
import 'package:bplus_tv/tv/tv_back_bar.dart';
import 'package:bplus_tv/utils/storage.dart';
import 'package:bplus_tv/utils/storage_key.dart';
import 'package:bplus_tv/utils/storage_pref.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

class BackgroundSettingPage extends StatefulWidget {
  const BackgroundSettingPage({super.key});

  @override
  State<BackgroundSettingPage> createState() => _BackgroundSettingPageState();
}

class _BackgroundSettingPageState extends State<BackgroundSettingPage> {
  late BackgroundScene _selected = Pref.backgroundScene;
  late String _customImage = Pref.backgroundImage ?? '';
  late ColorScheme _colorScheme;
  bool _pickingImage = false;

  bool get _hasCustomImage => _customImage.isNotEmpty;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _colorScheme = ColorScheme.of(context);
  }

  Future<void> _onSelected(BackgroundScene value) async {
    if (!_hasCustomImage && value == _selected) return;
    setState(() {
      _selected = value;
      _customImage = '';
    });
    await GStorage.setting.put(SettingBoxKey.backgroundScene, value.index);
    await GStorage.setting.delete(SettingBoxKey.backgroundImage);
    Pref.backgroundImagePath.value = '';
    SmartDialog.showToast('设置成功');
    Get.appUpdate();
  }

  Future<void> _onTapCustomTile() async {
    if (_pickingImage) return;
    _pickingImage = true;
    try {
      final path = await _pickViaSystemPicker();
      if (path == null || path.isEmpty || !mounted) return;
      await _applyCustomImage(path);
    } finally {
      _pickingImage = false;
    }
  }

  Future<String?> _pickViaSystemPicker() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const [
          'jpg',
          'jpeg',
          'png',
          'webp',
          'gif',
          'bmp',
          'avif',
        ],
      );
      return file?.path;
    } catch (_) {
      SmartDialog.showToast('未找到可用的文件管理器');
      return null;
    }
  }

  Future<void> _applyCustomImage(String path) async {
    try {
      // Picker paths may live in a disposable cache. Keep our own copy in
      // application support, with a new name to avoid stale decoded images.
      final support = await getApplicationSupportDirectory();
      final directory = await Directory('${support.path}/backgrounds').create(
        recursive: true,
      );
      final saved = await File(path).copy(
        '${directory.path}/wallpaper_${DateTime.now().microsecondsSinceEpoch}',
      );
      await GStorage.setting.put(SettingBoxKey.backgroundImage, saved.path);
      await GStorage.setting.delete(SettingBoxKey.backgroundScene);
      await GStorage.setting.flush();
      Pref.backgroundImagePath.value = saved.path;
      if (!mounted) return;
      setState(() {
        _customImage = saved.path;
        _selected = BackgroundScene.none;
      });
      SmartDialog.showToast('设置成功');
      Get.appUpdate();
    } catch (_) {
      if (mounted) SmartDialog.showToast('背景图片保存失败，请重新选择');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final crossCount = size.width < 700
        ? 3
        : size.width < 1500
        ? 5
        : 8;
    final content = SimpleScaffold(
      appBar: tvBackBar(),
      body: _buildPresetMode(theme, crossCount),
    );
    return TvPageFocus(child: content);
  }

  Widget _buildPresetMode(ThemeData theme, int crossCount) {
    return ListView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.viewPaddingOf(context).bottom + 100,
      ),
      children: [
        Text(
          '预览',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 8),
        _PreviewCard(
          scene: _selected,
          customImage: _customImage,
          colorScheme: _colorScheme,
        ),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: crossCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.62,
          children: [
            _buildCustomTile(theme),
            ...BackgroundScene.values.map((e) {
              final selected = !_hasCustomImage && e == _selected;
              return _buildSceneTile(
                theme,
                scene: e,
                selected: selected,
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomTile(ThemeData theme) {
    final selected = _hasCustomImage;
    return TvFocusable(
      autofocus: selected,
      onTap: _onTapCustomTile,
      builder: (context, focused, hovered) {
        return TvFocusHighlight(
          focused: focused,
          color: theme.colorScheme.primary,
          radius: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.all(Radius.circular(18)),
                    border: Border.all(
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.4,
                            ),
                      width: selected ? 3 : 1,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (selected && _customImage.isNotEmpty)
                        Image.file(
                          File(_customImage),
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          errorBuilder: (_, _, _) => Container(),
                        ),
                      Center(
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 40,
                          color: selected
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.outline,
                        ),
                      ),
                      if (selected)
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.primary,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                selected ? '本地图片（使用中）' : '本地图片',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: selected ? theme.colorScheme.primary : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSceneTile(
    ThemeData theme, {
    required BackgroundScene scene,
    required bool selected,
  }) {
    final scheme = _colorScheme;
    return TvFocusable(
      autofocus: selected,
      onTap: () => _onSelected(scene),
      builder: (context, focused, hovered) {
        return TvFocusHighlight(
          focused: focused,
          color: theme.colorScheme.primary,
          radius: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: scene.gradient(scheme) == null
                        ? scheme.surfaceContainerHighest
                        : null,
                    gradient: scene.gradient(scheme),
                    borderRadius: const BorderRadius.all(Radius.circular(18)),
                    border: Border.all(
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.4,
                            ),
                      width: selected ? 3 : 1,
                    ),
                  ),
                  child: selected
                      ? Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.primary,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                scene.label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.scene,
    required this.colorScheme,
    this.customImage = '',
  });

  final BackgroundScene scene;
  final ColorScheme colorScheme;
  final String customImage;

  @override
  Widget build(BuildContext context) {
    final hasImage = customImage.isNotEmpty;
    final gradient = scene.gradient(colorScheme);
    return Container(
      height: 160,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: !hasImage && gradient == null
            ? colorScheme.surfaceContainerHighest
            : null,
        gradient: hasImage ? null : gradient,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
      ),
      child: hasImage
          ? Image.file(
              File(customImage),
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => Container(),
            )
          : null,
    );
  }
}
