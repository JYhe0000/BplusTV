import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/common/widgets/smartisan/smartisan_style.dart';
import 'package:bplus_tv/models/common/nav_bar_config.dart';
import 'package:bplus_tv/models/common/ui_style.dart';
import 'package:bplus_tv/pages/main/controller.dart';
import 'package:bplus_tv/pages/setting/models/ui_style_settings.dart';
import 'package:bplus_tv/tv/tv_back_bar.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_page_focus.dart';
import 'package:bplus_tv/utils/storage_pref.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

/// 界面风格页：选择默认或 Smartisan OS 全局主题。
class StyleSettingsPage extends StatefulWidget {
  const StyleSettingsPage({
    super.key,
    this.showAppBar = true,
    this.embedded = false,
  });

  final bool showAppBar;
  final bool embedded;

  @override
  State<StyleSettingsPage> createState() => _StyleSettingsPageState();
}

class _StyleSettingsPageState extends State<StyleSettingsPage> {
  UiStyle _selected = Pref.uiStyle;

  Future<void> _pick(UiStyle style) async {
    if (_selected == style) return;
    await applyUiStyle(style);
    if (mounted) setState(() => _selected = style);
    Get.until((route) => route.isFirst);
    final main = Get.find<MainController>();
    final home = main.navigationBars.indexOf(NavigationBarType.home);
    if (home != -1 && main.selectedIndex.value != home) {
      main.setIndex(home);
    }
    main
      ..barOffset?.value = 0.0
      ..showBottomBar?.value = true
      ..setSearchBar();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = MediaQuery.viewPaddingOf(context);
    final smartisan = SmartisanStyle.of(context);
    final side = smartisan ? 12.0 : 24.0;
    final body = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            side + padding.left,
            smartisan ? 18 : 20,
            side + padding.right,
            padding.bottom + 72,
          ),
          children: [
            Text(
              '界面风格',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '选择整机视觉语言，切换后所有页面即时生效。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = [
                  _StyleCard(
                    style: UiStyle.netflix,
                    selected: _selected == UiStyle.netflix,
                    title: '默认',
                    subtitle: '黑灰背景、清晰白字与红色强调，专为电视大屏呈现',
                    preview: const _NetflixPreview(),
                    onTap: () => _pick(UiStyle.netflix),
                  ),
                  _StyleCard(
                    style: UiStyle.smartisan,
                    selected: _selected == UiStyle.smartisan,
                    title: 'Smartisan OS',
                    subtitle: '轻拟物、灰色条纹底、白色分组卡片与锤子蓝强调色',
                    preview: const _SmartisanPreview(),
                    onTap: () => _pick(UiStyle.smartisan),
                  ),
                ];
                if (constraints.maxWidth >= 720) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: cards.first),
                      const SizedBox(width: 16),
                      Expanded(child: cards.last),
                    ],
                  );
                }
                return Column(
                  children: [
                    cards.first,
                    const SizedBox(height: 14),
                    cards.last,
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            _StyleNote(style: _selected),
          ],
        ),
      ),
    );
    if (widget.embedded) return body;
    final content = SimpleScaffold(
      appBar: widget.showAppBar ? tvBackBar() : null,
      body: body,
    );
    return widget.showAppBar ? TvPageFocus(child: content) : content;
  }
}

class _StyleNote extends StatelessWidget {
  const _StyleNote({required this.style});

  final UiStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = style.isSmartisan
        ? 'Smartisan OS 已开启：全局使用灰色条纹底、细描边卡片、居中标题栏和锤子蓝强调色。'
        : '默认已开启：全局使用黑灰背景、白色文字与红色强调，遥控器焦点清晰可见。';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              note,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StyleCard extends StatelessWidget {
  const _StyleCard({
    required this.style,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.preview,
    required this.onTap,
  });

  final UiStyle style;
  final bool selected;
  final String title;
  final String subtitle;
  final Widget preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return TvFocusable(
      autofocus: style.isNetflix,
      onTap: onTap,
      builder: (context, focused, hovered) {
        final highlight = focused || hovered;
        return TvFocusHighlight(
          focused: focused,
          radius: 14,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? accent
                    : theme.colorScheme.outlineVariant.withValues(
                        alpha: highlight ? 0.9 : 0.6,
                      ),
                width: selected ? 1.4 : 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: SizedBox(height: 112, child: preview),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _SelectDot(selected: selected, color: accent),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.45,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SelectDot extends StatelessWidget {
  const _SelectDot({required this.selected, required this.color});

  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? color : Colors.transparent,
        border: Border.all(
          color: selected ? color : outline,
          width: 1.4,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}

class _NetflixPreview extends StatelessWidget {
  const _NetflixPreview();

  static const _accent = Color(0xFFE50914);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF141414),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 66,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF202020),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '默认',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Spacer(),
                  Icon(Icons.home_filled, color: _accent, size: 18),
                  SizedBox(height: 8),
                  Icon(Icons.search, color: Colors.white70, size: 18),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '为你推荐',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _poster(selected: true)),
                        const SizedBox(width: 6),
                        Expanded(child: _poster()),
                        const SizedBox(width: 6),
                        Expanded(child: _poster()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _poster({bool selected = false}) => Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: selected ? const Color(0xFF333333) : const Color(0xFF262626),
      borderRadius: BorderRadius.circular(4),
      border: selected ? Border.all(color: _accent, width: 2) : null,
    ),
    child: Icon(
      Icons.play_arrow_rounded,
      color: selected ? Colors.white : Colors.white54,
      size: 24,
    ),
  );
}

class _SmartisanPreview extends StatelessWidget {
  const _SmartisanPreview();

  static const _bg = Color(0xFFF2F2F2);
  static const _card = Colors.white;
  static const _stroke = Color(0xFFE2E2E2);
  static const _line = Color(0xFFF2F2F2);
  static const _accent = Color(0xFF5B87EB);
  static const _text = Color(0xFF636363);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_bg, Color(0xFFEDEDED)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.arrow_back_ios_new, size: 11, color: _text),
                const Spacer(),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _text,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 11),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _stroke, width: 0.8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 16,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(child: _row('账号与安全', Icons.person_outline)),
                    Container(height: 0.8, color: _line),
                    Expanded(child: _row('消息通知', Icons.notifications_none)),
                    Container(height: 0.8, color: _line),
                    Expanded(child: _row('主题与字体', Icons.text_fields)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 84,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF5B87EB), Color(0xFF5883EB)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF3F68E2),
                    width: 0.8,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x335079D9),
                      blurRadius: 4,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Text(
                  '完成',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, IconData icon) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Row(
      children: [
        Icon(icon, size: 15, color: _accent),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF333333)),
          ),
        ),
        const Icon(Icons.chevron_right, size: 15, color: Color(0xFFB2B2B2)),
      ],
    ),
  );
}
