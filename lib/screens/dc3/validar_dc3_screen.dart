import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class ValidarDc3Screen extends StatefulWidget {
  const ValidarDc3Screen({super.key});

  @override
  State<ValidarDc3Screen> createState() => _ValidarDc3ScreenState();
}

class _ValidarDc3ScreenState extends State<ValidarDc3Screen> {
  final TextEditingController _folioController = TextEditingController();
  bool _isLoading = false;
  bool _busquedaRealizada = false;
  Map<String, dynamic>? _datosCertificado;

  Future<void> _validarFolio() async {
    final folio = _folioController.text.trim().toUpperCase();

    if (folio.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa un número de folio.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _busquedaRealizada = false;
      _datosCertificado = null;
    });

    try {
      // 🚀 MAGIA REAL: Llamamos a nuestro servidor en Firebase
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('validarFolioDC3');

      // Le enviamos el folio escrito por el usuario
      final result = await callable.call({'folio': folio});

      final bool encontrado = result.data['encontrado'] ?? false;

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _busquedaRealizada = true;

        if (encontrado) {
          // Si Firebase lo encontró en Airtable, guardamos los datos
          _datosCertificado = Map<String, dynamic>.from(result.data['datos']);
        }
      });

    } on FirebaseFunctionsException catch (e) {
      setState(() => _isLoading = false);
      _mostrarErrorDialog(e.message ?? 'Error en el servidor de SafetyMex.');
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarErrorDialog('Verifica tu conexión a internet e intenta de nuevo.');
    }
  }

  void _mostrarErrorDialog(String mensaje) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Error de Conexión", style: TextStyle(color: Colors.red)),
        content: Text(mensaje),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Entendido"))
        ],
      ),
    );
  }

  @override
  void dispose() {
    _folioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validar Certificado'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.security, size: 60, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              "Verificación de Autenticidad",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Ingresa el folio del certificado DC-3 emitido por SafetyMex para verificar su validez oficial.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: _folioController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Número de Folio (Ej. PAA-5635)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.qr_code_scanner),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _folioController.clear();
                    setState(() {
                      _busquedaRealizada = false;
                      _datosCertificado = null;
                    });
                  },
                ),
              ),
              onSubmitted: (_) => _validarFolio(),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _validarFolio,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('VALIDAR AHORA', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),

            // --- RESULTADOS DE LA BÚSQUEDA ---
            if (_busquedaRealizada)
              Expanded(
                child: _datosCertificado != null
                    ? _buildTarjetaValida()
                    : _buildTarjetaInvalida(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTarjetaValida() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300, width: 2),
      ),
      child: ListView(
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 30),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "CERTIFICADO VÁLIDO",
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          const Divider(height: 30, color: Colors.green),
          _infoRow("Folio Oficial:", _datosCertificado!["folio"]?.toString() ?? "N/A"),
          const SizedBox(height: 10),
          _infoRow("Trabajador:", _datosCertificado!["nombreTrabajador"]?.toString() ?? "N/A"),
          const SizedBox(height: 10),
          _infoRow("CURP:", _datosCertificado!["curp"]?.toString() ?? "N/A"),
          const SizedBox(height: 10),
          _infoRow("Curso Aprobado:", _datosCertificado!["nombreCurso"]?.toString() ?? "N/A"),
          const SizedBox(height: 10),
          _infoRow("Duración:", _datosCertificado!["duracion"]?.toString() ?? "N/A"),
          const SizedBox(height: 10),
          _infoRow("Instructor:", _datosCertificado!["instructor"]?.toString() ?? "N/A"),
          const SizedBox(height: 10),
          _infoRow("Fecha Emisión:", _datosCertificado!["fechaEmision"]?.toString() ?? "N/A"),
          const SizedBox(height: 10),
          _infoRow("Calificación:", _datosCertificado!["calificacion"]?.toString() ?? "N/A"),
        ],
      ),
    );
  }

  Widget _buildTarjetaInvalida() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300, width: 2),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 50),
          SizedBox(height: 16),
          Text(
            "CERTIFICADO NO ENCONTRADO",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            "El folio ingresado no existe en la base de datos oficial de SafetyMex. Es posible que el certificado sea falso o el folio sea incorrecto.",
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String etiqueta, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        Text(valor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }
}