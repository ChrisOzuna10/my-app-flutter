import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionTimeoutService {
  static const int timeoutSeconds = 15; // 15 segundos para pruebas; cambiar a 300 (5 min) para producción
  
  Timer? _inactivityTimer;
  VoidCallback? _onSessionExpired;

  void startTimer(VoidCallback onSessionExpired) {
    _onSessionExpired = onSessionExpired;
    _resetTimer();
  }

  void _resetTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(seconds: timeoutSeconds), () {
      debugPrint('SessionTimeoutService: Sesión expirada por inactividad');
      _onSessionExpired?.call();
    });
  }

  void resetOnInteraction() {
    debugPrint('SessionTimeoutService: Actividad detectada, reiniciando temporizador');
    _resetTimer();
  }

  void dispose() {
    _inactivityTimer?.cancel();
    _onSessionExpired = null;
  }
}

// Provider del servicio de timeout
final sessionTimeoutProvider = Provider<SessionTimeoutService>((ref) {
  final service = SessionTimeoutService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});
