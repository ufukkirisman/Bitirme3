import 'package:flutter/material.dart';
import 'package:bitirme_3/services/admin_service.dart';
import 'package:bitirme_3/models/training.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrainingsManagementScreen extends StatefulWidget {
  const TrainingsManagementScreen({Key? key}) : super(key: key);

  @override
  _TrainingsManagementScreenState createState() =>
      _TrainingsManagementScreenState();
}

class _TrainingsManagementScreenState extends State<TrainingsManagementScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  List<DocumentSnapshot> _trainings = [];
  String _searchQuery = '';
  List<DocumentSnapshot> _filteredTrainings = [];

  @override
  void initState() {
    super.initState();
    _loadTrainings();
  }

  Future<void> _loadTrainings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('trainings').get();

      if (mounted) {
        setState(() {
          _trainings = snapshot.docs;
          _filteredTrainings = snapshot.docs;
          _isLoading = false;
        });

        // Sonuçları logla - Debug için
        print('Yüklenen eğitim sayısı: ${snapshot.docs.length}');
        for (var doc in snapshot.docs) {
          print('Eğitim ID: ${doc.id}, Başlık: ${doc.data()['title']}');
        }
      }
    } catch (e) {
      print('Eğitimler yüklenirken hata: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eğitimler yüklenirken bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterTrainings(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredTrainings = _trainings;
      } else {
        _filteredTrainings = _trainings.where((training) {
          final data = training.data() as Map<String, dynamic>;
          return (data['title'] as String)
              .toLowerCase()
              .contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  String _getTrainingLevelText(String levelStr) {
    switch (levelStr) {
      case 'beginner':
        return 'Başlangıç';
      case 'intermediate':
        return 'Orta Düzey';
      case 'advanced':
        return 'İleri Düzey';
      case 'expert':
        return 'Uzman';
      default:
        return 'Bilinmeyen Seviye';
    }
  }

  String _getContentTypeText(String typeStr) {
    switch (typeStr) {
      case 'video':
        return 'Video';
      case 'document':
        return 'Doküman';
      case 'presentation':
        return 'Sunum';
      case 'codeLab':
        return 'Kod Laboratuvarı';
      case 'exercise':
        return 'Alıştırma';
      case 'certification':
        return 'Sertifikasyon';
      default:
        return 'Bilinmeyen Tür';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eğitim Yönetimi'),
        backgroundColor: Colors.red.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrainings,
            tooltip: 'Yenile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTrainingDialog,
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
                labelText: 'Eğitim Ara',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _filterTrainings('');
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
              ),
              onChanged: _filterTrainings,
            ),
          ),
          // Eğitim Listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTrainings.isEmpty
                    ? const Center(
                        child: Text(
                          'Eğitim bulunamadı.',
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredTrainings.length,
                        itemBuilder: (context, index) {
                          final training = _filteredTrainings[index];
                          final data = training.data() as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: ExpansionTile(
                              title: Text(
                                data['title'] ?? 'İsimsiz Eğitim',
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
                                          color: Colors.red.shade100,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getTrainingLevelText(
                                              data['level'] ?? ''),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red.shade800,
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
                                              Icons.timer,
                                              size: 14,
                                              color: Colors.grey.shade800,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${data['durationHours'] ?? 0} saat',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.person,
                                        size: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          data['instructor'] ??
                                              'Bilinmeyen Eğitmen',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
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
                                      _showAddContentDialog(training.id);
                                    },
                                    tooltip: 'İçerik Ekle',
                                  ),
                                  // Sil butonu
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Eğitimi Sil'),
                                          content: const Text(
                                              'Bu eğitimi silmek istediğinizden emin misiniz?'),
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
                                              .deleteTraining(training.id);

                                          if (success) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Eğitim başarıyla silindi'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                            _loadTrainings();
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Eğitim silinirken bir hata oluştu'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Eğitim silinirken hata: $e'),
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
                                if ((data['skills'] as List<dynamic>?)
                                        ?.isNotEmpty ??
                                    false)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Kazanılan Yetenekler:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 8,
                                          children:
                                              (data['skills'] as List<dynamic>)
                                                  .map((skill) {
                                            return Chip(
                                              label: Text(skill as String),
                                              backgroundColor:
                                                  Colors.red.shade50,
                                              labelStyle: TextStyle(
                                                color: Colors.red.shade800,
                                                fontSize: 12,
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                FutureBuilder<QuerySnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('trainings')
                                      .doc(training.id)
                                      .collection('contents')
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
                                            'Bu eğitime ait içerik bulunamadı.'),
                                      );
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'İçerikler',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ...snapshot.data!.docs
                                              .map((contentDoc) {
                                            final contentData = contentDoc
                                                .data() as Map<String, dynamic>;
                                            return ListTile(
                                              title: Text(
                                                  contentData['title'] ??
                                                      'İsimsiz İçerik'),
                                              subtitle: Text(
                                                contentData['description'] ??
                                                    'Açıklama yok',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              leading: CircleAvatar(
                                                backgroundColor:
                                                    Colors.red.shade100,
                                                child: Icon(
                                                  _getContentTypeIcon(
                                                      contentData['type'] ??
                                                          ''),
                                                  color: Colors.red.shade800,
                                                  size: 18,
                                                ),
                                              ),
                                              trailing: Text(
                                                '${contentData['durationMinutes'] ?? 0} dk',
                                                style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                  fontWeight: FontWeight.bold,
                                                ),
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

  IconData _getContentTypeIcon(String typeStr) {
    switch (typeStr) {
      case 'video':
        return Icons.videocam;
      case 'document':
        return Icons.article;
      case 'presentation':
        return Icons.slideshow;
      case 'codeLab':
        return Icons.code;
      case 'exercise':
        return Icons.assignment;
      case 'certification':
        return Icons.card_membership;
      default:
        return Icons.help_outline;
    }
  }

  void _showAddTrainingDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final imageUrlController = TextEditingController();
    final instructorController = TextEditingController();
    final durationHoursController = TextEditingController(text: '10');
    final skillsController = TextEditingController();
    final moduleIdController = TextEditingController();
    TrainingLevel selectedLevel = TrainingLevel.beginner;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Yeni Eğitim Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Başlık',
                    hintText: 'Eğitim başlığını girin',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    hintText: 'Eğitim açıklamasını girin',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Görsel URL',
                    hintText: 'Eğitim görsel URL\'sini girin',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: moduleIdController,
                  decoration: const InputDecoration(
                    labelText: 'Modül ID',
                    hintText: 'Bağlı olduğu modül ID\'si',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: instructorController,
                  decoration: const InputDecoration(
                    labelText: 'Eğitmen',
                    hintText: 'Eğitmenin adı',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: durationHoursController,
                  decoration: const InputDecoration(
                    labelText: 'Süre (saat)',
                    hintText: 'Eğitim süresi',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: skillsController,
                  decoration: const InputDecoration(
                    labelText: 'Yetenekler (virgülle ayırın)',
                    hintText: 'Örn: Ağ Analizi, Sızma Testi',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TrainingLevel>(
                  value: selectedLevel,
                  decoration: const InputDecoration(
                    labelText: 'Eğitim Seviyesi',
                    border: OutlineInputBorder(),
                  ),
                  items: TrainingLevel.values.map((level) {
                    return DropdownMenuItem<TrainingLevel>(
                      value: level,
                      child:
                          Text(_getTrainingLevelText(_getLevelString(level))),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedLevel = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Not: Eğitim oluşturduktan sonra ayrı bir ekrandan içerikler ekleyebileceksiniz.',
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
                  // Yetenekleri virgülle ayırıp liste haline getir
                  List<String> skills = [];
                  if (skillsController.text.isNotEmpty) {
                    skills = skillsController.text
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();
                  }

                  // Eğitim verisini hazırla
                  final trainingData = {
                    'title': titleController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'imageUrl': imageUrlController.text.trim(),
                    'instructor': instructorController.text.trim(),
                    'durationHours':
                        int.tryParse(durationHoursController.text) ?? 10,
                    'level': _getLevelString(selectedLevel),
                    'skills': skills,
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  // Modül ID'si ekle
                  if (moduleIdController.text.trim().isNotEmpty) {
                    trainingData['moduleId'] = moduleIdController.text.trim();
                  }

                  // Firebase'e ekle
                  await FirebaseFirestore.instance
                      .collection('trainings')
                      .add(trainingData);

                  if (mounted) {
                    Navigator.pop(context);

                    // Eğitim ekledikten sonra listeyi hemen güncelle
                    _loadTrainings();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Eğitim başarıyla eklendi. Şimdi içerikler ekleyebilirsiniz.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Eğitim eklenirken hata oluştu: $e'),
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

  String _getLevelString(TrainingLevel level) {
    switch (level) {
      case TrainingLevel.beginner:
        return 'beginner';
      case TrainingLevel.intermediate:
        return 'intermediate';
      case TrainingLevel.advanced:
        return 'advanced';
      case TrainingLevel.expert:
        return 'expert';
    }
  }

  // Eğitime içerik eklemek için form
  void _showAddContentDialog(String trainingId) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final urlController = TextEditingController();
    final durationController = TextEditingController(text: '30');
    final orderController = TextEditingController(text: '1');
    String selectedType = 'video'; // Varsayılan içerik tipi

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Yeni İçerik Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Başlık',
                    hintText: 'İçerik başlığını girin',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    hintText: 'İçerik açıklamasını girin',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'İçerik Tipi',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'video', child: Text('Video')),
                    DropdownMenuItem(value: 'document', child: Text('Doküman')),
                    DropdownMenuItem(
                        value: 'presentation', child: Text('Sunum')),
                    DropdownMenuItem(
                        value: 'codeLab', child: Text('Kod Laboratuvarı')),
                    DropdownMenuItem(
                        value: 'exercise', child: Text('Alıştırma')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL',
                    hintText: 'İçerik bağlantısını girin',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'Süre (dakika)',
                    hintText: 'İçerik süresi',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: orderController,
                  decoration: const InputDecoration(
                    labelText: 'Sıralama',
                    hintText: 'İçerik sıralama değeri',
                  ),
                  keyboardType: TextInputType.number,
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
                  // İçerik verisini hazırla
                  final contentData = {
                    'title': titleController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'type': selectedType,
                    'url': urlController.text.trim(),
                    'durationMinutes':
                        int.tryParse(durationController.text) ?? 30,
                    'order': int.tryParse(orderController.text) ?? 1,
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  // Firebase'e ekle
                  await FirebaseFirestore.instance
                      .collection('trainings')
                      .doc(trainingId)
                      .collection('contents')
                      .add(contentData);

                  if (mounted) {
                    Navigator.pop(context);

                    // İçerik ekledikten sonra listeyi güncelle
                    _loadTrainings();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('İçerik başarıyla eklendi'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('İçerik eklenirken hata oluştu: $e'),
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
}
