import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
import 'package:safety_app/screens/document_viewer_screen.dart';

class ReviewDc3Screen extends StatefulWidget {
  const ReviewDc3Screen({super.key});

  @override
  State<ReviewDc3Screen> createState() => _ReviewDc3ScreenState();
}

class _ReviewDc3ScreenState extends State<ReviewDc3Screen> {
  List<Map<String, dynamic>> _allRecords = [];
  List<Map<String, dynamic>> _filteredRecords = [];
  bool _isLoading = true;
  String? _error;

  // Novedad: Controladores de estado para acciones en un elemento específico
  String? _sharingItemId;
  String? _deletingItemId;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDc3Records();
    _searchController.addListener(_filterRecords);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDc3Records() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('getDc3RecordsByUser');

      final response = await callable.call({'type': 'all'});

      final List<dynamic> recordsDynamic = response.data['records'] ?? [];
      final recordList = recordsDynamic
          .map((record) => Map<String, dynamic>.from(record as Map))
          .toList();

      if (!mounted) return;
      setState(() {
        _allRecords = recordList;
        _filteredRecords = recordList;
        _isLoading = false;
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error: [${e.code}] ${e.message}';
        _isLoading = false;
      });
      debugPrint("Firebase Functions Error: ${e.code} - ${e.message}");
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error inesperado: ${e.toString()}';
        _isLoading = false;
      });
      debugPrint("Error fetching DC3 records: $e");
    }
  }

  void _filterRecords() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredRecords = _allRecords.where((record) {
        final workerName = (record['workerName'] as String? ?? '').toLowerCase();
        final courseName = (record['courseName'] as String? ?? '').toLowerCase();
        return workerName.contains(query) || courseName.contains(query);
      }).toList();
    });
  }

  Future<void> _sharePdf(Map<String, dynamic> record) async {
    final fileUrl = record['fileUrl'] as String?;
    final docTitle = record['courseName'] as String? ?? 'documento';
    final recordId = record['id'] as String;

    if (fileUrl == null || fileUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Este registro no tiene archivo para compartir.')),
        );
      }
      return;
    }

    final box = context.findRenderObject() as RenderBox?;
    setState(() => _sharingItemId = recordId);

    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/${docTitle.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')}.pdf';
      await Dio().download(fileUrl, tempPath);

      if (!mounted) return;
      final xfile = XFile(tempPath);

      await Share.shareXFiles(
        [xfile],
        text: 'Constancia DC-3: $docTitle',
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      );

    } catch (e) {
      debugPrint('Error al compartir el PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al preparar el archivo para compartir.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharingItemId = null);
    }
  }

  void _viewPdf(Map<String, dynamic> record) {
    final fileUrl = record['fileUrl'] as String?;
    final courseName = record['courseName'] as String? ?? 'Curso sin nombre';

    if (fileUrl != null && fileUrl.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentViewerScreen(
            fileUrl: fileUrl,
            documentTitle: courseName,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este registro no tiene un archivo adjunto.')),
      );
    }
  }

  // ✅ NUEVA FUNCIÓN: Muestra un diálogo de confirmación y elimina el registro.
  Future<void> _confirmAndDeleteRecord(Map<String, dynamic> record) async {
    final recordId = record['id'] as String;
    final courseName = record['courseName'] as String? ?? 'esta constancia';

    // Muestra un diálogo de alerta para confirmar la acción
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Borrado'),
          content: Text('¿Estás seguro de que quieres eliminar permanentemente "$courseName"? Esta acción no se puede deshacer.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cierra el diálogo y devuelve 'false'
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Cierra el diálogo y devuelve 'true'
              child: Text('Borrar', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    // Si el usuario no confirma (presiona 'Cancelar' o fuera del diálogo), no hacer nada
    if (shouldDelete != true) return;

    // El usuario confirmó. Mostrar indicador de carga y llamar a la función de Firebase.
    setState(() => _deletingItemId = recordId);

    try {
      // Se asume que tienes una Cloud Function llamada 'deleteDc3Record' que recibe 'recordId'
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('deleteDc3Record');

      await callable.call({'recordId': recordId});

      if (!mounted) return;

      // Elimina el registro de la lista local para actualizar la UI instantáneamente
      setState(() {
        _allRecords.removeWhere((r) => r['id'] == recordId);
        _filteredRecords.removeWhere((r) => r['id'] == recordId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Constancia eliminada correctamente.'),
          backgroundColor: Colors.green,
        ),
      );

    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint("Firebase Functions Error on delete: ${e.code} - ${e.message}");
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error inesperado al eliminar.'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint("Error deleting DC3 record: $e");
    } finally {
      if (mounted) setState(() => _deletingItemId = null);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Constancias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDc3Records,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar por nombre o curso',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_error!)));
    }
    if (_filteredRecords.isEmpty) {
      return const Center(child: Text('No se encontraron constancias subidas.'));
    }

    return RefreshIndicator(
      onRefresh: _fetchDc3Records,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80, top: 8),
        itemCount: _filteredRecords.length,
        itemBuilder: (context, index) {
          final record = _filteredRecords[index];
          final courseName = record['courseName'] as String? ?? 'Curso sin nombre';
          final workerName = record['workerName'] as String? ?? 'Trabajador';
          final executionDate = record['executionDate'] as String? ?? 'Fecha no disponible';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              leading: Icon(
                Icons.cloud_upload_outlined,
                color: Theme.of(context).primaryColor,
                size: 36,
              ),
              title: Text(courseName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(workerName),
                  const SizedBox(height: 2),
                  Text(
                    executionDate,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              // ✅ MODIFICADO: Muestra un indicador si se está compartiendo O borrando
              trailing: (_sharingItemId == record['id'] || _deletingItemId == record['id'])
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
                  : PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'view') {
                    _viewPdf(record);
                  } else if (value == 'share') {
                    _sharePdf(record);
                  }
                  // ✅ MODIFICADO: Maneja la nueva opción 'delete'
                  else if (value == 'delete') {
                    _confirmAndDeleteRecord(record);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(children: [
                      Icon(Icons.visibility_outlined, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Ver'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(children: [
                      Icon(Icons.share_outlined, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Compartir'),
                    ]),
                  ),
                  const PopupMenuDivider(), // Separador visual
                  // ✅ MODIFICADO: Añade el nuevo item para borrar
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Borrar', style: TextStyle(color: Colors.red)),
                    ]),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}