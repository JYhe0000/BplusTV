import 'package:bplus_tv/common/widgets/route_aware_mixin.dart';
import 'package:bplus_tv/tv/tv_dialog.dart' show TvDialogScopes;
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/routes/default_route.dart'
    show GetPageRoute;

/// Gives a pushed TV page a valid D-pad target.
///
/// The app's routes do not automatically focus their own focus scope, so a
/// pushed page (settings, search, ...) can open with focus still on the page
/// behind it — the remote then drives that page instead. This requests focus
/// for its subtree once mounted; if a descendant already took focus
/// (autofocus), it stays put.
///
/// It also recovers the page's focus after a global rebuild (theme / style
/// switch) drops the focused item, and whenever a page on top of it is popped.
class TvPageFocus extends StatefulWidget {
  const TvPageFocus({super.key, required this.child});

  final Widget child;

  @override
  State<TvPageFocus> createState() => _TvPageFocusState();
}

class _TvPageFocusState extends State<TvPageFocus> with RouteAware {
  final FocusScopeNode _scopeNode = FocusScopeNode(
    debugLabel: 'TvPageFocus',
  );
  GetPageRoute? _route;
  bool _focusRestoreScheduled = false;
  FocusNode? _lastFocused;

  bool _hasActiveDescendant(FocusNode? node) =>
      TvFocusUtils.isFocusable(node, within: _scopeNode);

  bool _isDialogFocused(FocusNode? node) => TvDialogScopes.contains(node);

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_onPrimaryFocusChanged);
  }

  void _onPrimaryFocusChanged() {
    final primary = FocusManager.instance.primaryFocus;
    if (_hasActiveDescendant(primary)) _lastFocused = primary;
    _scheduleRestore();
  }

  void _scheduleRestore() {
    if (_focusRestoreScheduled) return;
    _focusRestoreScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusRestoreScheduled = false;
      if (!mounted) return;
      if (ModalRoute.of(context)?.isCurrent == false) return;
      FocusManager.instance.applyFocusChangesIfNeeded();
      final primary = FocusManager.instance.primaryFocus;
      if (TvDialogScopes.hasOpenDialog || _isDialogFocused(primary)) return;
      if (_hasActiveDescendant(primary)) return;
      _requestFirstFocusable();
    });
  }

  void _requestFirstFocusable() {
    final target = _hasActiveDescendant(_lastFocused)
        ? _lastFocused
        : TvFocusUtils.firstFocusable(_scopeNode);
    target?.requestFocus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is GetPageRoute && route != _route) {
      if (_route != null) routeObserver.unsubscribe(this);
      _route = route;
      routeObserver.subscribe(this, route);
    }
    _scheduleRestore();
  }

  @override
  void didUpdateWidget(covariant TvPageFocus oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleRestore();
  }

  @override
  void didPush() {
    _scheduleRestore();
  }

  @override
  void didPushNext() {
    // 路由负责交接焦点；手动 unfocus 会清空本页的焦点历史。
    final primary = FocusManager.instance.primaryFocus;
    if (_hasActiveDescendant(primary)) _lastFocused = primary;
  }

  @override
  void didPopNext() {
    _scheduleRestore();
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onPrimaryFocusChanged);
    if (_route != null) routeObserver.unsubscribe(this);
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
