import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:safety_app/models/candidato_model.dart';
import 'package:safety_app/screens/bolsa_trabajo/editar_cv_screen.dart';
import 'package:safety_app/screens/bolsa_trabajo/role_selection_screen.dart';
import 'package:safety_app/services/bolsa_trabajo_service.dart'; // ✅ CAMBIO: Se importa el nuevo servicio

class MiCvScreen extends StatefulWidget {
  const MiCvScreen({super.key});

  @override
  State<MiCvScreen> createState() => _MiCvScreenState();
}

class _MiCvScreenState extends State<MiCvScreen> {
  // ✅ CAMBIO: Se usa la nueva clase de servicio
  final BolsaTrabajoService _bolsaTrabajoService = BolsaTrabajoService();
  Future<Candidato?>? _candidatoFuture;

  @override
  void initState() {
    super.initState();
    _loadCandidatoProfile();
  }

  void _loadCandidatoProfile() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      setState(() {
        // ✅ CAMBIO: Se llama al método desde la nueva variable
        _candidatoFuture = _bolsaTrabajoService.getCandidatoProfile(userId);
      });
    }
  }

  Future<void> _updateAirtableField(String recordId, Map<String, dynamic> fields) async {
    // ✅ CAMBIO: Se llama al método desde la nueva variable
    final success = await _bolsaTrabajoService.updateCandidatoProfile(recordId, fields);
    if (mounted) {
      if (success) {
        _loadCandidatoProfile();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al actualizar.')));
      }
    }
  }

  Future<void> _changePdf(Candidato candidato) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result == null) return;

    final file = File(result.files.single.path!);
    if (await file.length() > 500 * 1024) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El archivo excede los 500 KB.')));
      return;
    }

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subiendo nuevo CV...')));

    try {
      if (candidato.cvUrl != null && candidato.cvUrl!.isNotEmpty) {
        await FirebaseStorage.instance.refFromURL(candidato.cvUrl!).delete();
      }

      final newFileName = result.files.single.name;
      final ref = FirebaseStorage.instance.ref('cvs/${candidato.userId}/$newFileName');
      final metadata = SettableMetadata(contentType: "application/pdf");
      await ref.putFile(file, metadata);
      final newUrl = await ref.getDownloadURL();

      await _updateAirtableField(candidato.recordId, {
        'CV_URL': newUrl,
        'CV_FileName': newFileName,
      });

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cambiar el PDF: $e')));
    }
  }

  Future<void> _deleteProfile(Candidato candidato) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar tu perfil? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (candidato.cvUrl != null && candidato.cvUrl!.isNotEmpty) {
        await FirebaseStorage.instance.refFromURL(candidato.cvUrl!).delete();
      }
      // ✅ CAMBIO: Se llama al método desde la nueva variable
      final success = await _bolsaTrabajoService.deleteCandidatoProfile(candidato.recordId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil eliminado.')));
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Candidato?>(
      future: _candidatoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error al cargar tu perfil: ${snapshot.error ?? "No se encontraron datos."}'),
            ),
          );
        }

        final candidato = snapshot.data!;
        final isVisible = candidato.perfilActivo == 'Mostrar';

        return RefreshIndicator(
          onRefresh: () async => _loadCandidatoProfile(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(candidato.nombre, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(candidato.email, style: Theme.of(context).textTheme.titleMedium),
                        if (candidato.telefono != null) Text(candidato.telefono!, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700)),
                        if (candidato.ciudad != null && candidato.estado != null) Text('${candidato.ciudad}, ${candidato.estado}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700)),

                        const Divider(height: 32, thickness: 1),

                        SwitchListTile(
                          title: const Text('Visibilidad de CV'),
                          subtitle: Text('Tu CV está ${isVisible ? 'visible' : 'oculto'}'),
                          value: isVisible,
                          onChanged: (newValue) {
                            _updateAirtableField(candidato.recordId, {'Perfil_Activo': newValue ? 'Mostrar' : 'Ocultar'});
                          },
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        ListTile(
                          leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                          title: Text(candidato.cvFileName ?? 'CV no disponible'),
                          subtitle: const Text('CV Adjunto'),
                          trailing: PopupMenuButton(
                            icon: const Icon(Icons.more_horiz),
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'change', child: Text('Cambiar PDF')),
                            ],
                            onSelected: (value) {
                              if (value == 'change') {
                                _changePdf(candidato);
                              }
                            },
                          ),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text('Editar Perfil'),
                          onTap: () async {
                            final result = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(builder: (context) => EditarCvScreen(candidato: candidato)),
                            );
                            if (result == true) {
                              _loadCandidatoProfile();
                            }
                          },
                        ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: TextButton.icon(
                            icon: const Icon(Icons.delete_forever, color: Colors.red),
                            label: const Text('Eliminar Mi Perfil', style: TextStyle(color: Colors.red)),
                            onPressed: () => _deleteProfile(candidato),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}