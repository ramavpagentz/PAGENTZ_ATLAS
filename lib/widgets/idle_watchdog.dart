import 'package:flutter/material.dart';

import '../core/services/session_timeout_service.dart';

/// Wraps its child in a Listener that touches the SessionTimeoutService on
/// any pointer event (mouse move/click, touch). Keyboard input is also tied
/// in via a global RawKeyboardListener at the root Focus.
class IdleWatchdog extends StatelessWidget {
  final Widget child;
  const IdleWatchdog({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _touch,
      onPointerMove: _touch,
      onPointerSignal: _touch,
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          SessionTimeoutService.instance.touch();
          return KeyEventResult.ignored;
        },
        child: child,
      ),
    );
  }

  void _touch(PointerEvent _) {
    SessionTimeoutService.instance.touch();
  }
}
