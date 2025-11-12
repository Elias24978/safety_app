import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safety_app/models/aplicacion_model.dart';
import 'package:safety_app/services/bolsa_trabajo_service.dart';
// ✅ CAMBIO: Se eliminó url_launcher
// import 'package:url_launcher/url_launcher.dart';

// ✅ CAMBIO: Se importó el visor de PDF reutilizable
import 'package:safety_app/screens/pdf_viewer_screen.dart';

class DetalleAplicacionScreen extends StatefulWidget {
  final Aplicacion aplicacion;

  const DetalleAplicacionScreen({super.key, required this.aplicacion});

  @override
  State<DetalleAplicacionScreen> createState() =>
      _DetalleAplicacionScreenState();
}

class _DetalleAplicacionScreenState extends State<DetalleAplicacionScreen> {
  late BolsaTrabajoService _bolsaTrabajoService;
  late String _estadoActual;
  bool _isLoading = false;
  bool _seRealizoCambio = false;

  final List<String> _opcionesEstado = ['✓ CV Visto', '– En proceso'];

  @override
  void initState() {
    super.initState();
    _bolsaTrabajoService =
        Provider.of<BolsaTrabajoService>(context, listen: false);
    _estadoActual = widget.aplicacion.estadoAplicacion;

    if (_estadoActual == '✓ CV Recibido') {
      _estadoActual = '✓ CV Visto';
      Future.microtask(() => _cambiarEstado(_estadoActual, auto: true));
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _cambiarEstado(String nuevoEstado, {bool auto = false}) async {
    if (!auto) {
      if (nuevoEstado == _estadoActual) return;
      setState(() => _isLoading = true);
    }

    final navigator = Navigator.of(context);

    try {
      final success = await _bolsaTrabajoService.updateAplicacionStatus(
        widget.aplicacion.recordId,
        nuevoEstado,
      );

      if (!mounted) return;

      if (success) {
        setState(() {
          _estadoActual = nuevoEstado;
          _seRealizoCambio = true;
        });

        if (!auto) {
          _showSnackBar('Estado actualizado');
        }

        if (nuevoEstado == '✗ Proceso finalizado') {
          navigator.pop(_seRealizoCambio);
        }
      } else {
        throw Exception('Error al guardar en Airtable');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted && !auto) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ CAMBIO: Función _verCV actualizada para usar PdfViewerScreen
  Future<void> _verCV() async {
    final cvUrl = widget.aplicacion.cvUrlCandidato;
    if (cvUrl == null || cvUrl.isEmpty) {
      if (mounted) _showSnackBar('El candidato no ha subido un CV.', isError: true);
      return;
    }

    // Capturamos el Navigator ANTES del await para evitar errores de "async gap"
    final navigator = Navigator.of(context);

    try {
      // Navegamos a la pantalla del visor de PDF
      await navigator.push(
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(
            fileUrl: cvUrl,
            // Usamos el nombre del candidato para el título de la AppBar
            fileName: 'CV de ${widget.aplicacion.nombreCandidato}',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al abrir el visor de PDF: $e', isError: true);
      }
    }
  }


  Future<void> _onFinalizarProceso() async {
    final context = this.context;

    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Finalizar Proceso'),
          content: const Text(
            '¿Estás seguro de que quieres finalizar el proceso con este candidato? La aplicación se marcará como "Proceso finalizado".',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Sí, Finalizar'),
            ),
          ],
        );
      },
    );

    if (confirmado == true) {
      await _cambiarEstado('✗ Proceso finalizado');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String domicilio = [
      widget.aplicacion.ciudadCandidato,
      widget.aplicacion.estadoCandidato
    ].where((s) => s != null && s.isNotEmpty).join(', ');

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.pop(context, _seRealizoCambio);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.aplicacion.nombreCandidato),
          backgroundColor: Colors.deepPurple[800],
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _seRealizoCambio),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildVacanteInfo(),
              const SizedBox(height: 24),
              _buildEstadoSection(),
              const SizedBox(height: 24),
              _buildInfoCandidato(domicilio),
              const SizedBox(height: 24),
              _buildResumenSection(),
              const SizedBox(height: 32),
              _buildAcciones(),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets Auxiliares (sin cambios) ---

  Widget _buildVacanteInfo() {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(Icons.work_outline, color: Colors.deepPurple[800]),
        title: Text(
          widget.aplicacion.tituloVacante,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(widget.aplicacion.nombreEmpresa),
      ),
    );
  }

  Widget _buildEstadoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado de la Aplicación',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _estadoActual,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: _opcionesEstado.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              _cambiarEstado(newValue);
            }
          },
        ),
      ],
    );
  }

  Widget _buildInfoCandidato(String domicilio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información de Contacto',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
            Icons.person_outline, widget.aplicacion.nombreCandidato),
        _buildInfoRow(Icons.phone_outlined,
            widget.aplicacion.telefonoCandidato ?? 'No disponible'),
        _buildInfoRow(Icons.email_outlined,
            widget.aplicacion.emailCandidato ?? 'No disponible'),
        _buildInfoRow(Icons.location_city_outlined,
            domicilio.isEmpty ? 'Domicilio no disponible' : domicilio),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen Profesional',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.aplicacion.resumenProfesional ?? 'No proporcionado',
          style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildAcciones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _verCV,
          icon: const Icon(Icons.picture_as_pdf_outlined), // ✅ CAMBIO: Ícono actualizado
          label: const Text('Ver CV Completo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _onFinalizarProceso,
          icon: const Icon(Icons.highlight_off),
          label: const Text('Finalizar Proceso'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red[700],
            side: BorderSide(color: Colors.red[700]!),
            padding: const EdgeInsets.symmetric(vertical: 12),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}