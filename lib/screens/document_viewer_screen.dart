import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:open_filex/open_filex.dart';

/// Una pantalla reutilizable para visualizar un PDF desde una URL.
/// Incluye funcionalidad para descargar el archivo al dispositivo del usuario.
class DocumentViewerScreen extends StatefulWidget {
  final String fileUrl;
  final String documentTitle;

  const DocumentViewerScreen({
    super.key,
    required this.fileUrl,
    required this.documentTitle,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  String? _tempFilePath;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPdfIntoTempFile();
  }

  /// Descarga el PDF a un archivo temporal para la visualización inicial.
  Future<void> _loadPdfIntoTempFile() async {
    try {
      final response = await Dio().get(
        widget.fileUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final dir = await getTemporaryDirectory();
      final sanitizedFileName = widget.documentTitle.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final file = File('${dir.path}/$sanitizedFileName.pdf');
      await file.writeAsBytes(response.data, flush: true);

      if (mounted) {
        setState(() {
          _tempFilePath = file.path;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando PDF para visualización: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar el PDF.')),
      );
    }
  }

  /// Guarda una copia del archivo en la carpeta pública de Descargas.
  Future<void> _saveFileToPublicDownloads() async {
    if (_tempFilePath == null) return;

    final hasPermission = await _checkAndRequestPermission();
    if (!hasPermission) return;

    setState(() => _isSaving = true);

    try {
      final tempFile = File(_tempFilePath!);
      final Directory? downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) throw Exception('No se pudo acceder a la carpeta de descargas.');

      final customDir = Directory('${downloadsDir.path}/SafetyApp');
      if (!await customDir.exists()) {
        await customDir.create(recursive: true);
      }

      final sanitizedFileName = widget.documentTitle.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final newPath = '${customDir.path}/$sanitizedFileName.pdf';
      await tempFile.copy(newPath);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Guardado en la carpeta ${customDir.path.split('/').last}'),
          action: SnackBarAction(
            label: 'ABRIR',
            onPressed: () => OpenFilex.open(newPath),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error al guardar el archivo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo guardar el archivo.')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Maneja la lógica de permisos de almacenamiento.
  Future<bool> _checkAndRequestPermission() async {
    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      if (deviceInfo.version.sdkInt >= 33) return true; // No se necesita permiso en Android 13+
    }

    var status = await Permission.storage.request();

    if (status.isPermanentlyDenied) {
      if(mounted) _showSettingsDialog();
      return false;
    }

    return status.isGranted;
  }

  /// Muestra un diálogo para ir a los ajustes de la app si el permiso fue denegado permanentemente.
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permiso Requerido'),
        content: const Text('El permiso de almacenamiento es necesario para guardar archivos. Por favor, actívalo en los ajustes de la aplicación.'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Abrir Ajustes'),
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.documentTitle),
        actions: [
          IconButton(
            onPressed: _isLoading || _isSaving ? null : _saveFileToPublicDownloads,
            icon: const Icon(Icons.download_for_offline_outlined),
            tooltip: 'Descargar',
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          if (_isLoading)
            const CircularProgressIndicator()
          else if (_tempFilePath != null)
            PDFView(filePath: _tempFilePath!)
          else
            const Text('No se pudo cargar el PDF.'),

          if (_isSaving)
            Container(
              // ✅ CORRECCIÓN: Se usa 'withAlpha' en lugar de 'withOpacity'.
              color: Colors.black.withAlpha(153), // 153 es ~60% de 255
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Guardando archivo...', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
}