/*
 * This file is part of PiliPlus
 *
 * PiliPlus is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * PiliPlus is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with PiliPlus.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:bplus_tv/common/assets.dart';
import 'package:bplus_tv/common/style.dart';
import 'package:bplus_tv/common/widgets/badge.dart';
import 'package:bplus_tv/common/widgets/dialog/simple_dialog_option.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/common/widgets/image_grid/image_grid_builder.dart';
import 'package:bplus_tv/common/widgets/image_viewer/gallery_viewer.dart';
import 'package:bplus_tv/common/widgets/scaffold/mini_scaffold.dart';
import 'package:bplus_tv/models/common/image_preview_type.dart';
import 'package:bplus_tv/tv/tv_dialog.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/utils/extension/num_ext.dart';
import 'package:bplus_tv/utils/global_data.dart';
import 'package:bplus_tv/utils/image_utils.dart';
import 'package:bplus_tv/utils/page_utils.dart';
import 'package:bplus_tv/utils/storage_pref.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:material_ui/material_ui.dart';

class ImageModel {
  ImageModel({
    required num? width,
    required num? height,
    required this.url,
    this.liveUrl,
  }) {
    this.width = width == null || width == 0 ? 1 : width;
    this.height = height == null || height == 0 ? 1 : height;
  }

  late num width;
  late num height;
  String url;
  String? liveUrl;
  bool? _isLongPic;
  bool? _isLivePhoto;

  bool get isLongPic =>
      _isLongPic ??= (height / width) > Style.imgMaxRatio && width > 100;
  bool get isLivePhoto =>
      _isLivePhoto ??= enableLivePhoto && liveUrl?.isNotEmpty == true;

  static bool enableLivePhoto = Pref.enableLivePhoto;
}

class ImageGridView extends StatelessWidget {
  const ImageGridView({
    super.key,
    required this.picArr,
    this.onViewImage,
    this.fullScreen = false,
  });

  final List<ImageModel> picArr;
  final VoidCallback? onViewImage;
  final bool fullScreen;

  static bool horizontalPreview = Pref.horizontalPreview;
  static final _regex = RegExp(r'/videoV|/dynamicDetail$|/articlePage');

  void _onTap(BuildContext context, int index) {
    final imgList = picArr.map(
      (item) {
        bool isLive = item.isLivePhoto;
        return SourceModel(
          sourceType: isLive ? .livePhoto : .networkImage,
          url: item.url,
          liveUrl: isLive ? item.liveUrl : null,
          width: isLive ? item.width.toInt() : null,
          height: isLive ? item.height.toInt() : null,
          isLongPic: item.isLongPic,
        );
      },
    ).toList();
    if (horizontalPreview &&
        !fullScreen &&
        Get.currentRoute.startsWith(_regex)) {
      final scaffoldState = MiniScaffold.maybeOf(context);
      if (scaffoldState != null) {
        onViewImage?.call();
        scaffoldState.showBottomSheet(
          constraints: const BoxConstraints(),
          (context) => GalleryViewer(
            sources: imgList,
            initIndex: index,
            quality: GlobalData().imgQuality,
          ),
          enableDrag: false,
        );
        return;
      }
    }
    PageUtils.imageView(
      initialPage: index,
      imgList: imgList,
      tag: hashCode.toString(),
    );
  }

  static BorderRadius _borderRadius(
    int col,
    int length,
    int index, {
    Radius r = Style.imgRadius,
  }) {
    if (length == 1) return Style.mdRadius;

    final bool hasUp = index - col >= 0;
    final bool hasDown = index + col < length;

    final bool isRowStart = index % col == 0;
    final bool isRowEnd = index % col == col - 1 || index == length - 1;

    return BorderRadius.only(
      topLeft: !hasUp && isRowStart ? r : Radius.zero,
      topRight: !hasUp && isRowEnd ? r : Radius.zero,
      bottomLeft: !hasDown && isRowStart ? r : Radius.zero,
      bottomRight: !hasDown && isRowEnd ? r : Radius.zero,
    );
  }

  static bool enableImgMenu = Pref.enableImgMenu;

  void _showMenu(BuildContext context, int index) {
    final item = picArr[index];
    Widget option(String label, VoidCallback onPressed) => DialogOption(
      onPressed: () {
        Get.back();
        onPressed();
      },
      child: Text(label),
    );
    showDialog(
      context: context,
      builder: (context) => tvDialog(
        SimpleDialog(
          title: const Text('图片操作'),
          children: [
            option('分享', () => ImageUtils.onShareImg(item.url)),
            option('保存图片', () => ImageUtils.downloadImg([item.url])),
            if (picArr.length > 1)
              option(
                '保存全部',
                () => ImageUtils.downloadImg(
                  picArr.map((item) => item.url).toList(),
                ),
              ),
            if (item.isLivePhoto)
              option(
                '保存视频',
                () => ImageUtils.downloadLivePhoto(
                  url: item.url,
                  liveUrl: item.liveUrl!,
                  width: item.width.toInt(),
                  height: item.height.toInt(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .only(top: 6),
      child: ImageGridBuilder(
        picArr: picArr,
        builder: (BuildContext context, ImageGridInfo info) {
          final width = info.size.width;
          final height = info.size.height;
          late final placeHolder = Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: ColorScheme.of(
                context,
              ).onInverseSurface.withValues(alpha: 0.4),
            ),
            child: Image.asset(
              Assets.loading,
              width: width,
              height: height,
              cacheWidth: width.cacheSize(context),
            ),
          );
          return List.generate(picArr.length, (index) {
            void onTap() => _onTap(context, index);
            final item = picArr[index];
            final borderRadius = _borderRadius(
              info.column,
              picArr.length,
              index,
            );
            Widget child = Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                NetworkImgLayer(
                  src: item.url,
                  width: width,
                  height: height,
                  borderRadius: borderRadius,
                  alignment: item.isLongPic ? .topCenter : .center,
                  cacheWidth: item.width <= item.height,
                  getPlaceHolder: () => placeHolder,
                ),
                if (item.isLivePhoto)
                  const PBadge(text: 'Live', right: 8, bottom: 8, type: .gray)
                else if (item.isLongPic)
                  const PBadge(text: '长图', right: 8, bottom: 8),
              ],
            );
            if (!item.isLongPic) {
              final baseTag = '${item.url}$hashCode';
              child = Hero(
                tag: picArr.where((e) => e.url == item.url).length > 1
                    ? '$baseTag-$index'
                    : baseTag,
                child: child,
              );
            }
            child = Semantics(
              label: '图片，第 ${index + 1} 张，共 ${picArr.length} 张',
              button: true,
              onTap: onTap,
              child: child,
            );
            final image = child;
            return LayoutId(
              id: index,
              child: TvFocusable(
                onTap: onTap,
                onLongPress: enableImgMenu
                    ? () => _showMenu(context, index)
                    : null,
                builder: (context, focused, _) => TvFocusHighlight(
                  focused: focused,
                  radius: Style.imgRadius.x,
                  child: image,
                ),
              ),
            );
          });
        },
      ),
    );
  }
}
