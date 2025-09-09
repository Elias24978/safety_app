// lib/models/norma_model.dart

class Norma {
  final String id;
  final String name;
  final String? fileUrl; // La URL del archivo puede ser opcional

  Norma({
    required this.id,
    required this.name,
    this.fileUrl,
  });

  factory Norma.fromJson(Map<String, dynamic> json) {
    String? url;
    // El campo 'File' en Airtable es una lista, verificamos que no esté vacía
    if (json['fields']['File'] != null && (json['fields']['File'] as List).isNotEmpty) {
      // Extraemos la URL del primer archivo adjunto
      url = json['fields']['File'][0]['url'];
    }

    return Norma(
      id: json['id'],
      // Asegúrate de que tu columna se llame 'Name' en Airtable
      name: json['fields']['Name'] ?? 'Sin nombre',
      fileUrl: url,
    );
  }
}