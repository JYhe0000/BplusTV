import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/common/widgets/loading_widget/loading_widget.dart';
import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/common/widgets/view_insets_safe_area.dart';
import 'package:bplus_tv/http/fav.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_option_picker.dart';
import 'package:bplus_tv/tv/tv_page_focus.dart';
import 'package:bplus_tv/tv/tv_text_input.dart';
import 'package:bplus_tv/utils/bili_utils.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class CreateFavPage extends StatefulWidget {
  const CreateFavPage({super.key});

  @override
  State<CreateFavPage> createState() => _CreateFavPageState();
}

class _CreateFavPageState extends State<CreateFavPage> {
  dynamic _mediaId;
  late final TextEditingController _titleController;
  late final TextEditingController _introController;
  String? _cover;
  bool _isPublic = true;
  String? _errMsg;
  int? _attr;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _introController = TextEditingController();
    _mediaId = Get.parameters['mediaId'];
    if (_mediaId != null) {
      _getFolderInfo();
    }
  }

  void _getFolderInfo() {
    _errMsg = null;
    FavHttp.favFolderInfo(mediaId: _mediaId).then((res) {
      if (!mounted) return;
      if (res case Success(:final response)) {
        _titleController.text = response.title;
        _introController.text = response.intro ?? '';
        _isPublic = BiliUtils.isPublicFav(response.attr);
        _cover = response.cover;
        _attr = response.attr;
      } else {
        _errMsg = res.toString();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final page = SimpleScaffold(
      appBar: AppBar(
        title: Text(_mediaId != null ? '编辑' : '创建'),
        actions: [
          TextButton(
            onPressed: () {
              if (_titleController.text.isEmpty) {
                SmartDialog.showToast('名称不能为空');
                return;
              }
              FavHttp.addOrEditFolder(
                isAdd: _mediaId == null,
                mediaId: _mediaId,
                title: _titleController.text,
                privacy: _isPublic ? 0 : 1,
                cover: _cover ?? '',
                intro: _introController.text,
              ).then((res) {
                if (res case Success(:final response)) {
                  SmartDialog.showToast('${_mediaId != null ? '编辑' : '创建'}成功');
                  if (mounted) {
                    Get.back(result: response);
                  }
                } else {
                  res.toast();
                }
              });
            },
            child: const Text('完成'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _mediaId != null
          ? _titleController.text.isNotEmpty
                ? _buildBody(theme)
                : _errMsg?.isNotEmpty == true
                ? scrollErrorWidget(errMsg: _errMsg, onReload: _getFolderInfo)
                : m3eLoading
          : _buildBody(theme),
    );
    return TvPageFocus(child: page);
  }

  Future<void> _editTitleTv() async {
    final text = await showTvTextInput(
      context,
      title: '名称',
      initialValue: _titleController.text,
      maxLength: 20,
    );
    if (text == null || !mounted) return;
    setState(() => _titleController.text = text);
  }

  Future<void> _editIntroTv() async {
    final text = await showTvTextInput(
      context,
      title: '简介',
      initialValue: _introController.text,
      maxLength: 200,
    );
    if (text == null || !mounted) return;
    setState(() => _introController.text = text);
  }

  Widget _buildTvField({
    required String value,
    required String hint,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    return TvFocusable(
      onTap: enabled ? onTap : null,
      canRequestFocus: enabled,
      builder: (context, focused, hovered) => TvFocusHighlight(
        focused: focused,
        radius: 8,
        borderWidth: 2,
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          alignment: Alignment.centerLeft,
          child: Text(
            value.isEmpty ? hint : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              color: value.isEmpty || !enabled
                  ? theme.colorScheme.outline
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onTvCover() async {
    final hasCover = _cover?.isNotEmpty == true;
    final action = await showTvOptionPicker<String>(
      context: context,
      title: '封面',
      options: [
        const TvOption(value: 'url', label: '输入封面链接'),
        if (hasCover) const TvOption(value: 'remove', label: '移除封面'),
      ],
    );
    if (action == null || !mounted) return;
    if (action == 'remove') {
      setState(() => _cover = null);
      return;
    }
    final url = await showTvTextInput(
      context,
      title: '封面链接',
      initialValue: _cover ?? '',
    );
    if (url == null || url.isEmpty || !mounted) return;
    setState(() => _cover = url);
  }

  final leadingStyle = const TextStyle(fontSize: 14);

  Widget _buildBody(ThemeData theme) => ViewInsetsSafeArea(
    child: SingleChildScrollView(
      padding: .only(bottom: MediaQuery.viewPaddingOf(context).bottom + 25),
      child: Column(
        spacing: 12,
        children: [
          if (_attr == null || !BiliUtils.isDefaultFav(_attr!))
            Builder(
              builder: (context) {
                return ListTile(
                  visualDensity: .standard,
                  tileColor: theme.colorScheme.onInverseSurface,
                  onTap: () {
                    EasyThrottle.throttle(
                      'imagePicker',
                      const Duration(milliseconds: 500),
                      () {
                        {
                          _onTvCover();
                          return;
                        }
                      },
                    );
                  },
                  leading: Text(
                    '封面',
                    style: leadingStyle,
                  ),
                  trailing: Row(
                    spacing: 10,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_cover?.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: NetworkImgLayer(
                            src: _cover,
                            height: 55,
                            width: 88,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(6),
                            ),
                          ),
                        ),
                      Icon(
                        Icons.keyboard_arrow_right,
                        color: theme.colorScheme.outline,
                      ),
                    ],
                  ),
                );
              },
            ),
          ListTile(
            tileColor: theme.colorScheme.onInverseSurface,
            title: Row(
              children: [
                SizedBox(
                  width: 55,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '*',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.error,
                          ),
                        ),
                        const TextSpan(
                          text: '名称',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _buildTvField(
                    value: _titleController.text,
                    hint: '名称',
                    enabled: !(_attr != null && BiliUtils.isDefaultFav(_attr!)),
                    onTap: _editTitleTv,
                  ),
                ),
              ],
            ),
          ),
          if (_attr == null || !BiliUtils.isDefaultFav(_attr!))
            ListTile(
              tileColor: theme.colorScheme.onInverseSurface,
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 55,
                    child: Text(
                      '简介',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildTvField(
                      value: _introController.text,
                      hint: '可填写简介',
                      onTap: _editIntroTv,
                    ),
                  ),
                ],
              ),
            ),
          Builder(
            builder: (context) {
              void onTap() {
                _isPublic = !_isPublic;
                (context as Element).markNeedsBuild();
              }

              return ListTile(
                onTap: onTap,
                tileColor: theme.colorScheme.onInverseSurface,
                leading: Text(
                  '公开',
                  style: leadingStyle,
                ),
                trailing: Transform.scale(
                  alignment: Alignment.centerRight,
                  scale: 0.8,
                  child: Switch(
                    value: _isPublic,
                    onChanged: (value) => onTap(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}
