import 'package:bplus_tv/tv/tv_dialog.dart';
import 'package:bplus_tv/utils/extension/num_ext.dart';
import 'package:material_ui/material_ui.dart';

class SliderDialog extends StatefulWidget {
  const SliderDialog({
    super.key,
    required this.value,
    required this.title,
    required this.min,
    required this.max,
    this.divisions,
    this.suffix = '',
    this.precise = 1,
  });

  final double value;
  final Widget title;
  final double min;
  final double max;
  final int? divisions;
  final String suffix;
  final int precise;

  @override
  State<SliderDialog> createState() => _SliderDialogState();
}

class _SliderDialogState extends State<SliderDialog> {
  late double _tempValue;

  @override
  void initState() {
    super.initState();
    _tempValue = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    final slider = Slider(
      value: _tempValue,
      min: widget.min,
      max: widget.max,
      divisions: widget.divisions,
      label: '${_tempValue.toStringAsFixed(widget.precise)}${widget.suffix}',
      onChanged: (double value) {
        setState(() {
          _tempValue = value.toPrecision(widget.precise);
        });
      },
    );
    final sliderContent = SizedBox(
      height: 40,
      // On TV, force directional navigation so up/down move focus out of
      // the slider instead of being captured to adjust the value. Only
      // left/right should change the value.
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          navigationMode: NavigationMode.directional,
        ),
        child: slider,
      ),
    );
    {
      return tvDialogShell(
        title: _stringify(widget.title),
        minWidth: 420,
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: sliderContent,
        ),
        actions: [
          TvDialogAction(
            label: '取消',
            onTap: Navigator.of(context).pop,
          ),
          TvDialogAction(
            label: '确定',
            onTap: () => Navigator.pop(context, _tempValue),
            primary: true,
          ),
        ],
      );
    }
  }

  static String _stringify(Widget w) {
    final text = w is Text ? w.data : null;
    return text ?? '设置';
  }
}
