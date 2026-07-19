import 'dart:async';

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

class _LoginWithGpsCheckState extends State<LoginWithGpsCheck>
    with WidgetsBindingObserver {
  bool? _isFakeGps;
  bool _loading = true;
  Timer? _monitorTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAndCheckGps();
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && !_loading) {
      _checkFakeGps(silent: true);
    }
  }

  void _startFakeGpsMonitor() {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _loading || _isFakeGps == true) return;
      _checkFakeGps(silent: true);
    });
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

  Future<void> _checkFakeGps({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _errorMsg = null;
      });
    }
    try {
      final isFake = await FakeGpsDetector.isLocationMocked().timeout(
        const Duration(seconds: 10),
        onTimeout: () => false,
      );
      if (!mounted) return;

      if (isFake) {
        setState(() {
          _isFakeGps = true;
          _loading = false;
        });
        return;
      }

      if (!silent) {
        setState(() {
          _isFakeGps = false;
          _loading = false;
        });
        _startFakeGpsMonitor();
      }
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _errorMsg = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
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
