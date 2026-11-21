import 'package:bplus_tv/tv/tv_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('较矮的电视屏幕使用更紧凑的设置项', () {
    expect(TvConstants.settingRowMinHeight(540), 52);
    expect(TvConstants.settingRowMinHeight(720), 58);
  });

  test('设置分类栏宽度随可用屏幕宽度调整', () {
    expect(TvConstants.settingSidebarWidth(800), 224);
    expect(TvConstants.settingSidebarWidth(1200), 240);
    expect(TvConstants.settingSidebarWidth(1280), 256);
    expect(TvConstants.settingSidebarWidth(1920), 256);
  });
}
