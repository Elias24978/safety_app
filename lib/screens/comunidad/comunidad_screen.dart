import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ComunidadScreen extends StatelessWidget {
  const ComunidadScreen({super.key});

  // Lógica inteligente para abrir enlaces según el tipo de red
  Future<void> _launchURL(BuildContext context, String urlString, {bool isInternalView = false}) async {
    try {
      final Uri url = Uri.parse(urlString);

      // ESTRATEGIA DE APERTURA:
      // 1. Blog: 'inAppWebView' -> Se abre DENTRO de tu app (mejor retención).
      // 2. Facebook: 'externalApplication' -> Intenta abrir la APP de Facebook nativa.
      final mode = isInternalView
          ? LaunchMode.inAppWebView
          : LaunchMode.externalApplication;

      // Intentamos abrir con el modo ideal
      try {
        if (!await launchUrl(url, mode: mode)) {
          throw 'No se pudo lanzar en modo $mode';
        }
      } catch (e) {
        // FALLBACK (Plan B):
        // Si falla (ej. no tiene la app de Facebook instalada),
        // forzamos abrir en el navegador normal (Chrome/Safari) del celular.
        debugPrint("Fallo modo externo, intentando navegador: $e");
        if (!await launchUrl(url, mode: LaunchMode.platformDefault)) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No se pudo abrir el enlace: $urlString'), backgroundColor: Colors.red),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error general al abrir URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Comunidad Safety',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        children: [
          const Text(
            "¡Conéctate con nosotros!",
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D3436)
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            "Accede a noticias, normativas actualizadas y únete a la conversación con otros profesionales.",
            style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // --- SECCIÓN NOTICIAS ---
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
                "Noticias y Artículos",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 14)
            ),
          ),

          // 1. BLOG OFICIAL (Se abre dentro de la App)
          _MenuCard(
            icon: FontAwesomeIcons.bloggerB,
            iconColor: const Color(0xFFFF5722), // Naranja Blogger
            iconBgColor: const Color(0xFFFFCCBC).withOpacity(0.3),
            title: "Blog Oficial",
            subtitle: "Artículos técnicos de SafetyMex",
            trailingIcon: Icons.article_outlined,
            onTap: () => _launchURL(
                context,
                "https://safetymex.blogspot.com/",
                isInternalView: true // <--- TRUE: Navegador interno
            ),
          ),

          const SizedBox(height: 30),

          // --- SECCIÓN REDES SOCIALES ---
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
                "Redes Sociales",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 14)
            ),
          ),

          // 2. FACEBOOK (Intenta abrir la App con tu perfil específico)
          _MenuCard(
            icon: FontAwesomeIcons.facebookF,
            iconColor: const Color(0xFF1877F2), // Azul Facebook
            iconBgColor: const Color(0xFFE7F3FF),
            title: "Facebook",
            subtitle: "Únete a nuestro grupo de comunidad",
            trailingIcon: Icons.open_in_new,
            onTap: () => _launchURL(
                context,
                "https://www.facebook.com/profile.php?id=61581363958913", // <--- ENLACE ACTUALIZADO
                isInternalView: false // <--- FALSE: Busca la App externa
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final IconData trailingIcon;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.trailingIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: FaIcon(icon, color: iconColor, size: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3436),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(trailingIcon, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}