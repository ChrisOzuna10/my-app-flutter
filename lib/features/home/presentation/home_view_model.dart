import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/secure_storage_service.dart';
import '../../../services/session_timeout_service.dart';
import '../../login/presentation/login_screen.dart';

final homeViewModelProvider = Provider<HomeViewModel>((ref) {
  return HomeViewModel(
    sessionTimeoutService: ref.read(sessionTimeoutProvider),
  );
});

class HomeViewModel {
  HomeViewModel({required this.sessionTimeoutService});

  final SessionTimeoutService sessionTimeoutService;

  void initialize(VoidCallback onSessionExpired) {
    sessionTimeoutService.startTimer(onSessionExpired);
  }

  void resetTimer() {
    sessionTimeoutService.resetOnInteraction();
  }

  Future<void> logoutAndClear(BuildContext context) async {
    await SecureStorageService.deleteSensitiveData();
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
