import 'package:bplus_tv/common/widgets/dialog/dialog.dart';
import 'package:bplus_tv/common/widgets/smartisan/smartisan_style.dart';
import 'package:bplus_tv/smartisan/smartisan_adapters.dart';
import 'package:bplus_tv/pages/setting/widgets/tv_setting_tile.dart';
import 'package:bplus_tv/utils/storage.dart';
import 'package:bplus_tv/utils/storage_key.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:material_ui/material_ui.dart' hide ListTile;

class SetSwitchItem extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String setKey;
  final bool defaultVal;
  final ValueChanged<bool>? onChanged;
  final bool needReboot;
  final Widget? leading;
  final void Function(BuildContext context)? onTap;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? titleStyle;
  final bool isSplit;

  const SetSwitchItem({
    super.key,
    required this.title,
    this.subtitle,
    required this.setKey,
    this.defaultVal = false,
    this.onChanged,
    this.needReboot = false,
    this.leading,
    this.onTap,
    this.contentPadding,
    this.titleStyle,
    this.isSplit = false,
  });

  @override
  State<SetSwitchItem> createState() => _SetSwitchItemState();
}

class _SetSwitchItemState extends State<SetSwitchItem> {
  late bool val;

  void _setVal() {
    val = GStorage.setting.get(widget.setKey, defaultValue: widget.defaultVal);
  }

  @override
  void didUpdateWidget(SetSwitchItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.setKey != widget.setKey) {
      _setVal();
    }
  }

  @override
  void initState() {
    super.initState();
    _setVal();
  }

  Future<void> switchChange([bool? value]) async {
    val = value ?? !val;

    if (val && widget.setKey == SettingBoxKey.badCertificateCallback) {
      val = await showConfirmDialog(
        context: context,
        title: const Text('确定禁用 SSL 证书验证？'),
        content: const Text('禁用容易受到中间人攻击'),
      );
      if (!val) return;
    }

    await GStorage.setting.put(widget.setKey, val);

    widget.onChanged?.call(val);
    if (widget.needReboot) SmartDialog.showToast('重启生效');
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final smartisan = SmartisanStyle.of(context);
    final toggle = TvSettingTile(
      title: Text(widget.title),
      subtitle: widget.subtitle == null ? null : Text(widget.subtitle!),
      leading: widget.leading,
      onTap: switchChange,
      trailing: IgnorePointer(
        child: smartisan
            ? SmartisanSwitch(value: val, onChanged: (_) {})
            : Switch(value: val, onChanged: (_) {}),
      ),
    );
    if (widget.onTap == null) return toggle;
    // Configuration and enabled state are separate remote targets: even when
    // disabled, the first row can always turn the feature back on.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        toggle,
        const SizedBox(height: 8),
        TvSettingTile(
          title: Text('配置${widget.title}'),
          enabled: val,
          onTap: () => widget.onTap!(context),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}
