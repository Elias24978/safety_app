import 'package:flutter/material.dart';
import 'package:safety_app/models/candidato_model.dart';
import 'package:safety_app/screens/document_viewer_screen.dart'; // Asegúrate que esta ruta es correcta
import 'package:url_launcher/url_launcher.dart';

class DetalleCandidatoReclutadorScreen extends StatelessWidget {
  final Candidato candidato;

  const DetalleCandidatoReclutadorScreen({super.key, required this.candidato});

  // Helper para lanzar URLs (email, teléfono, CV)
  Future<void> _launchURL(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el enlace: $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(candidato.nombre),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de Información Personal
            _buildInfoCard(
              context,
              title: 'Información de Contacto',
              children: [
                _InfoRow(icon: Icons.person, text: candidato.nombre),
                if (candidato.email.isNotEmpty)
                  _InfoRow(icon: Icons.email, text: candidato.email, onTap: () => _launchURL('mailto:${candidato.email}', context)),
                if (candidato.telefono != null && candidato.telefono!.isNotEmpty)
                  _InfoRow(icon: Icons.phone, text: candidato.telefono!, onTap: () => _launchURL('tel:${candidato.telefono}', context)),
                if (candidato.estado != null && candidato.estado!.isNotEmpty)
                  _InfoRow(icon: Icons.location_city, text: '${candidato.ciudad ?? ''}, ${candidato.estado ?? ''}'),
              ],
            ),
            const SizedBox(height: 20),

            // Sección de Resumen Profesional
            _buildInfoCard(
              context,
              title: 'Resumen Profesional',
              children: [
                Text(
                  candidato.resumenCv ?? 'No se proporcionó un resumen.',
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Botón para ver el CV
            if (candidato.cvUrl != null && candidato.cvUrl!.isNotEmpty)
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Ver CV Completo'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DocumentViewerScreen(
                          fileUrl: candidato.cvUrl!,
                          // ✅ CAMBIO: Se corrigió 'title' por 'documentTitle'
                          documentTitle: 'CV de ${candidato.nombre}',
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para crear las tarjetas de información
  Widget _buildInfoCard(BuildContext context, {required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }
}

// Widget auxiliar para las filas de información con ícono
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const _InfoRow({required this.icon, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isClickable = onTap != null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[700]),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: isClickable ? Theme.of(context).primaryColor : Colors.black87,
                  decoration: isClickable ? TextDecoration.underline : TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}