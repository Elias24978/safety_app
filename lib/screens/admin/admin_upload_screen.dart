import 'package:flutter/material.dart';
import 'package:safety_app/utils/admin_uploader.dart';

class AdminUploadScreen extends StatefulWidget {
  const AdminUploadScreen({super.key});

  @override
  State<AdminUploadScreen> createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends State<AdminUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _jsonController = TextEditingController();
  bool _isLoading = false;

  Future<void> _subirCurso() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final uploader = AdminUploader();
    try {
      // Limpiamos espacios en blanco accidentales en el ID
      final id = _idController.text.trim();
      final jsonContent = _jsonController.text;

      await uploader.uploadCursoTemario(id, jsonContent);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Curso subido correctamente'), backgroundColor: Colors.green),
      );

      // Opcional: Limpiar campos tras éxito
      // _idController.clear();
      // _jsonController.clear();

    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Error de Subida"),
          content: SingleChildScrollView(child: Text(e.toString())),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cerrar"))],
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin: Subir Contenido"),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                "Sube el contenido privado (videos/examen) para un curso existente en Airtable.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // CAMPO ID
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: "ID del Curso en Airtable (rec...)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_key),
                ),
                validator: (v) => v!.isEmpty ? "El ID es obligatorio" : null,
              ),
              const SizedBox(height: 16),

              // CAMPO JSON
              Expanded(
                child: TextFormField(
                  controller: _jsonController,
                  decoration: const InputDecoration(
                    labelText: "Pegar JSON del Temario Aquí",
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: null, // Permite múltiples líneas
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  validator: (v) => v!.isEmpty ? "El JSON es obligatorio" : null,
                ),
              ),
              const SizedBox(height: 16),

              // BOTÓN SUBIR
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _subirCurso,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                  ),
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.cloud_upload),
                  label: const Text("SUBIR A FIRESTORE"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}