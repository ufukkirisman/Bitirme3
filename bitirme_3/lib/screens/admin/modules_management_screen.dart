import 'package:flutter/material.dart';
import 'package:bitirme_3/services/admin_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bitirme_3/models/module.dart';

class ModulesManagementScreen extends StatefulWidget {
  const ModulesManagementScreen({Key? key}) : super(key: key);

  @override
  _ModulesManagementScreenState createState() =>
      _ModulesManagementScreenState();
}

class _ModulesManagementScreenState extends State<ModulesManagementScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  List<DocumentSnapshot> _modules = [];
  String _searchQuery = '';
  List<DocumentSnapshot> _filteredModules = [];

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  Future<void> _loadModules() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('modules').get();
      setState(() {
        _modules = snapshot.docs;
        _filteredModules = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Modüller yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
      // Hata mesajı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Modüller yüklenirken bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterModules(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredModules = _modules;
      } else {
        _filteredModules = _modules.where((module) {
          final data = module.data() as Map<String, dynamic>;
          return (data['title'] as String)
              .toLowerCase()
              .contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _showAddModuleDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final imageUrlController = TextEditingController();
    final orderController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Modül Ekle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Başlık',
                  hintText: 'Modül başlığını girin',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Modül açıklamasını girin',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Görsel URL',
                  hintText: 'Modül görsel URL\'sini girin',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: orderController,
                decoration: const InputDecoration(
                  labelText: 'Sıralama',
                  hintText: 'Modül sıralama numarası',
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
                // Yeni boş bir Module oluştur
                final newModule = Module(
                  id: '', // ID Firebase tarafından otomatik oluşturulacak
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  imageUrl: imageUrlController.text.trim(),
                  lessons: [], // Dersler henüz eklenmediği için boş liste
                  progress: 0, // İlerleme başlangıçta 0
                );

                // Module'ü Firestore'a ekle
                await FirebaseFirestore.instance.collection('modules').add({
                  ...newModule.toMap(),
                  'order': int.tryParse(orderController.text) ?? 0,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Modül başarıyla eklendi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadModules(); // Listeyi yenile
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Modül eklenirken hata oluştu: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _showEditModuleDialog(DocumentSnapshot module) {
    final data = module.data() as Map<String, dynamic>;
    final titleController = TextEditingController(text: data['title']);
    final descriptionController =
        TextEditingController(text: data['description']);
    final imageUrlController = TextEditingController(text: data['imageUrl']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modülü Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Başlık',
                  hintText: 'Modül başlığını girin',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Modül açıklamasını girin',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Görsel URL',
                  hintText: 'Modül görsel URL\'sini girin',
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
                await FirebaseFirestore.instance
                    .collection('modules')
                    .doc(module.id)
                    .update({
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'imageUrl': imageUrlController.text.trim(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Modül başarıyla güncellendi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadModules(); // Listeyi yenile
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Modül güncellenirken hata oluştu: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteModule(DocumentSnapshot module) async {
    // Onay dialog'u göster
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modülü Sil'),
        content: const Text(
            'Bu modülü silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Önce modüle bağlı dersleri bul
      final lessonsSnapshot = await FirebaseFirestore.instance
          .collection('modules')
          .doc(module.id)
          .collection('lessons')
          .get();

      // Batch işlemi başlat
      final batch = FirebaseFirestore.instance.batch();

      // Tüm dersleri silme işlemine ekle
      for (var lesson in lessonsSnapshot.docs) {
        batch.delete(lesson.reference);
      }

      // Ana modülü silme işlemine ekle
      batch.delete(module.reference);

      // Batch işlemini çalıştır
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Modül başarıyla silindi'),
            backgroundColor: Colors.green,
          ),
        );
        _loadModules(); // Listeyi yenile
      }
    } catch (e) {
      print('Modül silinirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Modül silinirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLessonsDialog(DocumentSnapshot module) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModuleLessonsScreen(moduleId: module.id),
      ),
    ).then((_) {
      // Dersler ekranından döndüğünde listeyi güncellemek isterseniz
      _loadModules();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modül Yönetimi'),
        backgroundColor: Colors.blueGrey.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadModules,
            tooltip: 'Yenile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddModuleDialog,
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
                labelText: 'Modül Ara',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _filterModules('');
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
              ),
              onChanged: _filterModules,
            ),
          ),
          // Modül Listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredModules.isEmpty
                    ? const Center(
                        child: Text(
                          'Modül bulunamadı.',
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredModules.length,
                        itemBuilder: (context, index) {
                          final module = _filteredModules[index];
                          final data = module.data() as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: ListTile(
                              title: Text(
                                data['title'] ?? 'İsimsiz Modül',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                data['description'] ?? 'Açıklama yok',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Dersler butonu
                                  IconButton(
                                    icon: const Icon(Icons.class_),
                                    onPressed: () => _showLessonsDialog(module),
                                    tooltip: 'Dersler',
                                  ),
                                  // Düzenle butonu
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () =>
                                        _showEditModuleDialog(module),
                                    tooltip: 'Düzenle',
                                  ),
                                  // Sil butonu
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteModule(module),
                                    tooltip: 'Sil',
                                    color: Colors.red,
                                  ),
                                ],
                              ),
                              onTap: () => _showEditModuleDialog(module),
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

class ModuleLessonsScreen extends StatefulWidget {
  final String moduleId;

  const ModuleLessonsScreen({Key? key, required this.moduleId})
      : super(key: key);

  @override
  _ModuleLessonsScreenState createState() => _ModuleLessonsScreenState();
}

class _ModuleLessonsScreenState extends State<ModuleLessonsScreen> {
  bool _isLoading = true;
  List<DocumentSnapshot> _lessons = [];
  String _moduleTitle = '';

  @override
  void initState() {
    super.initState();
    _loadModuleAndLessons();
  }

  Future<void> _loadModuleAndLessons() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Modül başlığını al
      final moduleDoc = await FirebaseFirestore.instance
          .collection('modules')
          .doc(widget.moduleId)
          .get();
      final moduleData = moduleDoc.data() as Map<String, dynamic>?;

      // Dersleri al
      final lessonsSnapshot = await FirebaseFirestore.instance
          .collection('modules')
          .doc(widget.moduleId)
          .collection('lessons')
          .orderBy('order', descending: false)
          .get();

      setState(() {
        _moduleTitle = moduleData?['title'] ?? 'İsimsiz Modül';
        _lessons = lessonsSnapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Dersler yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
      // Hata mesajı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dersler yüklenirken bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddLessonDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final durationController = TextEditingController(text: '30');
    final orderController = TextEditingController(text: '1');
    final quizIdController = TextEditingController();
    final simulationIdController = TextEditingController();
    String selectedType = 'theory'; // Varsayılan değer

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Yeni Ders Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Başlık',
                    hintText: 'Ders başlığını girin',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'İçerik',
                    hintText: 'Ders içeriğini girin',
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Ders Tipi',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'theory', child: Text('Teori')),
                    DropdownMenuItem(value: 'quiz', child: Text('Quiz')),
                    DropdownMenuItem(
                        value: 'simulation', child: Text('Simülasyon')),
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
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'Süre (dakika)',
                    hintText: 'Ders süresini girin',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: orderController,
                  decoration: const InputDecoration(
                    labelText: 'Sıra',
                    hintText: 'Ders sırasını girin (1, 2, 3, ...)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                if (selectedType == 'quiz')
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: TextField(
                      controller: quizIdController,
                      decoration: const InputDecoration(
                        labelText: 'Quiz ID',
                        hintText: 'Bağlantılı quiz ID\'sini girin',
                      ),
                    ),
                  ),
                if (selectedType == 'simulation')
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: TextField(
                      controller: simulationIdController,
                      decoration: const InputDecoration(
                        labelText: 'Simülasyon ID',
                        hintText: 'Bağlantılı simülasyon ID\'sini girin',
                      ),
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
                  final Map<String, dynamic> lessonData = {
                    'title': titleController.text.trim(),
                    'content': contentController.text.trim(),
                    'type': selectedType,
                    'durationMinutes':
                        int.tryParse(durationController.text) ?? 30,
                    'order': int.tryParse(orderController.text) ?? 1,
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  if (selectedType == 'quiz' &&
                      quizIdController.text.trim().isNotEmpty) {
                    lessonData['quizId'] = quizIdController.text.trim();
                  }

                  if (selectedType == 'simulation' &&
                      simulationIdController.text.trim().isNotEmpty) {
                    lessonData['simulationId'] =
                        simulationIdController.text.trim();
                  }

                  await FirebaseFirestore.instance
                      .collection('modules')
                      .doc(widget.moduleId)
                      .collection('lessons')
                      .add(lessonData);

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ders başarıyla eklendi'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadModuleAndLessons();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ders eklenirken hata oluştu: $e'),
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

  void _showEditLessonDialog(DocumentSnapshot lesson) {
    final data = lesson.data() as Map<String, dynamic>;
    final titleController = TextEditingController(text: data['title']);
    final contentController = TextEditingController(text: data['content']);
    final orderController =
        TextEditingController(text: data['order'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dersi Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Başlık',
                  hintText: 'Ders başlığını girin',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'İçerik',
                  hintText: 'Ders içeriğini girin',
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: orderController,
                decoration: const InputDecoration(
                  labelText: 'Sıra',
                  hintText: 'Ders sırasını girin (1, 2, 3, ...)',
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
                final order =
                    int.tryParse(orderController.text) ?? data['order'];

                await FirebaseFirestore.instance
                    .collection('modules')
                    .doc(widget.moduleId)
                    .collection('lessons')
                    .doc(lesson.id)
                    .update({
                  'title': titleController.text.trim(),
                  'content': contentController.text.trim(),
                  'order': order,
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ders başarıyla güncellendi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadModuleAndLessons(); // Listeyi yenile
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ders güncellenirken hata oluştu: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLesson(DocumentSnapshot lesson) async {
    // Onay dialog'u göster
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dersi Sil'),
        content: const Text(
            'Bu dersi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('modules')
          .doc(widget.moduleId)
          .collection('lessons')
          .doc(lesson.id)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ders başarıyla silindi'),
            backgroundColor: Colors.green,
          ),
        );
        _loadModuleAndLessons(); // Listeyi yenile
      }
    } catch (e) {
      print('Ders silinirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ders silinirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$_moduleTitle - Dersler'),
        backgroundColor: Colors.blueGrey.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadModuleAndLessons,
            tooltip: 'Yenile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLessonDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lessons.isEmpty
              ? const Center(
                  child: Text(
                    'Henüz ders eklenmemiş.',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  itemCount: _lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = _lessons[index];
                    final data = lesson.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            data['order'].toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          data['title'] ?? 'İsimsiz Ders',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          data['content'] ?? 'İçerik yok',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Düzenle butonu
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditLessonDialog(lesson),
                              tooltip: 'Düzenle',
                            ),
                            // Sil butonu
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteLesson(lesson),
                              tooltip: 'Sil',
                              color: Colors.red,
                            ),
                          ],
                        ),
                        onTap: () => _showEditLessonDialog(lesson),
                      ),
                    );
                  },
                ),
    );
  }
}
