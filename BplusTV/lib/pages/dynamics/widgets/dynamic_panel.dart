import 'package:bplus_tv/common/widgets/avatars.dart';
import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/common/widgets/image/image_save.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models/dynamics/result.dart';
import 'package:bplus_tv/pages/dynamics/widgets/action_panel.dart';
import 'package:bplus_tv/pages/dynamics/widgets/author_panel.dart';
import 'package:bplus_tv/pages/dynamics/widgets/dyn_content.dart';
import 'package:bplus_tv/pages/dynamics/dyn_layout.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/pages/dynamics/widgets/interaction.dart';
import 'package:bplus_tv/utils/extension/theme_ext.dart';
import 'package:bplus_tv/utils/page_utils.dart';
import 'package:material_ui/material_ui.dart';

class DynamicPanel extends StatelessWidget {
  final DynamicItemModel item;
  final bool isDetail;
  final ValueChanged<Object>? onRemove;
  final bool isSave;
  final void Function(bool isTop, Object dynId)? onSetTop;
  final VoidCallback? onBlock;
  final VoidCallback? onUnfold;
  final bool isDetailPortraitW;
  final Future<LoadingState> Function(bool isPrivate, Object dynId)?
  onSetPubSetting;
  final VoidCallback? onEdit;
  final ValueChanged<int>? onSetReplySubject;

  const DynamicPanel({
    super.key,
    required this.item,
    this.isDetail = false,
    this.onRemove,
    this.isSave = false,
    this.onSetTop,
    this.onBlock,
    this.onUnfold,
    this.isDetailPortraitW = true,
    this.onSetPubSetting,
    this.onEdit,
    this.onSetReplySubject,
  });

