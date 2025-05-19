import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bitirme_3/models/roadmap.dart';
import 'package:google_fonts/google_fonts.dart';

class RoadmapStepsScreen extends StatefulWidget {
  final String roadmapId;
  final String roadmapTitle;

  const RoadmapStepsScreen({
    Key? key,
    required this.roadmapId,
    required this.roadmapTitle,
  }) : super(key: key);

  @override
  _RoadmapStepsScreenState createState() => _RoadmapStepsScreenState();
}

class _RoadmapStepsScreenState extends State<RoadmapStepsScreen> {
  bool _isLoading = true;
  List<QueryDocumentSnapshot> _steps = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSteps();
  }

  Future<void> _loadSteps() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final stepsRef = FirebaseFirestore.instance
          .collection('roadmaps')
          .doc(widget.roadmapId)
          .collection('steps');

      final stepsQuery = await stepsRef.orderBy('order').get();

      setState(() {
        _steps = stepsQuery.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Yol haritası adımları yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteStep(String stepId) async {
    try {
      await FirebaseFirestore.instance
          .collection('roadmaps')
          .doc(widget.roadmapId)
          .collection('steps')
          .doc(stepId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adım başarıyla silindi'),
          backgroundColor: Colors.green,
        ),
      );

      _loadSteps();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Adım silinirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yol Haritası Adımları: ${widget.roadmapTitle}'),
        backgroundColor: const Color(0xFF1C2D40),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddStepDialog(),
        backgroundColor: const Color(0xFF00AACC),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _steps.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.route,
                            size: 80,
                            color: Color(0xFF00AACC),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Henüz Adım Yok',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Text(
                              'Bu yol haritası için henüz adım eklenmemiş. Yeni adım eklemek için "+" butonuna tıklayın.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ReorderableListView.builder(
                        itemCount: _steps.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (oldIndex < newIndex) {
                              newIndex -= 1;
                            }
                            final item = _steps.removeAt(oldIndex);
                            _steps.insert(newIndex, item);
                          });
                          _updateStepOrders();
                        },
                        itemBuilder: (context, index) {
                          final step = _steps[index];
                          final stepData = step.data() as Map<String, dynamic>;

                          return Card(
                            key: Key(step.id),
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF00AACC),
                                child: Text('${index + 1}'),
                              ),
                              title: Text(
                                stepData['title'] ?? 'İsimsiz Adım',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stepData['description'] ?? 'Açıklama yok',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  if ((stepData['requiredSkills']
                                              as List<dynamic>?)
                                          ?.isNotEmpty ??
                                      false)
                                    Wrap(
                                      spacing: 4,
                                      children: (stepData['requiredSkills']
                                              as List<dynamic>)
                                          .map((skill) => Chip(
                                                label: Text(
                                                  skill as String,
                                                  style: const TextStyle(
                                                      fontSize: 10),
                                                ),
                                                backgroundColor:
                                                    const Color(0xFFE0F7FA),
                                                labelStyle: const TextStyle(
                                                    color: Color(0xFF006064)),
                                                padding: EdgeInsets.zero,
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ))
                                          .toList(),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Kaynaklar butonu
                                  IconButton(
                                    icon: const Icon(Icons.list,
                                        color: Color(0xFF00AACC)),
                                    onPressed: () {
                                      // Kaynakları yönetme ekranına git
                                      _showResourcesDialog(step.id,
                                          stepData['title'] ?? 'İsimsiz Adım');
                                    },
                                    tooltip: 'Kaynaklar',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Color(0xFF00AACC)),
                                    onPressed: () {
                                      _showEditStepDialog(step.id, stepData);
                                    },
                                    tooltip: 'Düzenle',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Adımı Sil'),
                                          content: const Text(
                                              'Bu adımı silmek istediğinizden emin misiniz?'),
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
                                        _deleteStep(step.id);
                                      }
                                    },
                                    tooltip: 'Sil',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Future<void> _updateStepOrders() async {
    // Batch güncelleme için
    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (int i = 0; i < _steps.length; i++) {
      batch.update(
        FirebaseFirestore.instance
            .collection('roadmaps')
            .doc(widget.roadmapId)
            .collection('steps')
            .doc(_steps[i].id),
        {'order': i + 1},
      );
    }

    try {
      await batch.commit();
      // Sıralamayı veritabanında güncelleme başarılı oldu
      _loadSteps(); // Listeyi yenile
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Adım sıralaması güncellenirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddStepDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final skillsController = TextEditingController();
    final orderController = TextEditingController(text: '${_steps.length + 1}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Adım Ekle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Adım Başlığı',
                  hintText: 'Adım için bir başlık girin',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Bu adım için bir açıklama girin',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: skillsController,
                decoration: const InputDecoration(
                  labelText: 'Gerekli Beceriler',
                  hintText: 'Becerileri virgülle ayırarak girin',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: orderController,
                decoration: const InputDecoration(
                  labelText: 'Sıra',
                  hintText: 'Adımın sıra numarası',
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
                List<String> skills = [];
                if (skillsController.text.isNotEmpty) {
                  skills = skillsController.text
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();
                }

                await FirebaseFirestore.instance
                    .collection('roadmaps')
                    .doc(widget.roadmapId)
                    .collection('steps')
                    .add({
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'order':
                      int.tryParse(orderController.text) ?? (_steps.length + 1),
                  'requiredSkills': skills,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Adım başarıyla eklendi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadSteps();
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
    );
  }

  void _showEditStepDialog(String stepId, Map<String, dynamic> stepData) {
    final titleController =
        TextEditingController(text: stepData['title'] ?? '');
    final descriptionController =
        TextEditingController(text: stepData['description'] ?? '');
    final orderController =
        TextEditingController(text: '${stepData['order'] ?? 1}');

    // Becerileri String'e çevir
    final List<dynamic> skillsList = stepData['requiredSkills'] ?? [];
    final String skillsString = skillsList.join(', ');
    final skillsController = TextEditingController(text: skillsString);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adımı Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Adım Başlığı',
                  hintText: 'Adım için bir başlık girin',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Bu adım için bir açıklama girin',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: skillsController,
                decoration: const InputDecoration(
                  labelText: 'Gerekli Beceriler',
                  hintText: 'Becerileri virgülle ayırarak girin',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: orderController,
                decoration: const InputDecoration(
                  labelText: 'Sıra',
                  hintText: 'Adımın sıra numarası',
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
                List<String> skills = [];
                if (skillsController.text.isNotEmpty) {
                  skills = skillsController.text
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();
                }

                await FirebaseFirestore.instance
                    .collection('roadmaps')
                    .doc(widget.roadmapId)
                    .collection('steps')
                    .doc(stepId)
                    .update({
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'order': int.tryParse(orderController.text) ?? 1,
                  'requiredSkills': skills,
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Adım başarıyla güncellendi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadSteps();
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Adım güncellenirken hata oluştu: $e'),
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

  void _showResourcesDialog(String stepId, String stepTitle) {
    // Kaynakları görüntülemek ve düzenlemek için bir dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kaynaklar: $stepTitle'),
        content: const Text('Kaynakları yönetme özelliği henüz eklenmedi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
