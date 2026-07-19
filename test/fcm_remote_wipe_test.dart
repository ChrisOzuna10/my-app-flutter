import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/services/fcm_service.dart';

void main() {
  group('FCM remote wipe', () {
    test('only wipes when the notification is targeted to the current user', () {
      final message = RemoteMessage(
        data: {
          'action': 'REMOTE_WIPE',
          'targetUserId': 'user-123',
        },
        notification: null,
        sentTime: DateTime.now(),
        messageId: 'message-1',
      );

      expect(
        FCMService.shouldWipeSensitiveData(message, 'user-123'),
        isTrue,
      );

      expect(
        FCMService.shouldWipeSensitiveData(message, 'other-user'),
        isFalse,
      );
    });

    test('ignores non-remote-wipe notifications', () {
      final message = RemoteMessage(
        data: {'action': 'OTHER'},
        notification: null,
        sentTime: DateTime.now(),
        messageId: 'message-2',
      );

      expect(
        FCMService.shouldWipeSensitiveData(message, 'user-123'),
        isFalse,
      );
    });

    test('matches the target user even when the stored id has extra whitespace', () {
      final message = RemoteMessage(
        data: {
          'action': 'REMOTE_WIPE',
          'targetUserId': 'User-123',
        },
        notification: null,
        sentTime: DateTime.now(),
        messageId: 'message-3',
      );

      expect(
        FCMService.shouldWipeSensitiveData(message, '  user-123  '),
        isTrue,
      );
    });

    test('builds a visible local notification for a remote wipe message', () {
      final message = RemoteMessage(
        data: {
          'action': 'REMOTE_WIPE',
          'targetUserId': 'user-123',
        },
        notification: null,
        sentTime: DateTime.now(),
        messageId: 'message-4',
      );

      expect(
        FCMService.buildNotificationTitle(message),
        'Borrado remoto activado',
      );
      expect(
        FCMService.buildNotificationBody(message),
        contains('user-123'),
      );
    });
  });
}
