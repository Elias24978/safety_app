import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safety_app/models/candidato_model.dart';
import 'package:safety_app/services/bolsa_trabajo_service.dart'; // ✅ CAMBIO: Importamos el nuevo servicio
import '../../models/vacante_model.dart';

class DetalleVacanteScreen extends StatefulWidget {
  final Vacante vacante;
  final bool haAplicado;

  const DetalleVacanteScreen({
    super.key,
    required this.vacante,
    required this.haAplicado,
  });

  @override
  State<DetalleVacanteScreen> createState() => _DetalleVacanteScreenState();
}

class _DetalleVacanteScreenState extends State<DetalleVacanteScreen> {
  // ✅ CAMBIO: Usamos la nueva clase de servicio
  final BolsaTrabajoService _bolsaTrabajoService = BolsaTrabajoService();

  bool _isApplying = false;
  late bool _applicationSuccessful;
  bool _isLoadingStatus = true;

  @override
  void initState() {
    super.initState();
    _applicationSuccessful = widget.haAplicado;
    _verifyApplicationStatus();
  }

  Future<void> _verifyApplicationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingStatus = false);
      return;
    }

    // ✅ CAMBIO: Llamamos al método desde la nueva variable de servicio
    final serverStatus = await _bolsaTrabajoService.checkIfAlreadyApplied(user.uid, widget.vacante.id);

    if (mounted) {
      setState(() {
        _applicationSuccessful = serverStatus;
        _isLoadingStatus = false;
      });
    }
  }

  Future<void> _postularse() async {
    setState(() {
      _isApplying = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Usuario no encontrado.");

      // ✅ CAMBIO: Llamamos al método desde la nueva variable de servicio
      final bool yaAplico = await _bolsaTrabajoService.checkIfAlreadyApplied(user.uid, widget.vacante.id);
      if (yaAplico) {
        throw Exception("Ya te has postulado a esta vacante.");
      }

      // ✅ CAMBIO: Llamamos al método desde la nueva variable de servicio
      final Candidato? candidato = await _bolsaTrabajoService.getCandidatoProfile(user.uid);
      if (candidato == null) throw Exception("Perfil de candidato no encontrado.");

      if (!mounted) return;

      // ✅ CAMBIO: Llamamos al método desde la nueva variable de servicio
      final bool success = await _bolsaTrabajoService.createAplicacion(
        candidatoRecordId: candidato.recordId,
        vacanteRecordId: widget.vacante.id,
      );

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Postulación exitosa!'), backgroundColor: Colors.green),
        );
        setState(() => _applicationSuccessful = true);
      } else {
        throw Exception("La postulación falló. Intenta de nuevo.");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalles de la Vacante')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.vacante.titulo,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.vacante.nombreEmpresa,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            InfoRow(icon: Icons.location_on, text: widget.vacante.ubicacion),
            const SizedBox(height: 8),
            InfoRow(icon: Icons.monetization_on, text: widget.vacante.sueldoFormateado, color: Colors.green.shade800),
            if (widget.vacante.aceptaForaneos) ...[
              const SizedBox(height: 8),
              InfoRow(icon: Icons.public, text: 'Acepta candidatos foráneos', color: Colors.blue.shade800),
            ],
            const Divider(height: 32, thickness: 1),
            const Text(
              'Descripción del Puesto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.vacante.descripcion,
              style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildActionButton(),
      ),
    );
  }

  Widget _buildActionButton() {
    if (_isLoadingStatus) {
      return const ElevatedButton(
        onPressed: null,
        style: ButtonStyle(padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 16))),
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(color: Colors.grey, strokeWidth: 3),
        ),
      );
    }

    if (_applicationSuccessful) {
      return ElevatedButton(
        onPressed: null,
        style: const ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(Colors.teal),
          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 16)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 8),
            Text('Postulación Enviada', style: TextStyle(fontSize: 18, color: Colors.white)),
          ],
        ),
      );
    }

    if (_isApplying) {
      return const ElevatedButton(
        onPressed: null,
        style: ButtonStyle(padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 16))),
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return ElevatedButton(
      onPressed: _postularse,
      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
      child: const Text('Postularme', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const InfoRow({
    super.key,
    required this.icon,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey.shade700),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 16, color: color)),
        ),
      ],
    );
  }
}