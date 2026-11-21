import 'dart:io';

import 'package:bplus_tv/common/widgets/netflix_style.dart';
import 'package:bplus_tv/common/widgets/smartisan/smartisan_background.dart';
import 'package:bplus_tv/common/widgets/smartisan/smartisan_style.dart';
import 'package:bplus_tv/utils/storage_pref.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

/// 默认使用黑色背景，用户壁纸叠加暗色渐变以保证内容对比度。
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    if (SmartisanStyle.of(context)) {
      return const SmartisanBackground();
    }
    return Obx(() {
      final imagePath = Pref.backgroundImagePath.value;
      if (imagePath.isEmpty) {
        return const ColoredBox(color: NetflixStyle.page);
      }
      return ColoredBox(
        color: NetflixStyle.page,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) =>
                  const ColoredBox(color: NetflixStyle.page),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x99000000), Color(0xE6000000)],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
