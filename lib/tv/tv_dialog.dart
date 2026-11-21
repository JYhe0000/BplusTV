import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:flutter/material.dart';

/// 已挂载对话框的 FocusScopeNode 集合。
///
/// 供页面判断「当前焦点是否在对话框里」（[TvPageFocus] 用）。
/// 用节点身份而不是 `debugLabel` 字符串匹配，重构改名不会静默失效。
abstract final class TvDialogScopes {
  static final Set<FocusScopeNode> _scopes = {};

  static void add(FocusScopeNode node) => _scopes.add(node);
  static void remove(FocusScopeNode node) => _scopes.remove(node);

  static bool get hasOpenDialog => _scopes.isNotEmpty;

  /// 嵌套弹窗只有最上层可以恢复焦点，避免两个 scope 互相抢焦点。
  static bool isTopMost(FocusScopeNode node) =>
      _scopes.isNotEmpty && identical(_scopes.last, node);

  static bool contains(FocusNode? node) {
    if (node == null) return false;
    // 焦点可能正好停在对话框的 scope 本身（还没有子项被聚焦）。
    if (_scopes.contains(node)) return true;
    for (final ancestor in node.ancestors) {
      if (_scopes.contains(ancestor)) return true;
    }
    return false;
  }
}

/// Wraps dialog content so a TV remote can move focus inside it.
///
/// `SmartDialog` and other overlay-based dialogs do not create a focus scope,
/// which leaves focus on the page behind the dialog. This creates a scope and
/// explicitly takes focus so the D-pad traverses the dialog's own controls.
class TvDialogScope extends StatefulWidget {
  const TvDialogScope({super.key, required this.child});

  final Widget child;

  @override
  State<TvDialogScope> createState() => _TvDialogScopeState();
}

class _TvDialogScopeState extends State<TvDialogScope> {
  final FocusScopeNode _scopeNode = FocusScopeNode(
    debugLabel: 'TvDialogScope',
  );
  bool _restoreScheduled = false;
  FocusNode? _lastFocused;

  bool _hasActiveDescendant(FocusNode? node) =>
      TvFocusUtils.isFocusable(node, within: _scopeNode);

  @override
  void initState() {
    super.initState();
    TvDialogScopes.add(_scopeNode);
    FocusManager.instance.addListener(_restoreFocusIfLost);
    _scheduleRestore();
  }

  void _restoreFocusIfLost() {
    final primary = FocusManager.instance.primaryFocus;
    if (_hasActiveDescendant(primary)) _lastFocused = primary;
    _scheduleRestore();
  }

  void _scheduleRestore() {
    if (_restoreScheduled) return;
    _restoreScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreScheduled = false;
      if (!mounted || !TvDialogScopes.isTopMost(_scopeNode)) return;
      // 标准路由弹窗可能没有 TvDialogScope，也不能抢它的焦点。
      if (ModalRoute.of(context)?.isCurrent == false) return;
      // 先兑现子项的 autofocus，再决定是否需要默认兜底。
      FocusManager.instance.applyFocusChangesIfNeeded();
      final primary = FocusManager.instance.primaryFocus;
      // The dialog's own scope (or a dialog nested in it) already owns focus
      // and has an active descendant: nothing to restore.
      if (_hasActiveDescendant(primary)) return;
      final first = _hasActiveDescendant(_lastFocused)
          ? _lastFocused
          : TvFocusUtils.firstFocusable(_scopeNode);
      if (first != null) {
        first.requestFocus();
      } else if (!identical(primary, _scopeNode) &&
          _scopeNode.canRequestFocus) {
        // No focusable content (e.g. a message-only dialog): park focus on the
        // scope itself so the D-pad stops driving the page behind the dialog.
        _scopeNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_restoreFocusIfLost);
    TvDialogScopes.remove(_scopeNode);
    _scopeNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: TvFocusTraversalPolicy(),
      child: FocusScope(
        node: _scopeNode,
        child: widget.child,
      ),
    );
  }
}

/// Convenience wrapper for [TvDialogScope].
Widget tvDialog(Widget child) => TvDialogScope(child: child);

class TvDialogAction {
  const TvDialogAction({
    required this.label,
    required this.onTap,
    this.primary = false,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool autofocus;
}

/// TV dialog shell: a solid full-screen overlay with a centered surface
/// panel, D-pad removable focus, and an optional action row.
///
/// Drop-in replacement for mobile `AlertDialog` on TV. [content] is laid out
/// with its own vertical size; use a scrollable/limited-height content for
/// long option lists.
Widget tvDialogShell({
  required String title,
  required Widget content,
  List<TvDialogAction> actions = const [],
  double? minWidth,
  double? maxWidth,
  double? maxHeight,
}) {
  final explicitFocus = actions.indexWhere((action) => action.autofocus);
  final initialFocus = explicitFocus < 0 ? 0 : explicitFocus;
  return Dialog(
    backgroundColor: Colors.transparent,
    elevation: 0,
    child: tvDialog(
      netflixSurface(
        radius: 24,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: minWidth ?? 360,
            maxWidth: maxWidth ?? 520,
            maxHeight: maxHeight ?? 560,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 14),
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Divider(
                height: 1,
                color: Colors.white.withValues(alpha: 0.12),
              ),
              Flexible(child: content),
              if (actions.isNotEmpty) ...[
                Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  // Wrap instead of overflowing: a long label (or a large text
                  // scale) must not push the buttons past the panel width.
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < actions.length; i++)
                        _TvDialogActionButton(
                          action: actions[i],
                          autofocus: i == initialFocus,
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class _TvDialogActionButton extends StatelessWidget {
  const _TvDialogActionButton({
    required this.action,
    required this.autofocus,
  });

  final TvDialogAction action;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TvFocusable(
      autofocus: autofocus,
      onTap: action.onTap,
      builder: (context, focused, hovered) => TvFocusHighlight(
        focused: focused,
        radius: 12,
        child: Container(
          constraints: const BoxConstraints(minWidth: 88),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: action.primary
                ? colorScheme.primary.withValues(alpha: 0.92)
                : Colors.transparent,
          ),
          child: Text(
            action.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: action.primary
                  ? Colors.white
                  : Colors.white70.withValues(
                      alpha: focused ? 1 : 0.7,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// TV confirm dialog with [message] and action row.
Future<bool?> showTvConfirm({
  required BuildContext context,
  required String title,
  required String message,
  String cancelLabel = '取消',
  String confirmLabel = '确定',
  bool destructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => tvDialogShell(
      title: title,
      minWidth: 420,
      content: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            height: 1.4,
          ),
        ),
      ),
      actions: [
        TvDialogAction(
          label: cancelLabel,
          onTap: () => Navigator.of(dialogContext).pop(false),
        ),
        TvDialogAction(
          label: confirmLabel,
          onTap: () => Navigator.of(dialogContext).pop(true),
          primary: true,
        ),
      ],
    ),
  );
}
