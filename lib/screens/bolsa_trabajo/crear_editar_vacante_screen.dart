import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safety_app/models/empresa_model.dart';
import 'package:safety_app/models/vacante_model.dart';
import 'package:safety_app/services/bolsa_trabajo_service.dart';
import 'package:safety_app/utils/dialogs.dart';

class CrearEditarVacanteScreen extends StatefulWidget {
  final Vacante? vacante;

  const CrearEditarVacanteScreen({super.key, this.vacante});

  @override
  State<CrearEditarVacanteScreen> createState() => _CrearEditarVacanteScreenState();
}

class _CrearEditarVacanteScreenState extends State<CrearEditarVacanteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bolsaTrabajoService = BolsaTrabajoService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  late TextEditingController _tituloController;
  late TextEditingController _descripcionController;
  late TextEditingController _sueldoController;
  late TextEditingController _ubicacionController;
  bool _aceptaForaneos = false;
  String _visibilidad = 'Visible';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.vacante?.titulo ?? '');
    _descripcionController = TextEditingController(text: widget.vacante?.descripcion ?? '');
    _sueldoController = TextEditingController(text: widget.vacante?.sueldo?.toString() ?? '');
    _ubicacionController = TextEditingController(text: widget.vacante?.ubicacion ?? '');
    _aceptaForaneos = widget.vacante?.aceptaForaneos ?? false;
    _visibilidad = widget.vacante?.visibilidadOferta ?? 'Visible';
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _sueldoController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }

  Future<void> _guardarVacante() async {
    if (!_formKey.currentState!.validate()) return;

    final user = currentUser;
    if (user == null) {
      if (mounted) showSnackBar(context, 'Necesitas iniciar sesión para publicar.', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final Empresa? empresa = await _bolsaTrabajoService.getEmpresaProfile(user.uid);
      if (empresa == null) {
        throw Exception('No se encontró el perfil de tu empresa.');
      }

      final fields = {
        'Titulo_Vacante': _tituloController.text,
        'Descripcion_Puesto': _descripcionController.text,
        'Ubicacion': _ubicacionController.text,
        'Sueldo_Ofertado': double.tryParse(_sueldoController.text),
        'Acepta_Foraneos': _aceptaForaneos,
        'Visibilidad_Oferta': _visibilidad,
        'Empresas': [empresa.recordId],
      };

      bool success;
      if (widget.vacante == null) {
        success = await _bolsaTrabajoService.createVacante(fields);
      } else {
        success = await _bolsaTrabajoService.updateVacante(widget.vacante!.id, fields);
      }

      if (!mounted) return;

      if (success) {
        showSnackBar(context, 'Vacante guardada exitosamente.');
        Navigator.pop(context, true);
      } else {
        throw Exception('La operación en Airtable no tuvo éxito.');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error al guardar la vacante: ${e.toString()}', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ ELIMINADO: Se quitó la función _onArchivar

  // Lógica para eliminar la vacante permanentemente
  Future<void> _onEliminar() async {
    final bool confirmado = await _showDeleteConfirmation(
      title: '¡ACCIÓN PERMANENTE!',
      content: '¿Estás seguro de que quieres eliminar esta vacante? Esta acción no se puede deshacer y borrará la vacante para todos los candidatos.',
      confirmText: 'Sí, Eliminar',
      isDestructive: true,
    );

    if (!confirmado || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final success = await _bolsaTrabajoService.deleteVacante(widget.vacante!.id);
      if (!mounted) return;
      if (success) {
        showSnackBar(context, 'Vacante eliminada permanentemente.');
        Navigator.pop(context, true); // Regresa y refresca la lista
      } else {
        throw Exception('No se pudo eliminar la vacante.');
      }
    } catch (e) {
      if (mounted) showSnackBar(context, e.toString(), Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Diálogo de confirmación genérico
  Future<bool> _showDeleteConfirmation({
    required String title,
    required String content,
    required String confirmText,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: isDestructive ? Colors.red : Theme.of(context).primaryColor,
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vacante == null ? 'Publicar Vacante' : 'Editar Vacante'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(labelText: 'Título del Puesto', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Este campo es obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción del Puesto', border: OutlineInputBorder()),
                maxLines: 5,
                validator: (value) => value!.isEmpty ? 'Este campo es obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ubicacionController,
                decoration: const InputDecoration(labelText: 'Ubicación (Ej. Jalisco)', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Este campo es obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sueldoController,
                decoration: const InputDecoration(labelText: 'Sueldo Mensual (Opcional)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('¿Acepta candidatos foráneos?'),
                value: _aceptaForaneos,
                onChanged: (bool value) {
                  setState(() {
                    _aceptaForaneos = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _visibilidad,
                decoration: const InputDecoration(labelText: 'Estado de la Publicación', border: OutlineInputBorder()),
                items: ['Visible', 'Oculta'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _visibilidad = newValue!;
                  });
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _guardarVacante,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text(widget.vacante == null ? 'Publicar Vacante' : 'Guardar Cambios'),
              ),

              // ✅ CAMBIO: Se eliminó el botón de Archivar y el texto "Zona de Peligro"
              if (widget.vacante != null) ...[
                const SizedBox(height: 24),
                const Divider(thickness: 1),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _onEliminar,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Eliminar Permanentemente'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[800],
                    side: BorderSide(color: Colors.red[800]!),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}