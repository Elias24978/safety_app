// lib/screens/escritorio_screen.dart
import 'package:flutter/material.dart';

class EscritorioScreen extends StatelessWidget {
  const EscritorioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escritorio Premium')),
      body: const Center(
        child: Text(
          '¡Bienvenido a tu Escritorio Premium!',
          style: TextStyle(fontSize: 20, color: Colors.deepPurple),
        ),
      ),
    );
  }
}