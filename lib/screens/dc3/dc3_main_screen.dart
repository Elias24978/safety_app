import 'package:flutter/material.dart';
import 'package:safety_app/screens/dc3/dc3_form_screen.dart';
import 'package:safety_app/screens/dc3/review_dc3_screen.dart';
import 'package:safety_app/screens/dc3/upload_dc3_screen.dart';
// IMPORTANTE: Importaremos la nueva pantalla que crearemos en el siguiente paso
import 'package:safety_app/screens/dc3/validar_dc3_screen.dart';

class Dc3MainScreen extends StatelessWidget {
  const Dc3MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificaciones DC-3'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Añadido para evitar desbordamiento en pantallas pequeñas
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gestión de Constancias',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Administra tus Constancias de Habilidades Laborales (DC-3).',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // 1. GENERADOR
              _buildOptionCard(
                context,
                icon: Icons.note_add_outlined,
                title: 'Generador de DC-3',
                subtitle: 'Crea y descarga una nueva constancia desde la app.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DC3FormScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),

              // 2. SUBIR EXTERNA
              _buildOptionCard(
                context,
                icon: Icons.cloud_upload_outlined,
                title: 'Subir Constancia Externa',
                subtitle: 'Almacena de forma segura un nuevo certificado DC-3.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UploadDc3Screen()),
                  );
                },
              ),
              const SizedBox(height: 16),

              // 3. MIS CONSTANCIAS
              _buildOptionCard(
                context,
                icon: Icons.inventory_2_outlined,
                title: 'Mis Constancias',
                subtitle: 'Consulta y comparte tus documentos subidos.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ReviewDc3Screen()),
                  );
                },
              ),
              const SizedBox(height: 16),

              // 🚨 4. NUEVO BOTÓN: VALIDACIÓN DE FOLIOS
              _buildOptionCard(
                context,
                icon: Icons.verified_user_outlined,
                title: 'Validar DC-3 SafetyMex',
                subtitle: 'Verifica la autenticidad de un certificado emitido por nosotros.',
                iconColor: Colors.green, // Dándole un toque de color diferente para destacar seguridad
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ValidarDc3Screen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
        Color? iconColor,
      }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: iconColor ?? Theme.of(context).primaryColor),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}