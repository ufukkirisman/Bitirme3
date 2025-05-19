import 'package:flutter/material.dart';
import 'package:bitirme_3/services/admin_service.dart';
import 'package:bitirme_3/models/roadmap.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bitirme_3/screens/admin/roadmap_steps_screen.dart';

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
        onPressed: _showAddRoadmapDialog,
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
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
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
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
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
                                      // Adım sayısını gösteren etiket
                                      FutureBuilder<QuerySnapshot>(
                                        future: FirebaseFirestore.instance
                                            .collection('roadmaps')
                                            .doc(roadmap.id)
                                            .collection('steps')
                                            .get(),
                                        builder: (context, snapshot) {
                                          int stepCount = 0;
                                          if (snapshot.hasData) {
                                            stepCount =
                                                snapshot.data!.docs.length;
                                          }
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.teal.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.route_outlined,
                                                  size: 14,
                                                  color: Colors.teal.shade800,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '$stepCount adım',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.teal.shade800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      if (data['category'] != null)
                                        Container(
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
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Adımları yönet butonu
                                  IconButton(
                                    icon: const Icon(Icons.route,
                                        color: Colors.teal),
                                    onPressed: () {
                                      // Adımları yönetme ekranına git
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              RoadmapStepsScreen(
                                            roadmapId: roadmap.id,
                                            roadmapTitle: data['title'] ??
                                                'İsimsiz Yol Haritası',
                                          ),
                                        ),
                                      ).then((_) {
                                        // Adımlar ekranından dönüldüğünde sayfayı yenileyelim
                                        setState(() {});
                                      });
                                    },
                                    tooltip: 'Adımları Yönet',
                                  ),
                                  // Düzenle butonu
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
                              onExpansionChanged: (expanded) {
                                // Eğer genişletilirse, yenileme yapmak için setState'i tetikle
                                if (expanded) {
                                  setState(() {});
                                }
                              },
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
                                      // Eğer adım bulunamazsa, admin panel üzerinden adım ekleme sayfasına gitme seçeneği sunalım
                                      return Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          children: [
                                            const Text(
                                              'Bu yol haritasına ait adım bulunamadı.',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                            const SizedBox(height: 8),
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        RoadmapStepsScreen(
                                                      roadmapId: roadmap.id,
                                                      roadmapTitle: data[
                                                              'title'] ??
                                                          'İsimsiz Yol Haritası',
                                                    ),
                                                  ),
                                                ).then((_) {
                                                  // Geri döndüğünde sayfayı yenileyelim
                                                  setState(() {});
                                                });
                                              },
                                              icon: const Icon(Icons.add),
                                              label: const Text('Adım Ekle'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.teal.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
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

  void _showAddRoadmapDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final imageUrlController = TextEditingController();
    final categoryController = TextEditingController();
    final durationWeeksController = TextEditingController(text: '12');
    CareerPath selectedCareerPath = CareerPath.networkSecurity;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Yeni Yol Haritası Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Başlık',
                    hintText: 'Yol haritası başlığını girin',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    hintText: 'Yol haritası açıklamasını girin',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Görsel URL',
                    hintText: 'Yol haritası görsel URL\'sini girin',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    hintText: 'Yol haritası kategorisi',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: durationWeeksController,
                  decoration: const InputDecoration(
                    labelText: 'Tahmini Süre (hafta)',
                    hintText: 'Tamamlanma süresi',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<CareerPath>(
                  value: selectedCareerPath,
                  decoration: const InputDecoration(
                    labelText: 'Kariyer Yolu',
                    border: OutlineInputBorder(),
                  ),
                  items: CareerPath.values.map((path) {
                    return DropdownMenuItem<CareerPath>(
                      value: path,
                      child:
                          Text(_getCareerPathText(_getCareerPathString(path))),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedCareerPath = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Not: Yol haritası oluşturduktan sonra "Adımları Yönet" butonuna tıklayarak adımlar ekleyebilirsiniz.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Başlık boş olamaz'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  // Yeni boş bir Roadmap oluştur
                  final newRoadmap = Roadmap(
                    id: '', // ID Firebase tarafından otomatik oluşturulacak
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    imageUrl: imageUrlController.text.trim(),
                    category: categoryController.text.trim(),
                    estimatedDurationWeeks:
                        int.tryParse(durationWeeksController.text) ?? 12,
                    careerPath: selectedCareerPath,
                    steps: [], // Adımlar henüz eklenmediği için boş liste
                  );

                  // Roadmap'i Firestore'a ekle
                  await FirebaseFirestore.instance.collection('roadmaps').add({
                    ...newRoadmap.toMap(),
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Yol haritası başarıyla eklendi. Şimdi adımlar ekleyebilirsiniz.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadRoadmaps(); // Listeyi yenile
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Yol haritası eklenirken hata oluştu: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  String _getCareerPathString(CareerPath path) {
    switch (path) {
      case CareerPath.networkSecurity:
        return 'networkSecurity';
      case CareerPath.applicationSecurity:
        return 'applicationSecurity';
      case CareerPath.cloudSecurity:
        return 'cloudSecurity';
      case CareerPath.penetrationTesting:
        return 'penetrationTesting';
      case CareerPath.securityAnalyst:
        return 'securityAnalyst';
      case CareerPath.incidentResponse:
        return 'incidentResponse';
      case CareerPath.cryptography:
        return 'cryptography';
    }
  }

  // Yol haritasına adım eklemek için daha kapsamlı bir form ekleyebiliriz (sonraki aşama)
  void _showAddStepDialog(String roadmapId) {
    // TODO: Yol haritasına adım ekleme formunu ekle
  }
}
