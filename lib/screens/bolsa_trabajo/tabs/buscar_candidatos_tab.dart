import 'package:flutter/material.dart';
import 'package:safety_app/models/candidato_model.dart';
import 'package:safety_app/services/bolsa_trabajo_service.dart';
import 'package:safety_app/screens/bolsa_trabajo/detalle_candidato_reclutador_screen.dart';

class BuscarCandidatosTab extends StatefulWidget {
  const BuscarCandidatosTab({super.key});

  @override
  State<BuscarCandidatosTab> createState() => _BuscarCandidatosTabState();
}

class _BuscarCandidatosTabState extends State<BuscarCandidatosTab> {
  final BolsaTrabajoService _bolsaTrabajoService = BolsaTrabajoService();
  final TextEditingController _searchController = TextEditingController();

  List<Candidato> _allCandidatos = [];
  List<Candidato> _filteredCandidatos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCandidatos();
    _searchController.addListener(_filterCandidatos);
  }

  Future<void> _loadCandidatos() async {
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      final candidatos = await _bolsaTrabajoService.getVisibleCandidatos();
      if (mounted) {
        setState(() {
          _allCandidatos = candidatos;
          _filteredCandidatos = candidatos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar candidatos: $e')),
        );
      }
    }
  }

  void _filterCandidatos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCandidatos = _allCandidatos.where((candidato) {
        // ✅ CAMBIO: Se usa la propiedad 'nombre' que ahora lee 'Nombre_Completo'
        final nombre = candidato.nombre.toLowerCase();
        final estado = candidato.estado?.toLowerCase() ?? '';
        return nombre.contains(query) || estado.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar por nombre o estado',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: _loadCandidatos,
              child: _filteredCandidatos.isEmpty
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _searchController.text.isEmpty
                        ? 'No hay perfiles de candidatos visibles en este momento.'
                        : 'No se encontraron candidatos con tu búsqueda.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemCount: _filteredCandidatos.length,
                itemBuilder: (context, index) {
                  final candidato = _filteredCandidatos[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const Icon(Icons.person_outline, size: 40, color: Colors.deepPurple),
                      title: Text(
                        candidato.nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${candidato.nivelDeEstudios ?? "Nivel de estudios no especificado"}\n${candidato.estado ?? "Ubicación no especificada"}',
                      ),
                      isThreeLine: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetalleCandidatoReclutadorScreen(candidato: candidato),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}