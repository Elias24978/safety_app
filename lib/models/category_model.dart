// lib/models/category_model.dart

class Category {
  final String id;
  final String title;

  Category({required this.id, required this.title});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      // Asegúrate de que tu columna se llame 'Title' en Airtable
      title: json['fields']['Title'] ?? 'Sin Título',
    );
  }
}