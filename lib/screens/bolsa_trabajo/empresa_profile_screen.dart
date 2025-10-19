import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safety_app/models/empresa_model.dart';
// ✅ CAMBIO: Se importa el servicio correcto para la bolsa de trabajo
import 'package:safety_app/services/bolsa_trabajo_service.dart';
import 'package:safety_app/utils/dialogs.dart';

class EmpresaProfileScreen extends StatefulWidget {
  final Empresa? empresa;
  const EmpresaProfileScreen({super.key, this.empresa});

  @override
  State<EmpresaProfileScreen> createState() => _EmpresaProfileScreenState();
}

class _EmpresaProfileScreenState extends State<EmpresaProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  // ✅ CAMBIO: Se instancia el servicio correcto
  final BolsaTrabajoService _bolsaTrabajoService = BolsaTrabajoService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  late TextEditingController _nombreEmpresaController;
  late TextEditingController _emailEmpresaController;
  late TextEditingController _telefonoController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreEmpresaController = TextEditingController(text: widget.empresa?.nombreEmpresa ?? '');
    _emailEmpresaController = TextEditingController(text: widget.empresa?.emailEmpresa ?? currentUser?.email ?? '');
    _telefonoController = TextEditingController(text: widget.empresa?.telefono ?? '');
  }

  @override
  void dispose() {
    _nombreEmpresaController.dispose();
    _emailEmpresaController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (currentUser == null) {
      if (mounted) showSnackBar(context, 'Error: Usuario no autenticado.', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    final Map<String, dynamic> fields = {
      'UserID_Creador': currentUser!.uid,
      'Nombre_Empresa': _nombreEmpresaController.text,
      'Email_Empresa': _emailEmpresaController.text,
      'telefono': _telefonoController.text.isNotEmpty ? _telefonoController.text : null,
    };

    try {
      bool success;
      if (widget.empresa == null) {
        // ✅ CAMBIO: Se llama al método desde la nueva variable de servicio
        success = await _bolsaTrabajoService.createEmpresaProfile(fields);
      } else {
        // ✅ CAMBIO: Se llama al método desde la nueva variable de servicio
        success = await _bolsaTrabajoService.updateEmpresaProfile(widget.empresa!.recordId, fields);
      }

      if (!mounted) return;

      if (success) {
        showSnackBar(context, widget.empresa == null ? 'Perfil creado exitosamente.' : 'Perfil actualizado exitosamente.');
        Navigator.pop(context, true);
      } else {
        throw Exception('La operación en Airtable falló.');
      }
    } catch (e) {
      if (mounted) showSnackBar(context, 'Error al guardar el perfil: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.empresa == null ? 'Crear Perfil de Empresa' : 'Editar Perfil de Empresa'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreEmpresaController,
                decoration: const InputDecoration(labelText: 'Nombre de la Empresa', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Este campo es obligatorio.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailEmpresaController,
                decoration: const InputDecoration(labelText: 'Email de Contacto', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Este campo es obligatorio.';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Por favor, ingresa un email válido.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono (Opcional)', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text(
                  widget.empresa == null ? 'Crear Perfil' : 'Actualizar Perfil',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}