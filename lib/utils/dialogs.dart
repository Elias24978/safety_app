import 'package:flutter/material.dart';

// Esta función nos ayuda a mostrar mensajes rápidos en la parte inferior de la pantalla.
void showSnackBar(BuildContext context, String message, [Color backgroundColor = Colors.green]) {
  // Nos aseguramos de que el widget aún exista antes de mostrar el SnackBar.
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
    ),
  );
}