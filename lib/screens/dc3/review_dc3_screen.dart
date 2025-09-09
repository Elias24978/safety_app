// lib/screens/review_dc3_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';
import 'package:safety_app/screens/pdf_viewer_screen.dart'; // Asegúrate de que esta importación sea correcta

class ReviewDc3Screen extends StatefulWidget {
  const ReviewDc3Screen({super.key});

  @override
  State<ReviewDc3Screen> createState() => _ReviewDc3ScreenState();
}

class _ReviewDc3ScreenState extends State<ReviewDc3Screen> {
  late Future<List<Map<String, dynamic>>> _dc3RecordsFuture;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allRecords = [];
  List<Map<String, dynamic>> _filteredRecords = [];

  @override
  void initState() {
    super.initState();
    _dc3RecordsFuture = _fetchDc3Records();
    _searchController.addListener(_filterRecords);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchDc3Records() async {
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('getDc3RecordsByUser');
    try {
      final response = await callable.call();
      final List<dynamic> recordsDynamic = response.data['records'];
      final recordList = recordsDynamic
          .map((record) => Map<String, dynamic>.from(record as Map))
          .toList();
      if (!mounted) return [];
      setState(() {
        _allRecords = recordList;
        _filteredRecords = _allRecords;
      });
      return _filteredRecords;
    } catch (e) {
      debugPrint("Error fetching DC3 records: ${e.toString()}");
      throw Exception('Error al cargar las constancias');
    }
  }

  void _filterRecords() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredRecords = _allRecords.where((record) {
        final workerName = (record['workerName'] ?? '').toLowerCase();
        final courseName = (record['courseName'] ?? '').toLowerCase();
        return workerName.contains(query) || courseName.contains(query);
      }).toList();
    });
  }

  // Esta función ya no la necesitamos aquí, la hemos movido a PdfViewerScreen
  // void _downloadOrSharePdf(String? url) async { ... }

  void _scanQrCode() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de escáner QR no implementada.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Constancias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _searchController.clear();
                _dc3RecordsFuture = _fetchDc3Records();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ AQUÍ ESTÁ EL WIDGET PADDING CON SU PARÁMETRO OBLIGATORIO
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar por nombre o curso',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _dc3RecordsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (_filteredRecords.isEmpty) {
                  return const Center(child: Text('No se encontraron constancias.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: _filteredRecords.length,
                  itemBuilder: (context, index) {
                    final record = _filteredRecords[index];
                    final date = DateTime.tryParse(record['executionDate'] ?? '');
                    final formattedDate = date != null ? DateFormat('dd/MM/yyyy').format(date) : 'N/A';
                    final courseName = record['courseName'] ?? 'Curso sin nombre';
                    final workerName = record['workerName'] ?? 'Trabajador';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: Icon(
                          record['type'] == 'generated' ? Icons.qr_code : Icons.cloud_upload_outlined,
                          color: Theme.of(context).primaryColor,
                        ),
                        title: Text(courseName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('$workerName\nFecha: $formattedDate'),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          final fileUrl = record['fileUrl'];
                          if (fileUrl != null && fileUrl.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PdfViewerScreen(
                                  fileUrl: fileUrl,
                                  normaName: courseName,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Este registro no tiene un archivo adjunto.'))
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // ✅ AQUÍ ESTÁ EL FLOATINGACTIONBUTTON CON SU PARÁMETRO OBLIGATORIO
      floatingActionButton: FloatingActionButton(
        onPressed: _scanQrCode,
        tooltip: 'Escanear QR',
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}