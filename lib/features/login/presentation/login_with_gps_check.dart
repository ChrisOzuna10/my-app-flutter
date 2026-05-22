import 'package:flutter/material.dart';
import 'package:my_app/features/location/data/fake_gps_detector.dart';
import 'package:my_app/features/location/presentation/fake_gps_warning_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'login_screen.dart';

class LoginWithGpsCheck extends StatefulWidget {
  const LoginWithGpsCheck({Key? key}) : super(key: key);

  @override
  State<LoginWithGpsCheck> createState() => _LoginWithGpsCheckState();
}

class _LoginWithGpsCheckState extends State<LoginWithGpsCheck> {
  bool? _isFakeGps;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initAndCheckGps();
  }

  Future<void> _initAndCheckGps() async {
    setState(() => _loading = true);
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _isFakeGps = null;
          _loading = false;
        });
        return;
      }
    }
    await _checkFakeGps();
  }

  String? _errorMsg;

  Future<void> _checkFakeGps() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final isFake = await FakeGpsDetector.isLocationMocked().timeout(
        const Duration(seconds: 10),
        onTimeout: () => false,
      );
      if (!mounted) return;
      setState(() {
        _isFakeGps = isFake;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg =
            'No se pudo obtener la ubicación. Asegúrate de tener el GPS activo.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_errorMsg != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMsg!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initAndCheckGps,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_isFakeGps == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Permiso de ubicación denegado. Actívalo para continuar.',
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initAndCheckGps,
                child: const Text('Solicitar permiso'),
              ),
            ],
          ),
        ),
      );
    }
    if (_isFakeGps == true) {
      return FakeGpsWarningScreen(onReload: _checkFakeGps);
    }
    return const LoginScreen();
  }
}
