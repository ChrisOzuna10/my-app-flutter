import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_app/features/login/presentation/login_screen.dart';
import 'package:my_app/features/security/security_wrapper.dart';
import 'package:my_app/firebase_options.dart';
import 'package:my_app/services/fcm_service.dart';
import 'package:my_app/services/secure_storage_service.dart';
import 'package:my_app/services/session_timeout_service.dart';
import 'package:my_app/widgets/global_activity_listener.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Guardar datos sensibles de prueba
  try {
    await SecureStorageService.saveSensitiveData(
      userId: 'student-user-001',
    );
  } catch (error) {
    debugPrint(
      'SecureStorage init skipped due to error: $error',
    );
  }

  // Inicializar Firebase Cloud Messaging
  try {
    await FCMService.initialize();
  } catch (error) {
    debugPrint(
      'FCM init skipped due to platform/runtime error: $error',
    );
  }

  runApp(
    const MyApp(),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: GlobalActivityListener(
        child: SessionTimeoutWrapper(
          child: MaterialApp(
            title: 'Demo Seguridad',
            debugShowCheckedModeBanner: false,

            navigatorKey: navigatorKey,

            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
              ),
              useMaterial3: true,
            ),

            home: SecurityWrapper(
              child: LoginScreen(),
            ),
          ),
        ),
      ),
    );
  }
}


/// Control de expiración de sesión por inactividad
class SessionTimeoutWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const SessionTimeoutWrapper({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<SessionTimeoutWrapper> createState() =>
      _SessionTimeoutWrapperState();
}


class _SessionTimeoutWrapperState
    extends ConsumerState<SessionTimeoutWrapper> {

  bool _timerStarted = false;


  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {

      if (!_timerStarted && mounted) {

        debugPrint(
          'SessionTimeoutWrapper: Iniciando temporizador de sesión',
        );

        _timerStarted = true;

        final sessionTimeout =
            ref.read(sessionTimeoutProvider);

        sessionTimeout.startTimer(
          _handleSessionExpired,
        );
      }
    });
  }


  void _handleSessionExpired() {

    if (!mounted) return;

    debugPrint(
      'main: Sesión expirada, redirigiendo al login',
    );


    showDialog(
      context: context,
      barrierDismissible: false,

      builder: (ctx) {

        return AlertDialog(

          title: const Text(
            'Sesión expirada',
          ),

          content: const Text(
            'Su sesión ha expirado por inactividad. '
            'Por favor, inicie sesión nuevamente.',
          ),


          actions: [

            TextButton(

              onPressed: () {

                Navigator.of(ctx).pop();

                _performLogout();

              },

              child: const Text(
                'Aceptar',
              ),
            ),
          ],
        );
      },
    );
  }



  void _performLogout() {

    navigatorKey.currentState?.pushAndRemoveUntil(

      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),

      (route) => false,

    );
  }


  @override
  Widget build(BuildContext context) {

    return widget.child;

  }
}