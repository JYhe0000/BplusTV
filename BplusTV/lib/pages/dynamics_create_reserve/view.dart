import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/common/widgets/time_picker.dart';
import 'package:bplus_tv/pages/dynamics/dyn_layout.dart';
import 'package:bplus_tv/pages/dynamics_create_reserve/controller.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_option_picker.dart';
import 'package:bplus_tv/utils/date_utils.dart';
import 'package:bplus_tv/utils/utils.dart';
import 'package:flutter/services.dart'
    show TextInputFormatter, LengthLimitingTextInputFormatter;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart' hide showTimePicker;

class CreateReservePage extends StatefulWidget {
  const CreateReservePage({super.key, this.sid});

  final int? sid;

  @override
  State<CreateReservePage> createState() => _CreateReservePageState();
}

class _CreateReservePageState extends State<CreateReservePage> {
  late final CreateReserveController _controller;
  late TextStyle _leadingStyle;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(
      CreateReserveController(widget.sid),
      tag: Utils.generateRandomString(6),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _leadingStyle = TextStyle(
      fontSize: 18,
      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
    );
    final padding = MediaQuery.viewPaddingOf(context);
    final divider = [
      const SizedBox(height: 16),
      Divider(
        height: 1,
        color: theme.colorScheme.outline.withValues(alpha: 0.1),
      ),
      const SizedBox(height: 16),
    ];
    return SimpleScaffold(
      appBar: AppBar(title: const Text('添加直播预约')),
      body: DynPageContent(
        child: ListView(
          padding: EdgeInsets.only(
            top: 16,
            left: padding.left + 16,
            right: padding.right + 16,
            bottom: padding.bottom + 100,
          ),
          children: [
            Row(
              spacing: 12,
              children: [
                SizedBox(
                  width: 96,
                  child: Text('类型', style: _leadingStyle),
                ),
                Obx(
                  () {
                    final subTypeText = _controller.subType.value == 0
                        ? '公开直播'
                        : '大航海直播';
                    {
                      return TvFocusable(
                        onTap: _showTvTypePicker,
                        builder: (context, focused, hovered) =>
                            TvFocusHighlight(
                              focused: focused,
                              radius: 12,
                              borderWidth: 2,
                              child: Container(
                                constraints: const BoxConstraints(
                                  minHeight: 48,
                                ),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Text(subTypeText),
                              ),
                            ),
                      );
                    }
                  },
                ),
              ],
            ),
            ...divider,
            Row(
              spacing: 12,
              children: [
                SizedBox(
                  width: 96,
                  child: Text('时间', style: _leadingStyle),
                ),
                Expanded(
                  child: DynFocusAction(
                    onTap: () async {
                      FocusManager.instance.primaryFocus?.unfocus();
                      DateTime? newDate = await showDatePicker(
                        context: context,
                        initialDate: _controller.date.value,
                        firstDate: _controller.now,
                        lastDate: _controller.end,
                      );
                      if (newDate != null && context.mounted) {
                        TimeOfDay? newTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                            _controller.date.value,
                          ),
                        );
                        if (newTime != null) {
                          final newEndtime = DateTime(
                            newDate.year,
                            newDate.month,
                            newDate.day,
                            newTime.hour,
                            newTime.minute,
                          );
                          if (newEndtime.difference(DateTime.now()) >=
                              const Duration(minutes: 5)) {
                            _controller.date.value = newEndtime;
                          } else {
                            SmartDialog.showToast('至少选择5分钟之后');
                          }
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Obx(
                        () => Text(
                          DateFormatUtils.longFormatD.format(
                            _controller.date.value,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ...divider,
            Obx(
              () => _buildInput(
                theme,
                key: ValueKey(_controller.key),
                initialValue: _controller.title.value,
                onChanged: (value) => _controller
                  ..title.value = value
                  ..updateCanCreate(),
                desc: '标题',
                hintText: '请填写标题，最多14字',
                inputFormatters: [LengthLimitingTextInputFormatter(14)],
              ),
            ),
            ...divider,
            const SizedBox(height: 25),
            Obx(() {
              return FilledButton.tonal(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: _controller.canCreate.value
                    ? _controller.onCreate
                    : null,
                child: const Text('添加预约'),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _showTvTypePicker() async {
    final current = _controller.subType.value;
    final subType = await showTvOptionPicker<int>(
      context: context,
      title: '类型',
      current: current,
      options: const [
        TvOption(value: 0, label: '公开直播'),
        TvOption(value: 1, label: '大航海直播'),
      ],
    );
    if (subType == null || subType == current) return;
    _controller.subType.value = subType;
  }

  Widget _buildInput(
    ThemeData theme, {
    Key? key,
    String? initialValue,
    required ValueChanged<String> onChanged,
    required String desc,
    String? hintText,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Row(
      spacing: 12,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            desc,
            style: _leadingStyle,
          ),
        ),
        Expanded(
          child: TextFormField(
            key: key,
            initialValue: initialValue,
            style: const TextStyle(fontSize: 18, height: 1.4),
            onChanged: onChanged,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              hintText: hintText ?? desc,
              hintStyle: TextStyle(
                fontSize: 18,
                color: theme.colorScheme.outline.withValues(alpha: 0.7),
              ),
            ),
            inputFormatters: inputFormatters,
          ),
        ),
      ],
    );
  }
}
