import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';
import 'package:safety_app/services/database_service.dart';
import 'package:safety_app/screens/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UploadDc3Screen extends StatefulWidget {
  const UploadDc3Screen({super.key});

  @override
  State<UploadDc3Screen> createState() => _UploadDc3ScreenState();
}

class _UploadDc3ScreenState extends State<UploadDc3Screen> {
  // Gestor de estado para la UI
  bool _isUploading = false;
  bool _isPremiumUser = true; // Modo de prueba

  // Controladores y variables del formulario
  final _nameController = TextEditingController();
  final _courseNameController = TextEditingController();
  DateTime? _selectedDate;
  File? _selectedFile;
  String? _fileName;

  // Instancias de servicios de Firebase
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  @override
  void initState() {
    super.initState();
    // TODO: Reactivar esto antes de publicar la app
    // _checkPremiumStatus();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _courseNameController.dispose();
    super.dispose();
  }

  // Se mantiene para cuando se reactive el modo de producción
  Future<void> _checkPremiumStatus() async {
    setState(() { _isPremiumUser = false; });
    bool isPremium = await _databaseService.isUserPremiumStream.first;
    if (mounted) {
      setState(() {
        _isPremiumUser = isPremium;
      });
    }
  }

  // ✅ LÓGICA SIMPLIFICADA: Solo selecciona el archivo
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return;

    final file = File(result.files.single.path!);
    const maxFileSizeInBytes = 300 * 1024; // 300 KB

    if (file.lengthSync() > maxFileSizeInBytes) {
      _showSnackBar('El archivo excede el límite de 300 KB.', isError: true);
      return;
    }

    setState(() {
      _selectedFile = file;
      _fileName = result.files.single.name;
    });
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  // ✅ LÓGICA SIMPLIFICADA: Sube el archivo directamente a la carpeta final
  Future<void> _uploadData() async {
    if (_nameController.text.isEmpty ||
        _courseNameController.text.isEmpty ||
        _selectedDate == null ||
        _selectedFile == null) {
      _showSnackBar('Por favor, completa todos los campos.', isError: true);
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showSnackBar('Error de autenticación.', isError: true);
      return;
    }

    setState(() { _isUploading = true; });

    try {
      // Sube el archivo directamente a la carpeta final
      final finalPath = 'user_dc3s/$userId/${DateTime.now().millisecondsSinceEpoch}_$_fileName';
      final ref = FirebaseStorage.instance.ref(finalPath);

      await ref.putFile(_selectedFile!);
      final fileUrl = await ref.getDownloadURL();

      // Llama a la función para guardar en Airtable
      final callable = _functions.httpsCallable('uploadDc3ToAirtable');
      final response = await callable.call(<String, dynamic>{
        'workerName': _nameController.text,
        'courseName': _courseNameController.text,
        'executionDate': _selectedDate!.toIso8601String(),
        'fileUrl': fileUrl,
        'fileName': _fileName,
      });

      if (response.data['success'] == true) {
        _showSnackBar('¡DC-3 subido con éxito!');
        _resetForm();
      } else {
        throw Exception(response.data['error'] ?? 'Ocurrió un error desconocido.');
      }

    } catch (e) {
      _showSnackBar('Error al subir el archivo: ${e.toString()}', isError: true);
    } finally {
      if(mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _resetForm() {
    setState(() {
      _nameController.clear();
      _courseNameController.clear();
      _selectedDate = null;
      _selectedFile = null;
      _fileName = null;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subir DC-3'),
      ),
      body: _isPremiumUser ? _buildUploadForm() : _buildPremiumGate(),
    );
  }

  Widget _buildPremiumGate() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium, size: 80, color: Colors.amber.shade600),
            const SizedBox(height: 24),
            Text(
              'Función Premium',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Para subir y resguardar tus constancias DC-3 de forma segura, necesitas ser un usuario Premium.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade500, Colors.orangeAccent.shade400],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(30.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withAlpha(77),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: const Text(
                  'Hazte Premium',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildUploadForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre del Trabajador',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _courseNameController,
            decoration: const InputDecoration(
              labelText: 'Nombre del Curso',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.school_outlined),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Periodo de Ejecución',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              child: Text(
                _selectedDate == null ? 'No seleccionada' : DateFormat('dd/MM/yyyy').format(_selectedDate!),
              ),
            ),
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: _pickFile,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_file, size: 40, color: Theme.of(context).primaryColor),
                  const SizedBox(height: 8),
                  Text(
                    _fileName ?? 'Toca para seleccionar un archivo PDF',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _fileName != null ? Colors.black : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Tamaño máximo: 300 KB', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: (_isUploading || _selectedFile == null) ? null : _uploadData,
            icon: _isUploading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.cloud_upload_outlined),
            label: Text(_isUploading ? 'Subiendo...' : 'Subir DC-3'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}