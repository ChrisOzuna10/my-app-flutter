import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/session_timeout_service.dart';

class GlobalActivityListener extends ConsumerStatefulWidget {
  final Widget child;

  const GlobalActivityListener({Key? key, required this.child}) : super(key: key);

  @override
  ConsumerState<GlobalActivityListener> createState() => _GlobalActivityListenerState();
}

class _GlobalActivityListenerState extends ConsumerState<GlobalActivityListener> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _onUserActivity(),
      onPointerMove: (_) => _onUserActivity(),
      onPointerUp: (_) => _onUserActivity(),
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: (node, event) {
          _onUserActivity();
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _onUserActivity,
          onHorizontalDragStart: (_) => _onUserActivity(),
          onVerticalDragStart: (_) => _onUserActivity(),
          child: widget.child,
        ),
      ),
    );
  }

  void _onUserActivity() {
    debugPrint('[GlobalActivityListener] Actividad detectada');
    try {
      final sessionTimeout = ref.read(sessionTimeoutProvider);
      sessionTimeout.resetOnInteraction();
    } catch (e) {
      debugPrint('[GlobalActivityListener] Error al leer sessionTimeout: $e');
    }
  }
}
