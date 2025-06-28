import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Aquí podrías poner otra imagen si quisieras
              const Spacer(),
              ElevatedButton(
                onPressed: () { /* TODO: Navegar a Login */ },
                child: const Text('Login'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () { /* TODO: Navegar a Register */ },
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}