import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SecurityWrapper extends StatefulWidget {
  final Widget child;
  const SecurityWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<SecurityWrapper> createState() => _SecurityWrapperState();
}

class _SecurityWrapperState extends State<SecurityWrapper>
    with WidgetsBindingObserver {
  bool _isObscured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Bloquea capturas de pantalla y grabación de video
    _setSecureScreen(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setSecureScreen(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _isObscured =
          state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive;
    });
  }

  Future<void> _setSecureScreen(bool secure) async {
    // Usa el canal de plataforma para Android/iOS
    const platform = MethodChannel('security_channel');
    try {
      await platform.invokeMethod('secureScreen', {'secure': secure});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isObscured) {
      return Container(color: Colors.black);
    }
    return widget.child;
  }
}
