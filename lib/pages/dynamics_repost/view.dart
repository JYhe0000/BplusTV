import 'package:bplus_tv/common/widgets/animated_height.dart';
import 'package:bplus_tv/common/widgets/draggable_sheet/dyn.dart';
import 'package:bplus_tv/common/widgets/flutter/text_field/text_field.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/common/widgets/scroll_physics.dart'
    show platformClampingPhysics;
import 'package:bplus_tv/http/dynamics.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models/dynamics/result.dart';
import 'package:bplus_tv/pages/common/publish/common_rich_text_pub_page.dart';
import 'package:bplus_tv/pages/dynamics/dyn_layout.dart';
import 'package:bplus_tv/pages/dynamics_mention/controller.dart';
import 'package:bplus_tv/pages/emote/controller.dart';
import 'package:bplus_tv/pages/emote/view.dart';
import 'package:bplus_tv/tv/tv_back_bar.dart';
import 'package:bplus_tv/utils/accounts.dart';
import 'package:bplus_tv/utils/request_utils.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart' hide TextField;

class RepostPanel extends CommonRichTextPubPage {
  const RepostPanel({
    super.key,
    this.item,
    this.dynIdStr,
    this.onSuccess,
    // video
    this.rid,
    this.dynType,
    this.pic,
    this.title,
    this.uname,
    super.autofocus = false,
  });

  // video
  final int? rid;
  final int? dynType;
  final String? pic;
  final String? title;
  final String? uname;

  final DynamicItemModel? item;
  final String? dynIdStr;
  final VoidCallback? onSuccess;

  @override
  State<RepostPanel> createState() => _RepostPanelState();
}

