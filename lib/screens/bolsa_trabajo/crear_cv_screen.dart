import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:safety_app/screens/bolsa_trabajo/candidato_dashboard_screen.dart';
// ✅ Importamos el servicio correcto
import 'package:safety_app/services/bolsa_trabajo_service.dart';

class CrearCvScreen extends StatefulWidget {
  const CrearCvScreen({super.key});

  @override
  State<CrearCvScreen> createState() => _CrearCvScreenState();
}

class _CrearCvScreenState extends State<CrearCvScreen> {
  final _formKey = GlobalKey<FormState>();
  // ✅ Instancia del servicio correcto
  final _bolsaTrabajoService = BolsaTrabajoService();
  bool _isLoading = false;
  File? _cvFile;
  String? _cvFileName;

  // Controladores
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  final _estadoController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _resumenController = TextEditingController();

  String? _selectedSexo;
  String? _selectedNivelEstudios;
  bool _perfilActivo = true;

  @override
  void initState() {
    super.initState();
    // Pre-llenamos el email y nombre con los datos de Firebase Auth
    _emailController.text = FirebaseAuth.instance.currentUser?.email ?? '';
    _nombreController.text = FirebaseAuth.instance.currentUser?.displayName ?? '';
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _fechaNacimientoController.dispose();
    _estadoController.dispose();
    _ciudadController.dispose();
    _resumenController.dispose();
    super.dispose();
  }

  Future<void> _pickAndValidateFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result == null) return;

    final file = File(result.files.single.path!);
    final fileSize = await file.length();

    if (fileSize > 500 * 1024) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El archivo es demasiado grande. Límite: 500 KB.'), backgroundColor: Colors.red,));
      return;
    }

    setState(() {
      _cvFile = file;
      _cvFileName = result.files.single.name;
    });
  }

  Future<String?> _uploadCvFile(File file, String userId, String fileName) async {
    try {
      final ref = FirebaseStorage.instance.ref('cvs/$userId/$fileName');
      final metadata = SettableMetadata(contentType: "application/pdf");
      final uploadTask = ref.putFile(file, metadata);
      final snapshot = await uploadTask.whenComplete(() => {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error al subir archivo a Firebase Storage: $e');
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (_cvFile == null || _cvFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, adjunta tu CV en formato PDF.')));
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de autenticación.')));
        setState(() => _isLoading = false);
        return;
      }

      final cvUrl = await _uploadCvFile(_cvFile!, user.uid, _cvFileName!);

      if (cvUrl == null) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al subir el CV. Inténtalo de nuevo.')));
        setState(() => _isLoading = false);
        return;
      }

      final fechaNacimientoAirtable = _fechaNacimientoController.text.isNotEmpty
          ? DateFormat('yyyy-MM-dd').format(DateFormat('dd-MM-yyyy').parse(_fechaNacimientoController.text))
          : null;

      final Map<String, dynamic> fields = {
        'UserID': user.uid,
        'Nombre_Completo': _nombreController.text,
        'Email': _emailController.text, // Se enviará el email pre-cargado
        'Telefono': _telefonoController.text,
        'Fecha_de_Nacimiento': fechaNacimientoAirtable,
        'Sexo': _selectedSexo,
        'Estado': _estadoController.text,
        'Ciudad': _ciudadController.text,
        'Resumen_cv': _resumenController.text,
        'CV_URL': cvUrl,
        'CV_FileName': _cvFileName,
        'Nivel_de_estudios': _selectedNivelEstudios,
        'Perfil_Activo': _perfilActivo ? 'Mostrar' : 'Ocultar',
      };

      fields.removeWhere((key, value) => value == null || (value is String && value.isEmpty));

      // ✅ Llamada al servicio correcto
      final success = await _bolsaTrabajoService.createCandidatoProfile(fields);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Perfil creado con éxito!')));
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const CandidatoDashboardScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar el perfil en Airtable.')));
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _fechaNacimientoController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crea tu Perfil de Candidato')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre Completo*'),
                  validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null
              ),
              const SizedBox(height: 16),

              // --- CAMPO DE EMAIL BLOQUEADO ---
              TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email de Contacto*',
                    // Color de fondo para indicar que es solo lectura
                    filled: true,
                    fillColor: Colors.grey[200],
                    // Borde deshabilitado visualmente para reforzar que no es editable
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  readOnly: true, // Esto impide la edición
                  validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null
              ),
              // --------------------------------

              const SizedBox(height: 16),
              TextFormField(controller: _telefonoController, decoration: const InputDecoration(labelText: 'Teléfono*'), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fechaNacimientoController,
                decoration: const InputDecoration(labelText: 'Fecha de Nacimiento*', suffixIcon: Icon(Icons.calendar_today)),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _estadoController, decoration: const InputDecoration(labelText: 'Estado*'), validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null)),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(controller: _ciudadController, decoration: const InputDecoration(labelText: 'Ciudad*'), validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null)),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSexo,
                hint: const Text('Sexo*'),
                items: ['Hombre', 'Mujer'].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                onChanged: (newValue) => setState(() => _selectedSexo = newValue),
                validator: (v) => v == null ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedNivelEstudios,
                hint: const Text('Nivel de estudios*'),
                items: ['Preparatoria', 'Licenciatura', 'Maestría', 'Otro'].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                onChanged: (newValue) => setState(() => _selectedNivelEstudios = newValue),
                validator: (v) => v == null ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.attach_file),
                label: const Text('Adjuntar CV (PDF, máx 500kb)*'),
                onPressed: _pickAndValidateFile,
              ),
              if (_cvFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Archivo: $_cvFileName', style: TextStyle(color: Colors.green[700])),
                ),
              const SizedBox(height: 16),
              TextFormField(controller: _resumenController, decoration: const InputDecoration(labelText: 'Resumen Profesional*', alignLabelWithHint: true), maxLines: 5, validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Perfil visible para reclutadores'),
                subtitle: Text(_perfilActivo ? 'Tu perfil será visible' : 'Tu perfil estará oculto'),
                value: _perfilActivo,
                onChanged: (bool value) => setState(() => _perfilActivo = value),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Text('Guardar Perfil y Ver Vacantes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}