import 'package:flutter/material.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;

  // Hacemos que reciba un título para saber qué botón se presionó
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Center(
        child: Text(
          'Pantalla para "$title"\n(En construcción)',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}