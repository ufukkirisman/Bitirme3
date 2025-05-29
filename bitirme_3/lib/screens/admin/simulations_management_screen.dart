import 'package:flutter/material.dart';
import 'package:bitirme_3/services/admin_service.dart';
import 'package:bitirme_3/models/simulation.dart' as app_sim;
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

      if (mounted) {
        setState(() {
          _simulations = snapshot.docs;
          _filteredSimulations = snapshot.docs;
          _isLoading = false;
        });

        // Sonuçları logla - Debug için
        print('Yüklenen simülasyon sayısı: ${snapshot.docs.length}');
        for (var doc in snapshot.docs) {
          print('Simülasyon ID: ${doc.id}, Başlık: ${doc.data()['title']}');
        }
      }
    } catch (e) {
      print('Simülasyonlar yüklenirken hata: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
        onPressed: _showAddSimulationDialog,
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
                                      _showAddStepDialog(simulation.id);
                                    },
                                    tooltip: 'Adım Ekle',
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

  void _showAddSimulationDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final imageUrlController = TextEditingController();
    final difficultyController = TextEditingController(text: '3');
    final moduleIdController = TextEditingController();
    app_sim.SimulationType selectedType =
        app_sim.SimulationType.networkAnalysis;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Yeni Simülasyon Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Başlık',
                    hintText: 'Simülasyon başlığını girin',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    hintText: 'Simülasyon açıklamasını girin',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Görsel URL',
                    hintText: 'Simülasyon görsel URL\'sini girin',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: moduleIdController,
                  decoration: const InputDecoration(
                    labelText: 'Modül ID (İsteğe bağlı)',
                    hintText: 'Bağlı olduğu modül ID',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: difficultyController,
                  decoration: const InputDecoration(
                    labelText: 'Zorluk Seviyesi (1-5)',
                    hintText: 'Zorluk seviyesi',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<app_sim.SimulationType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Simülasyon Türü',
                    border: OutlineInputBorder(),
                  ),
                  items: app_sim.SimulationType.values.map((type) {
                    return DropdownMenuItem<app_sim.SimulationType>(
                      value: type,
                      child: Text(_getSimulationTypeText(_getTypeString(type))),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedType = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Not: Simülasyon oluşturduktan sonra ayrı bir ekrandan adımlar ekleyebileceksiniz.',
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
                  // Zorluk seviyesini 1-5 arasında sınırla
                  int difficultyLevel =
                      int.tryParse(difficultyController.text) ?? 3;
                  difficultyLevel = difficultyLevel.clamp(1, 5);

                  // Simülasyon verisini hazırla
                  final simulationData = {
                    'title': titleController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'imageUrl': imageUrlController.text.trim(),
                    'type': _getTypeString(selectedType),
                    'difficultyLevel': difficultyLevel,
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  // Modül ID'si varsa ekle
                  if (moduleIdController.text.trim().isNotEmpty) {
                    simulationData['moduleId'] = moduleIdController.text.trim();
                  }

                  // Firebase'e ekle
                  final docRef = await FirebaseFirestore.instance
                      .collection('simulations')
                      .add(simulationData);

                  if (mounted) {
                    Navigator.pop(context);

                    // Simülasyon ekledikten sonra listeyi hemen güncelle
                    _loadSimulations();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Simülasyon başarıyla eklendi. Şimdi adımlar ekleyebilirsiniz.'),
                        backgroundColor: Colors.green,
                      ),
                    );

                    // Adım ekleme ekranını doğrudan aç
                    _showAddStepDialog(docRef.id);
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Simülasyon eklenirken hata oluştu: $e'),
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

  String _getTypeString(app_sim.SimulationType type) {
    switch (type) {
      case app_sim.SimulationType.networkAnalysis:
        return 'networkAnalysis';
      case app_sim.SimulationType.penetrationTesting:
        return 'penetrationTesting';
      case app_sim.SimulationType.forensicAnalysis:
        return 'forensicAnalysis';
      case app_sim.SimulationType.malwareAnalysis:
        return 'malwareAnalysis';
      case app_sim.SimulationType.cryptography:
        return 'cryptography';
      case app_sim.SimulationType.socialEngineering:
        return 'socialEngineering';
    }
  }

  // Simülasyona adım eklemek için form
  void _showAddStepDialog(String simulationId) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final commandsController = TextEditingController();
    final expectedOutputController = TextEditingController();
    final orderController = TextEditingController(text: '1');

    // Çoktan seçmeli yanıtlar için değişkenler
    bool hasMultipleChoiceOptions = false;
    List<Map<String, dynamic>> options = [];

    void addNewOption() {
      options.add({
        'id': 'option${options.length + 1}',
        'text': '',
        'isCorrect': false,
      });
    }

    // Başlangıç için bir seçenek ekle
    addNewOption();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Simülasyon Adımı Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Başlık',
                    hintText: 'Adım başlığını girin',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    hintText: 'Adım açıklamasını girin',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Adım türü seçimi
                SwitchListTile(
                  title: const Text('Çoktan Seçmeli Soru'),
                  subtitle: const Text('Bu adım bir senaryo sorusu içerecek'),
                  value: hasMultipleChoiceOptions,
                  onChanged: (value) {
                    setState(() {
                      hasMultipleChoiceOptions = value;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Çoktan seçmeli soru ise şıkları göster
                if (hasMultipleChoiceOptions) ...[
                  const Divider(),
                  const Text(
                    'Seçenekler',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: 'Seçenek ${index + 1}',
                                hintText: 'Şık içeriğini girin',
                              ),
                              onChanged: (value) {
                                setState(() {
                                  options[index]['text'] = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Checkbox(
                            value: option['isCorrect'] as bool,
                            onChanged: (value) {
                              setState(() {
                                options[index]['isCorrect'] = value ?? false;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: options.length > 1
                                ? () {
                                    setState(() {
                                      options.removeAt(index);
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        addNewOption();
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Seçenek Ekle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                  const Divider(),
                ] else ...[
                  TextField(
                    controller: commandsController,
                    decoration: const InputDecoration(
                      labelText: 'Komutlar (virgülle ayırın)',
                      hintText: 'Örn: git clone, cd project',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: expectedOutputController,
                    decoration: const InputDecoration(
                      labelText: 'Beklenen Çıktı',
                      hintText: 'Komutların beklenen çıktısını girin',
                    ),
                    maxLines: 3,
                  ),
                ],

                const SizedBox(height: 16),
                TextField(
                  controller: orderController,
                  decoration: const InputDecoration(
                    labelText: 'Sıra',
                    hintText: 'Adım sırası',
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

                // Çoktan seçmeli soru kontrolü
                if (hasMultipleChoiceOptions) {
                  // Boş seçenek kontrolü
                  bool hasEmptyOption = false;
                  for (var option in options) {
                    if ((option['text'] as String).trim().isEmpty) {
                      hasEmptyOption = true;
                      break;
                    }
                  }

                  if (hasEmptyOption) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tüm seçenekler doldurulmalıdır'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Doğru cevap kontrolü
                  bool hasCorrectAnswer =
                      options.any((option) => option['isCorrect'] == true);
                  if (!hasCorrectAnswer) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('En az bir doğru cevap işaretlenmelidir'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                }

                try {
                  // Çoktan seçmeli değilse, komutları virgülle ayırıp liste haline getir
                  List<String> commands = [];
                  if (!hasMultipleChoiceOptions &&
                      commandsController.text.isNotEmpty) {
                    commands = commandsController.text
                        .split(',')
                        .map((c) => c.trim())
                        .where((c) => c.isNotEmpty)
                        .toList();
                  }

                  // Adım verisini hazırla
                  final stepData = {
                    'title': titleController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'commands': commands,
                    'expectedOutput': hasMultipleChoiceOptions
                        ? ''
                        : expectedOutputController.text.trim(),
                    'order': int.tryParse(orderController.text) ?? 1,
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                    'hasMultipleChoiceOptions': hasMultipleChoiceOptions,
                  };

                  // Eğer çoktan seçmeli bir soruysa şıkları ekle
                  if (hasMultipleChoiceOptions) {
                    stepData['options'] = options;
                  }

                  // Firebase'e ekle
                  await FirebaseFirestore.instance
                      .collection('simulations')
                      .doc(simulationId)
                      .collection('steps')
                      .add(stepData);

                  if (mounted) {
                    Navigator.pop(context);

                    // Adım ekledikten sonra listeyi güncelle
                    _loadSimulations();

                    // Başarı mesajı göster ve başka adım eklemek isteyip istemediğini sor
                    final addAnother = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Adım Eklendi'),
                        content:
                            const Text('Başka bir adım eklemek ister misiniz?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Hayır'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Evet'),
                          ),
                        ],
                      ),
                    );

                    // Eğer başka adım eklemek istiyorsa formu tekrar aç
                    if (addAnother == true) {
                      _showAddStepDialog(simulationId);
                    }
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Adım eklenirken hata oluştu: $e'),
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
