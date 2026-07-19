import 'package:flutter/material.dart';

import '../../services/secure_storage_service.dart';

class SensitiveDataScreen extends StatefulWidget {
  const SensitiveDataScreen({super.key});

  @override
  State<SensitiveDataScreen> createState() => _SensitiveDataScreenState();
}

class _SensitiveDataScreenState extends State<SensitiveDataScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _jwtController = TextEditingController();
  final _apiKeyController = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDemoValues();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _jwtController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadDemoValues() async {
    final demoData = SecureStorageService.buildDemoSensitiveData();

    if (!mounted) return;

    setState(() {
      _emailController.text = demoData['email'] ?? '';
      _passwordController.text = demoData['password'] ?? '';
      _jwtController.text = demoData['jwt_token'] ?? '';
      _apiKeyController.text = demoData['api_key'] ?? '';
    });
  }

  Future<void> _saveSensitiveData() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final jwt = _jwtController.text.trim();
    final apiKey = _apiKeyController.text.trim();

    if (email.isEmpty || password.isEmpty || jwt.isEmpty || apiKey.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa los 4 campos sensibles.')),
      );
      return;
    }

    setState(() => _saving = true);

    await SecureStorageService.saveProvidedSensitiveData(
      email: email,
      password: password,
      jwtToken: jwt,
      apiKey: apiKey,
      userId: email,
    );

    if (!mounted) return;

    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Datos sensibles guardados para $email.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Datos sensibles')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Captura 4 campos sensibles y guárdalos automáticamente en almacenamiento seguro.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Usuario'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _jwtController,
              decoration: const InputDecoration(labelText: 'JWT Token'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(labelText: 'API Key'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saving ? null : _saveSensitiveData,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock),
              label: Text(_saving ? 'Guardando…' : 'Guardar datos sensibles'),
            ),
            const SizedBox(height: 16),
            const Text(
              'La eliminación remota por FCM será específica para el usuario asociado a estos datos.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
