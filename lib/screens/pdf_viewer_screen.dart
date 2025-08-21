import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart'; // Importamos el nuevo paquete

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
    // Carga el PDF en una ubicación temporal solo para visualización
    _loadPdfForViewing();
  }

  Future<void> _loadPdfForViewing() async {
    // Esta función no necesita permisos, ya que usa el directorio temporal de la app.
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
      print('Error cargando PDF para visualización: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar el PDF.')),
      );
    }
  }

  // ✅ INICIO DE LA LÓGICA DE PERMISOS ACTUALIZADA
  Future<void> _requestDownload() async {
    bool hasPermission = await _checkAndRequestPermission();
    if (hasPermission) {
      _startDownload();
    }
  }

  /// Verifica y solicita permisos de forma inteligente según la versión de Android.
  Future<bool> _checkAndRequestPermission() async {
    bool isGranted;

    // En Android 13 (SDK 33) y superior, no se necesita ningún permiso
    // para guardar en la carpeta de descargas.
    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      if (deviceInfo.version.sdkInt >= 33) {
        isGranted = true; // El permiso no es necesario, así que consideramos que está concedido.
      } else {
        // Para versiones de Android 12 e inferiores, sí necesitamos el permiso.
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
      // Para otras plataformas como iOS, asumimos que se puede escribir.
      isGranted = true;
    }

    if (!isGranted) {
      if (!mounted) return false;
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
            'El permiso de almacenamiento es necesario para guardar archivos. Por favor, actívalo en los ajustes de la aplicación.'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Abrir Ajustes'),
            onPressed: () {
              openAppSettings(); // Abre los ajustes de la app
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _startDownload() async {
    // `getDownloadsDirectory()` funciona sin permisos en Android moderno.
    final Directory? dir = await getDownloadsDirectory();

    if (dir == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No se pudo encontrar la carpeta de descargas.')),
      );
      return;
    }

    final savePath = '${dir.path}/${widget.normaName}.pdf';
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
        SnackBar(content: Text('Descargado en: ${dir.path}')),
      );
    } catch (e) {
      print('Error al descargar: $e');
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
  // ✅ FIN DE LA LÓGICA DE PERMISOS

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.normaName),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            onPressed: _isDownloading ? null : _requestDownload, // Llamamos a la nueva función
            icon: const Icon(Icons.download),
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