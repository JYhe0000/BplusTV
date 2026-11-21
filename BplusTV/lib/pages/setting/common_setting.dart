import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/common/widgets/smartisan/smartisan_style.dart';
import 'package:bplus_tv/models/common/setting_type.dart';
import 'package:bplus_tv/pages/setting/models/model.dart';
import 'package:bplus_tv/tv/tv_back_bar.dart';
import 'package:bplus_tv/tv/tv_constants.dart';
import 'package:bplus_tv/tv/tv_page_focus.dart';
import 'package:material_ui/material_ui.dart';

class CommonSetting extends StatefulWidget {
  const CommonSetting({
    super.key,
    required this.settingType,
    this.showAppBar = true,
    this.embedded = false,
  });

  final bool showAppBar;
  final bool embedded;
  final SettingType settingType;

  @override
  State<CommonSetting> createState() => _CommonSettingState();
}

class _CommonSettingState extends State<CommonSetting> {
  late EdgeInsets padding;
  late List<SettingsModel> settings;

  void _initSetting() {
    settings = widget.settingType.settings;
  }

  @override
  void initState() {
    super.initState();
    _initSetting();
  }

  @override
  void didUpdateWidget(CommonSetting oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.settingType != oldWidget.settingType) {
      _initSetting();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    padding = MediaQuery.viewPaddingOf(context);
  }

  @override
  Widget build(BuildContext context) {
    final showAppBar = widget.showAppBar;
    final smartisan = SmartisanStyle.of(context);
    final side = smartisan ? 10.0 : 16.0;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final body = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: ListView.builder(
          key: ValueKey(widget.settingType),
          padding: EdgeInsets.only(
            left: side + padding.left,
            right: side + padding.right,
            top: smartisan ? 12 : 14,
            bottom: padding.bottom + 48,
          ),
          itemCount: settings.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  widget.settingType.title,
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontSize: 22, fontWeight: FontWeight.w600),
                ),
              );
            }
            final item = settings[index - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: smartisan
                      ? 52
                      : TvConstants.settingRowMinHeight(viewportHeight),
                ),
                child: item.widget,
              ),
            );
          },
        ),
      ),
    );
    if (widget.embedded) return body;
    final content = SimpleScaffold(
      appBar: showAppBar ? tvBackBar() : null,
      body: body,
    );
    return showAppBar ? TvPageFocus(child: content) : content;
  }
}
