import 'package:flutter/material.dart';

class FakeGpsWarningScreen extends StatelessWidget {
  final VoidCallback onReload;
  const FakeGpsWarningScreen({Key? key, required this.onReload})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning, color: Colors.yellow, size: 64),
              const SizedBox(height: 24),
              const Text(
                'Se detectó una ubicación falsa (Fake GPS).\nPor favor, desactívala para continuar.',
                style: TextStyle(color: Colors.white, fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onReload,
                child: const Text('Recargar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
