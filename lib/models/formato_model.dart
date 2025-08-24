// lib/models/formato_model.dart
//Este modelo representará cada tarjeta de la lista.

class Formato {
  final String id;
  final String title;
  final String description;
  final String? previewUrl; // <-- Renombrado para más claridad
  final String? fileUrl;

  Formato({
    required this.id,
    required this.title,
    required this.description,
    this.previewUrl,
    this.fileUrl,
  });

  factory Formato.fromJson(Map<String, dynamic> json) {
    String? localPreviewUrl;
    String? localFileUrl;

    // Buscamos el nuevo campo 'File' que contiene los PDFs
    final attachments = json['fields']['File'] as List<dynamic>?;
    if (attachments != null && attachments.isNotEmpty) {
      final firstAttachment = attachments[0];

      // 1. Obtenemos el enlace directo al archivo PDF
      localFileUrl = firstAttachment['url'] as String?;

      // 2. Buscamos la vista previa (thumbnail) que Airtable genera
      final thumbnails = firstAttachment['thumbnails'] as Map<String, dynamic>?;
      if (thumbnails != null) {
        // Usamos la vista previa grande para mejor calidad
        final largeThumbnail = thumbnails['large'] as Map<String, dynamic>?;
        localPreviewUrl = largeThumbnail?['url'] as String?;
      }
    }

    return Formato(
      id: json['id'],
      title: json['fields']['Title'] ?? 'Sin Título',
      description: json['fields']['Description'] ?? 'Sin descripción.',
      previewUrl: localPreviewUrl,
      fileUrl: localFileUrl,
    );
  }
}