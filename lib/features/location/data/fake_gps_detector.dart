import 'package:geolocator/geolocator.dart';

class FakeGpsDetector {
  /// Devuelve true si se detecta Fake GPS, false si todo está bien.
  static Future<bool> isLocationMocked() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      throw Exception('Permiso de ubicación no otorgado');
    }

    Position? pos;
    if (serviceEnabled) {
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception(
              'No se pudo obtener una ubicación actual. Asegúrate de tener GPS activo y señal.'),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }
    } else {
      pos = await Geolocator.getLastKnownPosition();
    }

    if (pos == null) {
      final errorReason = serviceEnabled
          ? 'No se pudo obtener una ubicación actual.'
          : 'Servicio de ubicación desactivado o sin señal.';
      throw Exception(
          '$errorReason Activa el GPS y espera a que haya señal.');
    }

    return pos.isMocked;
  }
}
