// lib/models/formato_category_model.dart

class FormatoCategory {
  final String id;
  final String title;
  final String tableName;

  FormatoCategory({
    required this.id,
    required this.title,
    required this.tableName
  });

  factory FormatoCategory.fromJson(Map<String, dynamic> json) {
    return FormatoCategory(
      id: json['id'],
      // Corregido: usa 'Title' para que coincida con tu columna de Airtable
      title: json['fields']['Title'] ?? 'Sin Título',

      // Este campo buscará la nueva columna 'TableName' que debes crear
      tableName: json['fields']['TableName'] ?? '',
    );
  }
}