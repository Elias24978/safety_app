import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:open_filex/open_filex.dart';

class PdfViewerScreen extends StatefulWidget {
  final String fileUrl;
  // ✅ CAMBIO: Renombrado a 'fileName' para ser genérico
  final String fileName;

  const PdfViewerScreen({
    super.key,
    required this.fileUrl,
    required this.fileName, // ✅ CAMBIO
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _tempFilePath;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPdfIntoTempFile();
  }

  /// Descarga el PDF UNA SOLA VEZ a un archivo temporal para la visualización.
  Future<void> _loadPdfIntoTempFile() async {
    // Capturamos el context antes del await
    final context = this.context;

    try {
      final response = await Dio().get(
        widget.fileUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final dir = await getTemporaryDirectory();

      // Sanitiza el nombre del archivo para evitar caracteres inválidos
      // ✅ CAMBIO: Usa 'fileName'
      final sanitizedFileName = widget.fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
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
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar el PDF. Intenta de nuevo.')),
      );
    }
  }

  /// COPIA el archivo temporal a la carpeta pública de Descargas.
  Future<void> _copyFileToDownloads() async {
    // Capturamos el context antes del await
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (_tempFilePath == null) {
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('El archivo aún no está listo para guardar.')));
      return;
    }

    final hasPermission = await _checkAndRequestPermission();
    if (!hasPermission) return;

    setState(() => _isSaving = true);

    try {
      final tempFile = File(_tempFilePath!);
      final Directory? downloadsDir = await getDownloadsDirectory();

      if (downloadsDir == null) throw Exception('No se pudo acceder a la carpeta de descargas.');

      final safetyMexDir = Directory('${downloadsDir.path}/SafetyMex');
      if (!await safetyMexDir.exists()) {
        await safetyMexDir.create(recursive: true);
      }

      // ✅ CAMBIO: Usa 'fileName'
      final sanitizedFileName = widget.fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final newPath = '${safetyMexDir.path}/$sanitizedFileName.pdf';

      // Copia el archivo en lugar de volver a descargarlo
      await tempFile.copy(newPath);

      if (!mounted) return;

      // SnackBar con acción para abrir el archivo
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text('Guardado en la carpeta SafetyMex'),
          action: SnackBarAction(
            label: 'ABRIR',
            onPressed: () {
              OpenFilex.open(newPath);
            },
          ),
        ),
      );

    } catch (e) {
      debugPrint('Error al guardar el archivo: $e');
      if (mounted) {
        scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('No se pudo guardar el archivo.')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Maneja la lógica de permisos de almacenamiento para diferentes versiones de Android.
  Future<bool> _checkAndRequestPermission() async {
    // Capturamos el context antes del await
    final context = this.context;
    bool isGranted;

    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      // En Android 13+ (SDK 33+), no se necesita permiso para guardar en carpetas públicas.
      if (deviceInfo.version.sdkInt >= 33) {
        isGranted = true;
      } else {
        var status = await Permission.storage.status;
        if (status.isPermanentlyDenied) {
          if (mounted) _showSettingsDialog(context); // Pasamos el context
          return false;
        }
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        isGranted = status.isGranted;
      }
    } else {
      isGranted = true;
    }

    if (!isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de almacenamiento denegado.')),
      );
    }
    return isGranted;
  }

  // ✅ CAMBIO: Pasamos el context como parámetro
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permiso Requerido'),
        content: const Text(
            'El permiso de almacenamiento es necesario. Por favor, actívalo en los ajustes de la aplicación.'),
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
        // ✅ CAMBIO: Usa 'fileName'
        title: Text(widget.fileName),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isLoading || _isSaving ? null : _copyFileToDownloads,
            icon: const Icon(Icons.download_for_offline_outlined),
            tooltip: 'Descargar',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_tempFilePath != null)
            PDFView(filePath: _tempFilePath!)
          else
            const Center(child: Text('No se pudo cargar el PDF.')),

          if (_isSaving)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Guardando archivo...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}