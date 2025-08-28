// lib/screens/pdf_viewer_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PdfViewerScreen extends StatefulWidget {
  final String fileUrl;
  final String normaName;

  const PdfViewerScreen(
      {super.key, required this.fileUrl, required this.normaName});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _localPath;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPdfForViewing();
  }

  Future<void> _loadPdfForViewing() async {
    try {
      final response = await Dio().get(
        widget.fileUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.normaName}.pdf');
      await file.writeAsBytes(response.data, flush: true);
      if (mounted) {
        setState(() {
          _localPath = file.path;
        });
      }
    } catch (e) {
      debugPrint('Error cargando PDF para visualización: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar el PDF.')),
      );
    }
  }

  Future<void> _requestDownload() async {
    bool hasPermission = await _checkAndRequestPermission();
    if (hasPermission) {
      _startDownload();
    }
  }

  Future<bool> _checkAndRequestPermission() async {
    bool isGranted;
    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      if (deviceInfo.version.sdkInt >= 33) {
        isGranted = true;
      } else {
        var status = await Permission.storage.status;
        if (status.isPermanentlyDenied) {
          _showSettingsDialog();
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

  void _showSettingsDialog() {
    if (!mounted) return;
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

  Future<void> _startDownload() async {
    final Directory? downloadsDir = await getDownloadsDirectory();

    if (downloadsDir == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No se pudo encontrar la carpeta de descargas.')),
      );
      return;
    }

    // --- 👇 CAMBIO PARA CREAR CARPETA "SafetyMex" ---
    final safetyMexDir = Directory('${downloadsDir.path}/SafetyMex');
    if (!await safetyMexDir.exists()) {
      await safetyMexDir.create(recursive: true);
    }
    final savePath = '${safetyMexDir.path}/${widget.normaName}.pdf';
    // --- FIN DEL CAMBIO ---

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      await Dio().download(
        widget.fileUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Descargado en: ${safetyMexDir.path}')),
      );
    } catch (e) {
      debugPrint('Error al descargar: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al descargar el archivo.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.normaName),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isDownloading ? null : _requestDownload,
            icon: const Icon(Icons.download_for_offline_outlined),
            tooltip: 'Descargar',
          ),
        ],
      ),
      body: Stack(
        children: [
          _localPath != null
              ? PDFView(filePath: _localPath!)
              : const Center(child: CircularProgressIndicator()),
          if (_isDownloading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 20),
                    Text(
                      'Descargando... ${(_downloadProgress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
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