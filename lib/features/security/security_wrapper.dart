import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/scheduler.dart';

// Permite forzar la comprobación de ADB en modo debug mediante --dart-define
const bool forceAdbCheck = bool.fromEnvironment('FORCE_ADB_CHECK', defaultValue: false);
const MethodChannel securityChannel = MethodChannel('security_channel');

bool shouldBlockForDeviceDebug({
  required bool isDeviceInDevMode,
  bool forceAdbCheckEnabled = false,
}) {
  return forceAdbCheckEnabled || isDeviceInDevMode;
}

class SecurityWrapper extends StatefulWidget {
  final Widget child;
  const SecurityWrapper({super.key, required this.child});

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
    // Verificación temprana de seguridad: comprobar si ADB está activo
    // Si la depuración USB está activa, la app debe bloquearse con un aviso y cierre.
    _checkAdbAndBlockIfNeeded();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setSecureScreen(false);
    // limpiar handler nativo y timers
    try {
      securityChannel.setMethodCallHandler(null);
    } catch (_) {}
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _isObscured = state == AppLifecycleState.paused;
    });
  }

  Future<void> _setSecureScreen(bool secure) async {
    // Usa el canal de plataforma para Android/iOS
    const platform = securityChannel;
    try {
      await platform.invokeMethod('secureScreen', {'secure': secure});
    } catch (_) {}
  }

  Future<void> _checkAdbAndBlockIfNeeded() async {
    // Ejecutar siempre la comprobación incluso en modo debug (usuario solicitó bloqueo en modo desarrollador)
    // Si antes se quería forzar desde --dart-define, la constante sigue disponible.
    const platform = MethodChannel('security_channel');

    // Registrar handler para notificaciones desde Android nativo
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onDevModeChanged') {
        final dynamic arg = call.arguments;
        final bool devMode = arg is Map && arg['devMode'] == true;
        debugPrint('SecurityWrapper: onDevModeChanged -> $devMode');
        if (devMode) {
          if (!_dialogShown) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              _showBlockingDialog();
            });
          }
        } else {
          // Cerrar diálogo si está mostrado
          if (_dialogShown && mounted) {
            try {
              Navigator.of(context, rootNavigator: true).pop();
            } catch (_) {}
            _dialogShown = false;
          }
        }
      }
    });

    try {
      final dynamic result = await platform.invokeMethod('isDeviceInDevMode');
      final bool blocked = result == true;
      final bool shouldBlock = shouldBlockForDeviceDebug(
        isDeviceInDevMode: blocked,
        forceAdbCheckEnabled: forceAdbCheck,
      );
      debugPrint('SecurityWrapper: initial isDeviceInDevMode -> $blocked, shouldBlock -> $shouldBlock');
      if (shouldBlock) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _showBlockingDialog();
        });
      }
    } catch (_) {
      debugPrint('SecurityWrapper: fallo comprobando isDeviceInDevMode');
    }
  }

  bool _dialogShown = false;
  Timer? _pollTimer;

  void _showBlockingDialog() {
    if (!mounted) return;
    debugPrint('SecurityWrapper: _showBlockingDialog llamado');
    _dialogShown = true;

    // iniciar sondeo periódico como respaldo
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      try {
        final res = await securityChannel.invokeMethod('isDeviceInDevMode');
        final bool dev = res == true;
        if (!dev && mounted && _dialogShown) {
          try {
            Navigator.of(context, rootNavigator: true).pop();
          } catch (_) {}
          _dialogShown = false;
          t.cancel();
        }
      } catch (_) {}
    });

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seguridad del dispositivo'),
          content: const Text(
              'La depuración USB o las Opciones de desarrollador están activas. La aplicación permanecerá bloqueada mientras estas opciones estén habilitadas.'),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                try {
                  SystemNavigator.pop();
                } catch (_) {
                  exit(0);
                }
              },
              child: const Text('Cerrar aplicación'),
            ),
          ],
        );
      },
    ).then((_) {
      _dialogShown = false;
      _pollTimer?.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isObscured) {
      return Container(color: Colors.black);
    }
    return widget.child;
  }
}
