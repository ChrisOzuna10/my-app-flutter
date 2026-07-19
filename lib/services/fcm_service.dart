import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'secure_storage_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FCMService.handleMessage(message);
}

class FCMService {
  static const String _remoteWipeAction = 'REMOTE_WIPE';
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initializeLocalNotifications() async {
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await _localNotifications.initialize(initializationSettings);
  }

  static bool shouldUseFCMForPlatform(bool isWeb) {
    return !isWeb;
  }

  static Future<void> initialize() async {
    if (kIsWeb) {
      print('FCM deshabilitado en web; la app seguirá cargando en Chrome.');
      return;
    }

    try {
      print('FCM: iniciando inicialización');
      await initializeLocalNotifications();
      final FirebaseMessaging messaging = FirebaseMessaging.instance;

      final NotificationSettings settings = await messaging.requestPermission();
      print('FCM: permisos de notificaciones = ${settings.authorizationStatus}');

      final String? token = await messaging.getToken();
      if (token != null) {
        await SecureStorageService.saveFcmToken(token);
        print('FCM: token generado = $token');
      } else {
        print('FCM: no se pudo obtener el token');
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        print('FCM: mensaje recibido en primer plano: ${message.data}');
        await handleMessage(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
        print('FCM: mensaje abierto desde la app: ${message.data}');
        await handleMessage(message);
      });

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      print('FCM: listeners registrados');
    } catch (error) {
      print('FCM: error de inicialización = $error');
    }
  }

  static Future<void> handleMessage(RemoteMessage message) async {
    final currentUserId = await SecureStorageService.readUserId();
    print('FCM: evaluando mensaje para usuario actual = $currentUserId');
    print('FCM: datos del mensaje = ${message.data}');

    if (!shouldWipeSensitiveData(message, currentUserId)) {
      print('FCM: mensaje ignorado porque no coincide con el usuario objetivo');
      return;
    }

    await _showLocalNotification(message);
    await SecureStorageService.deleteSensitiveData();
    print('FCM: datos sensibles eliminados para el usuario = $currentUserId');
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final title = buildNotificationTitle(message);
    final body = buildNotificationBody(message);

    const androidDetails = AndroidNotificationDetails(
      'remote_wipe_channel',
      'Borrado remoto',
      channelDescription: 'Notificaciones de borrado remoto por FCM',
      importance: Importance.max,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
    );
  }

  static String buildNotificationTitle(RemoteMessage message) {
    return message.data['action'] == _remoteWipeAction
        ? 'Borrado remoto activado'
        : 'Notificación recibida';
  }

  static String buildNotificationBody(RemoteMessage message) {
    final targetUserId = message.data['targetUserId'] ?? message.data['targetEmail'] ?? message.data['userId'] ?? 'usuario';
    return 'Se recibió una orden de borrado remoto para $targetUserId.';
  }

  static bool shouldWipeSensitiveData(
    RemoteMessage message,
    String? currentUserId,
  ) {
    final action = message.data['action']?.toString().trim().toUpperCase();
    final normalizedCurrentUserId = _normalizeUserId(currentUserId);

    if (action != _remoteWipeAction || normalizedCurrentUserId == null) {
      return false;
    }

    final candidateTargetIds = <String?>[
      message.data['targetUserId']?.toString(),
      message.data['targetEmail']?.toString(),
      message.data['userId']?.toString(),
    ];

    return candidateTargetIds.any((targetId) => _normalizeUserId(targetId) == normalizedCurrentUserId);
  }

  static String? _normalizeUserId(String? value) {
    if (value == null) {
      return null;
    }

    final normalized = value.trim().toLowerCase();
    return normalized.isEmpty ? null : normalized;
  }
}
