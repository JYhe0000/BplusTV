import 'package:PiliPlus/tv/tv_focus.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scopeNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
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
