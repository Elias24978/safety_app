import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:safety_app/models/curso_model.dart';
import 'package:safety_app/services/purchase_service.dart';

class BotonCompraCurso extends StatefulWidget {
  final Curso curso;
  final VoidCallback onCompraExitosa;

  const BotonCompraCurso({
    super.key,
    required this.curso,
    required this.onCompraExitosa,
  });

  @override
  State<BotonCompraCurso> createState() => _BotonCompraCursoState();
}

class _BotonCompraCursoState extends State<BotonCompraCurso> {
  bool _isLoading = true;
  Package? _ofertaDisponible;

  @override
  void initState() {
    super.initState();
    _buscarPrecioEnTienda();
  }

  Future<void> _buscarPrecioEnTienda() async {
    // Busca la oferta exacta. Si no existe en RevenueCat, retornará null.
    final package = await PurchaseService().getOfferingForCourse(widget.curso.id);
    if (mounted) {
      setState(() {
        _ofertaDisponible = package;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 50,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    // 🔒 ESTADO BLOQUEADO: Si no hay oferta en RevenueCat
    if (_ofertaDisponible == null) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: null, // Deshabilita el botón
          icon: const Icon(Icons.block, color: Colors.grey),
          label: const Text("No disponible para compra"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[300],
            disabledBackgroundColor: Colors.grey[300],
            disabledForegroundColor: Colors.grey[600],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    }

    // 🛒 ESTADO DISPONIBLE
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D47A1), // Azul SafetyApp
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 4,
        ),
        onPressed: () async {
          setState(() => _isLoading = true);
          bool exito = await PurchaseService().purchasePackage(_ofertaDisponible!);
          if (exito) {
            widget.onCompraExitosa();
          } else {
            // Si falló o canceló, quitamos el loading
            if (mounted) setState(() => _isLoading = false);
          }
        },
        child: Text(
          "Comprar por ${_ofertaDisponible!.storeProduct.priceString}",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}