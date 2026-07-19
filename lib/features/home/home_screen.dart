import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/secure_storage_service.dart';
import '../sensitive/sensitive_data_screen.dart';
import 'presentation/home_view_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ref.read(homeViewModelProvider);
    _viewModel.initialize(_handleSessionExpired);
  }

  void _handleSessionExpired() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Sesión expirada'),
        content: const Text('La sesión ha expirado por inactividad por motivos de seguridad.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _viewModel.logoutAndClear(context);
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showFcmTokenDialog() async {
    String? token = await SecureStorageService.readFcmToken();

    if (token == null || token.isEmpty) {
      try {
        token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) {
          await SecureStorageService.saveFcmToken(token);
        }
      } catch (error) {
        debugPrint('FCM token read failed: $error');
      }
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Token FCM'),
          content: SelectableText(
            token ?? 'No se pudo obtener el token FCM. Asegúrate de aceptar los permisos de notificaciones.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: SecureStorageService.readUserId(),
      builder: (context, snapshot) {
        final userId = snapshot.data ?? 'student-user-001';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Inicio seguro'),
            actions: [
              IconButton(
                tooltip: 'Cerrar sesión',
                onPressed: () => _viewModel.logoutAndClear(context),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                _viewModel.resetTimer();
                return false;
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sesión activa',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text('Usuario: $userId'),
                  const SizedBox(height: 8),
                  const Text('Los datos sensibles están protegidos en almacenamiento seguro.'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      _viewModel.resetTimer();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SensitiveDataScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.lock),
                    label: const Text('Ir al formulario de datos sensibles'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _showFcmTokenDialog,
                    icon: const Icon(Icons.vpn_key),
                    label: const Text('Ver token FCM'),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.fingerprint),
                            title: const Text('Estado de seguridad'),
                            subtitle: const Text('La eliminación remota por FCM está preparada para tu usuario.'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