  @override
  Widget build(BuildContext context) {
    if (item.visible == false) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final authorWidget = AuthorPanel(
      item: item,
      isDetail: isDetail,
      onRemove: onRemove,
      isSave: isSave,
      onSetTop: onSetTop,
      onBlock: onBlock,
      onSetPubSetting: onSetPubSetting,
      onEdit: onEdit,
      onSetReplySubject: onSetReplySubject,
    );

    void showMore() => _imageSaveDialog(context, authorWidget.morePanel);

    Widget child = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap:
            isDetail &&
                !const {
                  'DYNAMIC_TYPE_AV',
                  'DYNAMIC_TYPE_UGC_SEASON',
                  'DYNAMIC_TYPE_PGC_UNION',
                  'DYNAMIC_TYPE_PGC',
                  'DYNAMIC_TYPE_LIVE',
                  'DYNAMIC_TYPE_LIVE_RCMD',
                  'DYNAMIC_TYPE_MEDIALIST',
                  'DYNAMIC_TYPE_COURSES_SEASON',
                }.contains(item.type)
            ? null
            : () => PageUtils.pushDynDetail(item),
        onLongPress: showMore,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: authorWidget,
            ),
            if (item.modules.moduleDispute case final moduleDispute?)
              _buildDispute(theme, moduleDispute),
            ...dynContent(
              context,
              theme: theme,
              isSave: isSave,
              isDetail: isDetail,
              item: item,
              floor: 1,
            ),
            const SizedBox(height: 1),
            if (!isDetail) ...[
              if (item.modules.moduleInteraction case ModuleInteraction(
                :final items,
              ))
                if (items != null && items.isNotEmpty)
                  dynInteraction(
                    theme: theme,
                    items: items,
                  ),
              ActionPanel(item: item),
              if (item.modules.moduleFold case final moduleFold?) ...[
                Divider(
                  height: 1,
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
                _buildFoldItem(theme, moduleFold),
              ],
            ] else if (!isSave)
              const SizedBox(height: 10),
          ],
        ),
      ),
    );
    if (!isDetail && !isSave) {
      final content = NetflixSurface(
        radius: 18,
        child: child,
      );
      child = TvFocusable(
        onTap: () => PageUtils.pushDynDetail(item),
        onLongPress: showMore,
        builder: (context, focused, hovered) => TvFocusHighlight(
          focused: focused,
          radius: 18,
          // Mobile author/action controls otherwise become invisible D-pad
          // stops inside the card. They remain available on the detail page.
          child: ExcludeFocus(child: content),
        ),
      );
    }
    if (isSave || (isDetail && !isDetailPortraitW)) {
      return child;
    }
    if (isDetail) {
      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: 8,
              color: theme.dividerColor.withValues(alpha: 0.05),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: child,
        ),
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: DynLayout.maxReadingWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }

  void _imageSaveDialog(
    BuildContext context,
    Function(BuildContext) morePanel,
  ) {
    String? title;
    String? cover;
    String? bvid;
    late final major = item.modules.moduleDynamic?.major;
    switch (item.type) {
      case 'DYNAMIC_TYPE_AV':
        if (major?.archive case final archive?) {
          title = archive.title;
          cover = archive.cover;
          bvid = archive.bvid;
        }
        break;
      case 'DYNAMIC_TYPE_UGC_SEASON':
        if (major?.ugcSeason case final ugcSeason?) {
          title = ugcSeason.title;
          cover = ugcSeason.cover;
          bvid = ugcSeason.bvid;
        }
        break;
      case 'DYNAMIC_TYPE_PGC' || 'DYNAMIC_TYPE_PGC_UNION':
        if (major?.pgc case final pgc?) {
          title = pgc.title;
          cover = pgc.cover;
        }
        break;
      case 'DYNAMIC_TYPE_LIVE_RCMD':
        if (major?.liveRcmd case final liveRcmd?) {
          title = liveRcmd.title;
          cover = liveRcmd.cover;
        }
        break;
      case 'DYNAMIC_TYPE_LIVE':
        if (major?.live case final live?) {
          title = live.title;
          cover = live.cover;
        }
        break;
      case 'DYNAMIC_TYPE_COURSES_SEASON':
        if (major?.courses case final courses?) {
          title = courses.title;
          cover = courses.cover;
        }
        break;
      case 'DYNAMIC_TYPE_SUBSCRIPTION_NEW':
        if (major?.subscriptionNew?.liveRcmd?.content?.livePlayInfo
            case final livePlayInfo?) {
          title = livePlayInfo.title;
          cover = livePlayInfo.cover;
        }
        break;
      default:
        morePanel(context);
        return;
    }
    imageSaveDialog(
      title: title,
      cover: cover,
      bvid: bvid,
    );
  }

  Widget _buildFoldItem(ThemeData theme, ModuleFold moduleFold) {
    Widget child = Text.rich(
      textAlign: TextAlign.center,
      style: TextStyle(
        height: 1,
        fontSize: 16,
        color: theme.colorScheme.outline,
      ),
      strutStyle: const StrutStyle(
        height: 1,
        leading: 0,
        fontSize: 16,
      ),
      TextSpan(
        children: [
          TextSpan(text: moduleFold.statement ?? '展开'),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(
              size: 19,
              Icons.keyboard_arrow_down,
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
    final users = moduleFold.users;
    if (users != null && users.isNotEmpty) {
      child = Row(
        spacing: 5,
        mainAxisAlignment: .center,
        children: [
          avatars(colorScheme: theme.colorScheme, users: users),
          Flexible(child: child),
        ],
      );
    }
    return InkWell(
      onTap: onUnfold,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: child,
      ),
    );
  }

  Widget _buildDispute(ThemeData theme, ModuleDispute moduleDispute) {
    final child = Container(
      width: .infinity,
      margin: const .fromLTRB(12, 2, 12, 6),
      padding: const .symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(
          alpha: theme.isLight ? 0.5 : 0.7,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      child: Text.rich(
        style: TextStyle(
          height: 1,
          fontSize: 13,
          color: theme.colorScheme.onSecondaryContainer,
        ),
        strutStyle: const StrutStyle(
          leading: 0,
          height: 1,
          fontSize: 13,
        ),
        TextSpan(
          children: [
            WidgetSpan(
              alignment: .middle,
              child: Padding(
                padding: const .only(right: 4),
                child: Icon(
                  size: 15,
                  Icons.warning_rounded,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            TextSpan(text: moduleDispute.title),
          ],
        ),
      ),
    );
    if (moduleDispute.jumpUrl?.isNotEmpty == true) {
      return TvFocusable(
        onTap: () => PageUtils.handleWebview(moduleDispute.jumpUrl!),
        builder: (context, focused, hovered) => TvFocusHighlight(
          radius: 8,
          focused: focused,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: child,
          ),
        ),
      );
    }
    return child;
  }
}
