import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// ✅ Importamos Firebase Auth
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safety_app/models/candidato_model.dart';
import 'package:safety_app/services/bolsa_trabajo_service.dart';

class EditarCvScreen extends StatefulWidget {
  final Candidato candidato;

  const EditarCvScreen({super.key, required this.candidato});

  @override
  State<EditarCvScreen> createState() => _EditarCvScreenState();
}

class _EditarCvScreenState extends State<EditarCvScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bolsaTrabajoService = BolsaTrabajoService();
  bool _isLoading = false;

  late TextEditingController _nombreController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  late TextEditingController _fechaNacimientoController;
  late TextEditingController _estadoController;
  late TextEditingController _ciudadController;
  late TextEditingController _resumenController;

  String? _selectedNivelEstudios;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();

    // Obtenemos el usuario actual para asegurar que el email coincida
    final currentUser = FirebaseAuth.instance.currentUser;

    _nombreController = TextEditingController(text: widget.candidato.nombre);

    // ✅ SEGURIDAD: Usamos el email de la sesión actual, o el del candidato como respaldo
    _emailController = TextEditingController(text: currentUser?.email ?? widget.candidato.email);

    _telefonoController = TextEditingController(text: widget.candidato.telefono);
    _estadoController = TextEditingController(text: widget.candidato.estado);
    _ciudadController = TextEditingController(text: widget.candidato.ciudad);
    _resumenController = TextEditingController(text: widget.candidato.resumenCv);
    _fechaNacimientoController = TextEditingController();

    if (widget.candidato.fechaNacimiento != null && widget.candidato.fechaNacimiento!.isNotEmpty) {
      try {
        _selectedDate = DateTime.parse(widget.candidato.fechaNacimiento!);
        _fechaNacimientoController.text = DateFormat('dd-MM-yyyy').format(_selectedDate!);
      } catch (e) {
        debugPrint('Error al parsear fecha: $e');
      }
    }

    _selectedNivelEstudios = widget.candidato.nivelDeEstudios;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final fechaNacimientoAirtable = _selectedDate != null
          ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
          : null;

      final Map<String, dynamic> fieldsToUpdate = {
        'Nombre_Completo': _nombreController.text,
        'Email': _emailController.text, // Se envía el mismo email verificado
        'Telefono': _telefonoController.text,
        'Fecha_de_Nacimiento': fechaNacimientoAirtable,
        'Estado': _estadoController.text,
        'Ciudad': _ciudadController.text,
        'Resumen_cv': _resumenController.text,
        'Nivel_de_estudios': _selectedNivelEstudios,
      };

      final success = await _bolsaTrabajoService.updateCandidatoProfile(
        widget.candidato.recordId,
        fieldsToUpdate,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Perfil actualizado!')));
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al actualizar el perfil.')));
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _fechaNacimientoController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Nombre Completo*'), validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null),
              const SizedBox(height: 16),

              // --- CAMPO DE EMAIL BLOQUEADO ---
              TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email de Contacto*',
                    // Estilo visual de solo lectura
                    filled: true,
                    fillColor: Colors.grey[200],
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    // Mantiene el borde por defecto si no está deshabilitado (aunque aquí siempre será readOnly)
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  readOnly: true, // Impide la edición
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
                value: _selectedNivelEstudios,
                hint: const Text('Nivel de estudios*'),
                items: ['Preparatoria', 'Licenciatura', 'Maestría', 'Otro'].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                onChanged: (newValue) => setState(() => _selectedNivelEstudios = newValue),
                validator: (v) => v == null ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _resumenController, decoration: const InputDecoration(labelText: 'Resumen Profesional*', alignLabelWithHint: true), maxLines: 5, validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Guardar Cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}