import 'package:bplus_tv/models/common/enum_with_label.dart';

/// 全局视觉风格，保留枚举顺序以兼容已保存的设置。
enum UiStyle implements EnumWithLabel {
  netflix('默认'),
  smartisan('Smartisan OS'),
  ;

  const UiStyle(this.label);

  @override
  final String label;

  bool get isNetflix => this == UiStyle.netflix;

  bool get isSmartisan => this == UiStyle.smartisan;
}
