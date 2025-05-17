import 'package:flutter/material.dart';
import 'package:bitirme_3/services/admin_service.dart';
import 'package:bitirme_3/models/roadmap.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoadmapsManagementScreen extends StatefulWidget {
  const RoadmapsManagementScreen({Key? key}) : super(key: key);

  @override
  _RoadmapsManagementScreenState createState() =>
      _RoadmapsManagementScreenState();
}

class _RoadmapsManagementScreenState extends State<RoadmapsManagementScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  List<DocumentSnapshot> _roadmaps = [];
  String _searchQuery = '';
  List<DocumentSnapshot> _filteredRoadmaps = [];

  @override
  void initState() {
    super.initState();
    _loadRoadmaps();
  }

  Future<void> _loadRoadmaps() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('roadmaps').get();
      setState(() {
        _roadmaps = snapshot.docs;
        _filteredRoadmaps = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Yol haritaları yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yol haritaları yüklenirken bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterRoadmaps(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredRoadmaps = _roadmaps;
      } else {
        _filteredRoadmaps = _roadmaps.where((roadmap) {
          final data = roadmap.data() as Map<String, dynamic>;
          return (data['title'] as String)
              .toLowerCase()
              .contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  String _getCareerPathText(String careerPathStr) {
    switch (careerPathStr) {
      case 'networkSecurity':
        return 'Ağ Güvenliği';
      case 'applicationSecurity':
        return 'Uygulama Güvenliği';
      case 'cloudSecurity':
        return 'Bulut Güvenliği';
      case 'penetrationTesting':
        return 'Sızma Testi';
      case 'securityAnalyst':
        return 'Güvenlik Analisti';
      case 'incidentResponse':
        return 'Olay Müdahale';
      case 'cryptography':
        return 'Kriptografi';
      default:
        return 'Bilinmeyen Kariyer';
    }
  }

  String _getResourceTypeText(String typeStr) {
    switch (typeStr) {
      case 'article':
        return 'Makale';
      case 'video':
        return 'Video';
      case 'course':
        return 'Kurs';
      case 'tutorial':
        return 'Öğretici';
      case 'book':
        return 'Kitap';
      case 'tool':
        return 'Araç';
      case 'certification':
        return 'Sertifika';
      default:
        return 'Bilinmeyen Tür';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yol Haritası Yönetimi'),
        backgroundColor: Colors.teal.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRoadmaps,
            tooltip: 'Yenile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Yol haritası ekleme işlevi henüz geliştirilme aşamasındadır.'),
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
                labelText: 'Yol Haritası Ara',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _filterRoadmaps('');
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
              ),
              onChanged: _filterRoadmaps,
            ),
          ),
          // Yol Haritası Listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRoadmaps.isEmpty
                    ? const Center(
                        child: Text(
                          'Yol haritası bulunamadı.',
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredRoadmaps.length,
                        itemBuilder: (context, index) {
                          final roadmap = _filteredRoadmaps[index];
                          final data = roadmap.data() as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: ExpansionTile(
                              title: Text(
                                data['title'] ?? 'İsimsiz Yol Haritası',
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
                                          color: Colors.teal.shade100,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getCareerPathText(
                                              data['careerPath'] ?? ''),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.teal.shade800,
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
                                              Icons.calendar_today,
                                              size: 14,
                                              color: Colors.grey.shade800,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${data['estimatedDurationWeeks'] ?? 0} hafta',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (data['category'] != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 8.0),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              data['category'],
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.amber.shade900,
                                              ),
                                            ),
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
                                              'Yol haritası düzenleme henüz geliştirilme aşamasındadır.'),
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
                                          title:
                                              const Text('Yol Haritasını Sil'),
                                          content: const Text(
                                              'Bu yol haritasını silmek istediğinizden emin misiniz?'),
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
                                              .deleteRoadmap(roadmap.id);

                                          if (success) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Yol haritası başarıyla silindi'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                            _loadRoadmaps();
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Yol haritası silinirken bir hata oluştu'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Yol haritası silinirken hata: $e'),
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
                                      .collection('roadmaps')
                                      .doc(roadmap.id)
                                      .collection('steps')
                                      .orderBy('order')
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
                                            'Bu yol haritasına ait adım bulunamadı.'),
                                      );
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Adımlar',
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
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    stepData['description'] ??
                                                        'Açıklama yok',
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  if ((stepData['requiredSkills']
                                                              as List<dynamic>?)
                                                          ?.isNotEmpty ??
                                                      false)
                                                    Wrap(
                                                      spacing: 4,
                                                      children: (stepData[
                                                                  'requiredSkills']
                                                              as List<dynamic>)
                                                          .map((skill) => Chip(
                                                                label: Text(
                                                                  skill
                                                                      as String,
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          10),
                                                                ),
                                                                backgroundColor:
                                                                    Colors.teal
                                                                        .shade50,
                                                                labelStyle: TextStyle(
                                                                    color: Colors
                                                                        .teal
                                                                        .shade800),
                                                                padding:
                                                                    EdgeInsets
                                                                        .zero,
                                                                materialTapTargetSize:
                                                                    MaterialTapTargetSize
                                                                        .shrinkWrap,
                                                                visualDensity:
                                                                    VisualDensity
                                                                        .compact,
                                                              ))
                                                          .toList(),
                                                    ),
                                                ],
                                              ),
                                              leading: CircleAvatar(
                                                backgroundColor:
                                                    Colors.teal.shade100,
                                                child: Text(
                                                    '${stepData['order'] ?? '?'}'),
                                              ),
                                              // Kaynakları göstermek için genişletme butonu
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // Kaynak sayısını gösterir
                                                  FutureBuilder<QuerySnapshot>(
                                                    future: FirebaseFirestore
                                                        .instance
                                                        .collection('roadmaps')
                                                        .doc(roadmap.id)
                                                        .collection('steps')
                                                        .doc(stepDoc.id)
                                                        .collection('resources')
                                                        .get(),
                                                    builder: (context,
                                                        resourceSnapshot) {
                                                      if (resourceSnapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .waiting) {
                                                        return const CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        );
                                                      }
                                                      int resourceCount =
                                                          resourceSnapshot
                                                                  .hasData
                                                              ? resourceSnapshot
                                                                  .data!
                                                                  .docs
                                                                  .length
                                                              : 0;
                                                      return Chip(
                                                        label: Text(
                                                            '$resourceCount kaynak'),
                                                        backgroundColor:
                                                            Colors.teal.shade50,
                                                        labelStyle: TextStyle(
                                                          color: Colors
                                                              .teal.shade800,
                                                          fontSize: 10,
                                                        ),
                                                        padding:
                                                            EdgeInsets.zero,
                                                        materialTapTargetSize:
                                                            MaterialTapTargetSize
                                                                .shrinkWrap,
                                                        visualDensity:
                                                            VisualDensity
                                                                .compact,
                                                      );
                                                    },
                                                  ),
                                                ],
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
