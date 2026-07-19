import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const List<String> sensitiveKeys = <String>[
    'email',
    'password',
    'jwt_token',
    'api_key',
    'user_id',
    'device_token',
  ];

  static Map<String, String> buildDemoSensitiveData({String userId = 'student-user-001'}) {
    return {
      'email': 'alumno@upchiapas.edu.mx',
      'password': '123456789',
      'jwt_token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9',
      'api_key': 'AIzaSyXXXXXXXXXXXXXXXX',
      'user_id': userId,
      'device_token': 'android-demo-device',
    };
  }

  static bool credentialsMatch(
    String enteredEmail,
    String enteredPassword,
    String? storedEmail,
    String? storedPassword,
  ) {
    final normalizedEnteredEmail = enteredEmail.trim().toLowerCase();
    final normalizedStoredEmail = (storedEmail ?? '').trim().toLowerCase();

    return normalizedEnteredEmail == normalizedStoredEmail &&
        enteredPassword == (storedPassword ?? '');
  }

  static Future<bool> validateCredentials(
    String enteredEmail,
    String enteredPassword,
  ) async {
    final storedEmail = await _storage.read(key: 'email');
    final storedPassword = await _storage.read(key: 'password');

    return credentialsMatch(
      enteredEmail,
      enteredPassword,
      storedEmail,
      storedPassword,
    );
  }

  static Future<String?> readUserId() async {
    return _storage.read(key: 'user_id');
  }

  static Future<String?> readFcmToken() async {
    return _storage.read(key: 'fcm_token');
  }

  static Future<void> saveUserId(String userId) async {
    await _storage.write(key: 'user_id', value: userId);
  }

  static Future<void> saveFcmToken(String token) async {
    await _storage.write(key: 'fcm_token', value: token);
  }

  static Future<void> saveSensitiveData({String userId = 'student-user-001'}) async {
    final demoData = buildDemoSensitiveData(userId: userId);
    await _storage.write(key: 'email', value: demoData['email']);
    await _storage.write(key: 'password', value: demoData['password']);
    await _storage.write(key: 'jwt_token', value: demoData['jwt_token']);
    await _storage.write(key: 'api_key', value: demoData['api_key']);
    await _storage.write(key: 'user_id', value: demoData['user_id']);
    await _storage.write(key: 'device_token', value: demoData['device_token']);
  }

  static Future<void> saveProvidedSensitiveData({
    required String email,
    required String password,
    required String jwtToken,
    required String apiKey,
    String userId = 'student-user-001',
  }) async {
    await _storage.write(key: 'email', value: email);
    await _storage.write(key: 'password', value: password);
    await _storage.write(key: 'jwt_token', value: jwtToken);
    await _storage.write(key: 'api_key', value: apiKey);
    await _storage.write(key: 'user_id', value: userId);
    await _storage.write(key: 'device_token', value: 'device-$userId');
  }

  static Future<void> deleteSensitiveData() async {
    for (final key in sensitiveKeys) {
      await _storage.delete(key: key);
    }
    await _storage.delete(key: 'fcm_token');
  }
}
