import 'package:flutter/material.dart';
import 'package:bitirme_3/services/admin_service.dart';
import 'package:bitirme_3/models/simulation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SimulationsManagementScreen extends StatefulWidget {
  const SimulationsManagementScreen({Key? key}) : super(key: key);

  @override
  _SimulationsManagementScreenState createState() =>
      _SimulationsManagementScreenState();
}

class _SimulationsManagementScreenState
    extends State<SimulationsManagementScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  List<DocumentSnapshot> _simulations = [];
  String _searchQuery = '';
  List<DocumentSnapshot> _filteredSimulations = [];

  @override
  void initState() {
    super.initState();
    _loadSimulations();
  }

  Future<void> _loadSimulations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('simulations').get();
      setState(() {
        _simulations = snapshot.docs;
        _filteredSimulations = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Simülasyonlar yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Simülasyonlar yüklenirken bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterSimulations(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredSimulations = _simulations;
      } else {
        _filteredSimulations = _simulations.where((simulation) {
          final data = simulation.data() as Map<String, dynamic>;
          return (data['title'] as String)
              .toLowerCase()
              .contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  String _getSimulationTypeText(String typeStr) {
    switch (typeStr) {
      case 'networkAnalysis':
        return 'Ağ Analizi';
      case 'penetrationTesting':
        return 'Sızma Testi';
      case 'forensicAnalysis':
        return 'Adli Analiz';
      case 'malwareAnalysis':
        return 'Zararlı Yazılım Analizi';
      case 'cryptography':
        return 'Kriptografi';
      case 'socialEngineering':
        return 'Sosyal Mühendislik';
      default:
        return 'Bilinmeyen Tür';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simülasyon Yönetimi'),
        backgroundColor: Colors.purple.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSimulations,
            tooltip: 'Yenile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Simülasyon ekleme işlevi henüz geliştirilme aşamasındadır.'),
            ),
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Arama Çubuğu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Simülasyon Ara',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _filterSimulations('');
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
              ),
              onChanged: _filterSimulations,
            ),
          ),
          // Simülasyon Listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSimulations.isEmpty
                    ? const Center(
                        child: Text(
                          'Simülasyon bulunamadı.',
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredSimulations.length,
                        itemBuilder: (context, index) {
                          final simulation = _filteredSimulations[index];
                          final data =
                              simulation.data() as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: ExpansionTile(
                              title: Text(
                                data['title'] ?? 'İsimsiz Simülasyon',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['description'] ?? 'Açıklama yok',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.shade100,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getSimulationTypeText(
                                              data['type'] ?? ''),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.purple.shade800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.star,
                                              size: 14,
                                              color: Colors.amber.shade800,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${data['difficultyLevel'] ?? 1}/5',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Detay butonu
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Simülasyon düzenleme henüz geliştirilme aşamasındadır.'),
                                        ),
                                      );
                                    },
                                    tooltip: 'Düzenle',
                                  ),
                                  // Sil butonu
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Simülasyonu Sil'),
                                          content: const Text(
                                              'Bu simülasyonu silmek istediğinizden emin misiniz?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('İptal'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red),
                                              child: const Text('Sil'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirmed == true) {
                                        try {
                                          final success = await _adminService
                                              .deleteSimulation(simulation.id);

                                          if (success) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Simülasyon başarıyla silindi'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                            _loadSimulations();
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Simülasyon silinirken bir hata oluştu'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Simülasyon silinirken hata: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    tooltip: 'Sil',
                                    color: Colors.red,
                                  ),
                                ],
                              ),
                              children: [
                                FutureBuilder<QuerySnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('simulations')
                                      .doc(simulation.id)
                                      .collection('steps')
                                      .get(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Center(
                                            child: CircularProgressIndicator()),
                                      );
                                    }

                                    if (!snapshot.hasData ||
                                        snapshot.data!.docs.isEmpty) {
                                      return const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text(
                                            'Bu simülasyona ait adım bulunamadı.'),
                                      );
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Simülasyon Adımları',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ...snapshot.data!.docs.map((stepDoc) {
                                            final stepData = stepDoc.data()
                                                as Map<String, dynamic>;
                                            return ListTile(
                                              title: Text(stepData['title'] ??
                                                  'İsimsiz Adım'),
                                              subtitle: Text(
                                                stepData['description'] ??
                                                    'Açıklama yok',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              leading: CircleAvatar(
                                                backgroundColor:
                                                    Colors.purple.shade100,
                                                child: Text(
                                                    '${stepData['order'] ?? '?'}'),
                                              ),
                                            );
                                          }).toList(),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