class _RepostPanelState extends CommonRichTextPubPageState<RepostPanel>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  late final String? _pic;
  late final String _text;
  late final String? _uname;

  static const _durtion = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    late final modules = widget.item?.modules;
    late final moduleDynamic = modules?.moduleDynamic;
    late final major = moduleDynamic?.major;

    _pic =
        widget.pic ??
        major?.archive?.cover ??
        major?.pgc?.cover ??
        major?.opus?.pics?.firstOrNull?.url;

    _text =
        widget.title ??
        major?.opus?.summary?.text ??
        major?.archive?.title ??
        major?.pgc?.title ??
        moduleDynamic?.desc?.text ??
        '';

    _uname = widget.uname ?? modules?.moduleAuthor?.name;
  }

  @override
  void dispose() {
    // 只删除本页面创建的 tag 实例，避免误关其他页面仍在使用的无 tag 实例
    Get
      ..delete<EmotePanelController>(tag: 'emotePanel')
      ..delete<DynMentionController>(tag: 'dynMention');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget page([ScrollController? scrollController]) => Column(
      crossAxisAlignment: .start,
      mainAxisSize: _expanded ? .max : .min,
      children: [
        if (!_expanded) const SizedBox(height: 10),
        _buildAppBar(),
        if (_expanded) ...[
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              controller: scrollController,
              physics: platformClampingPhysics,
              children: _buildEditPanel(),
            ),
          ),
          _buildToolbar,
          buildPanelContainer(Colors.transparent),
        ] else ...[
          ..._buildEditPanel(),
          ..._buildDismiss(),
        ],
      ],
    );

    return DynPageContent(
      child: AnimatedHeight(
        vsync: this,
        expand: _expanded,
        curve: Curves.ease,
        duration: _durtion,
        child: _expanded
            ? DynDraggableScrollableSheet(
                snap: true,
                expand: false,
                minChildSize: 0,
                maxChildSize: 1,
                initialChildSize: 1,
                snapSizes: const [1],
                builder: (context, scrollController) => page(scrollController),
              )
            : page(),
      ),
    );
  }

  List<Widget> _buildEditPanel() => [
    Padding(
      padding: const .symmetric(horizontal: 16),
      child: _expanded
          ? _buildEditWidget()
          : DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    width: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              child: _buildEditPlaceHolder(),
            ),
    ),
    const SizedBox(height: 16),
    _buildRefWidget(),
  ];

  Widget _buildRefWidget() => Card(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_pic != null) ...[
            NetworkImgLayer(
              width: 64,
              height: 64,
              src: _pic,
              borderRadius: const BorderRadius.all(
                Radius.circular(6),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_uname?.isNotEmpty == true)
                  Text(
                    '@$_uname',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 16,
                    ),
                  ),
                Text(
                  _text,
                  style: const TextStyle(fontSize: 18, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildEditPlaceHolder() => DynFocusAction(
    onTap: () {
      setState(() => _expanded = true);
      Future.delayed(_durtion, () {
        if (mounted) {
          focusNode.requestFocus();
        }
      });
    },
    child: SizedBox(
      width: double.infinity,
      child: Text(
        '说点什么吧',
        style: TextStyle(
          height: 1.5,
          fontSize: 20,
          color: theme.colorScheme.outline,
        ),
      ),
    ),
  );

  Widget _buildEditWidget() => Obx(
    () => RichTextField(
      key: key,
      controller: editController,
      style: const TextStyle(fontSize: 20, height: 1.5),
      minLines: 4,
      maxLines: null,
      autofocus: false,
      focusNode: focusNode,
      onSubmitted: onSubmitted,
      readOnly: readOnly.value,
      decoration: InputDecoration(
        hintText: '说点什么吧',
        hintStyle: TextStyle(color: theme.colorScheme.outline),
        border: const OutlineInputBorder(
          borderSide: BorderSide.none,
          gapPadding: 0,
        ),
        contentPadding: EdgeInsets.zero,
      ),
      // inputFormatters: [LengthLimitingTextInputFormatter(1000)],
    ),
  );

  Widget _buildAppBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      spacing: 16,
      children: [
        if (_expanded) const TvBackButton(),
        Expanded(
          child: Text(
            widget.rid != null ? '分享至动态' : '转发动态',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
        ),
        FilledButton.tonal(
          onPressed: onPublishThrottle,
          style: FilledButton.styleFrom(
            minimumSize: const Size(96, 48),
            textStyle: const TextStyle(fontSize: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(widget.rid != null ? '发布' : '转发'),
        ),
      ],
    ),
  );

  Widget get _buildToolbar => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      spacing: 16,
      children: [
        DynToolbarTarget(child: emojiBtn),
        DynToolbarTarget(child: atBtn),
      ],
    ),
  );

  List<Widget> _buildDismiss() => [
    const SizedBox(height: 10),
    Divider(
      height: 1,
      color: theme.colorScheme.outline.withValues(alpha: 0.1),
    ),
    ListTile(
      dense: true,
      onTap: Get.back,
      title: Center(
        child: Text(
          '取消',
          style: TextStyle(color: theme.colorScheme.outline),
        ),
      ),
    ),
    SizedBox(height: 10 + MediaQuery.viewPaddingOf(context).bottom),
  ];

  @override
  Widget? get customPanel => EmotePanel(onChoose: onChooseEmote);

  List<Map<String, dynamic>>? getRepostContent(DynamicItemModel item) {
    try {
      return [
        {"raw_text": "//", "type": 1, "biz_id": ""},
        {
          "raw_text": "@${item.modules.moduleAuthor!.name}",
          "type": 2,
          "biz_id": item.modules.moduleAuthor!.mid.toString(),
        },
        {"raw_text": ":", "type": 1, "biz_id": ""},
        ...item.modules.moduleDynamic!.desc!.richTextNodes!.map(
          (e) {
            int type;
            String bizId;
            switch (e.type) {
              case 'RICH_TEXT_NODE_TYPE_EMOJI':
                type = 9;
                bizId = '';
              case 'RICH_TEXT_NODE_TYPE_AT':
                type = 2;
                bizId = e.rid ?? '';
              case 'RICH_TEXT_NODE_TYPE_TEXT':
              default:
                type = 1;
                bizId = '';
            }
            return {
              "raw_text": e.origText,
              "type": type,
              "biz_id": bizId,
            };
          },
        ),
      ];
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> onCustomPublish({List? pictures}) async {
    SmartDialog.showLoading();
    List<Map<String, dynamic>>? richContent = getRichContent();
    final hasRichText = richContent != null;
    List<Map<String, dynamic>>? repostContent = widget.item?.orig != null
        ? getRepostContent(widget.item!)
        : null;
    if (hasRichText && repostContent != null) {
      richContent.addAll(repostContent);
    }
    final res = await DynamicsHttp.createDynamic(
      mid: Accounts.main.mid,
      dynIdStr: widget.item?.idStr ?? widget.dynIdStr,
      rid: widget.rid,
      dynType: widget.dynType,
      rawText: hasRichText ? null : editController.text,
      extraContent: richContent ?? repostContent,
    );
    SmartDialog.dismiss();
    if (res case Success(:final response)) {
      hasPub = true;
      Get.back();
      SmartDialog.showToast('转发成功');
      widget.onSuccess?.call();
      final id = response?['dyn_id'];
      RequestUtils.insertCreatedDyn(id);
      RequestUtils.checkCreatedDyn(
        id: id,
        dynText: editController.rawText,
      );
    } else {
      res.toast();
    }
  }

  @override
  void onSave() {}
}
