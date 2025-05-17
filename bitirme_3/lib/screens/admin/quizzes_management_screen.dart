import 'package:flutter/material.dart';
import 'package:bitirme_3/services/admin_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizzesManagementScreen extends StatefulWidget {
  const QuizzesManagementScreen({Key? key}) : super(key: key);

  @override
  _QuizzesManagementScreenState createState() =>
      _QuizzesManagementScreenState();
}

class _QuizzesManagementScreenState extends State<QuizzesManagementScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  List<DocumentSnapshot> _quizzes = [];
  String _searchQuery = '';
  List<DocumentSnapshot> _filteredQuizzes = [];

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('quizzes').get();
      setState(() {
        _quizzes = snapshot.docs;
        _filteredQuizzes = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Quizler yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quizler yüklenirken bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterQuizzes(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredQuizzes = _quizzes;
      } else {
        _filteredQuizzes = _quizzes.where((quiz) {
          final data = quiz.data() as Map<String, dynamic>;
          return (data['title'] as String)
              .toLowerCase()
              .contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Yönetimi'),
        backgroundColor: Colors.blueGrey.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuizzes,
            tooltip: 'Yenile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Quiz ekleme işlevi henüz geliştirilme aşamasındadır.'),
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
                labelText: 'Quiz Ara',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _filterQuizzes('');
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
              ),
              onChanged: _filterQuizzes,
            ),
          ),
          // Quiz Listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredQuizzes.isEmpty
                    ? const Center(
                        child: Text(
                          'Quiz bulunamadı.',
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredQuizzes.length,
                        itemBuilder: (context, index) {
                          final quiz = _filteredQuizzes[index];
                          final data = quiz.data() as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: ListTile(
                              title: Text(
                                data['title'] ?? 'İsimsiz Quiz',
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
                                  // Detay butonu
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Quiz düzenleme henüz geliştirilme aşamasındadır.'),
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
                                          title: const Text('Quiz\'i Sil'),
                                          content: const Text(
                                              'Bu quiz\'i silmek istediğinizden emin misiniz?'),
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
                                          // Sorular koleksiyonu sil
                                          final questionsSnapshot =
                                              await FirebaseFirestore.instance
                                                  .collection('quizzes')
                                                  .doc(quiz.id)
                                                  .collection('questions')
                                                  .get();

                                          final batch = FirebaseFirestore
                                              .instance
                                              .batch();
                                          for (var doc
                                              in questionsSnapshot.docs) {
                                            batch.delete(doc.reference);
                                          }

                                          // Quiz belgesini sil
                                          batch.delete(quiz.reference);
                                          await batch.commit();

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Quiz başarıyla silindi'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                          _loadQuizzes();
                                        } catch (e) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Quiz silinirken hata: $e'),
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
