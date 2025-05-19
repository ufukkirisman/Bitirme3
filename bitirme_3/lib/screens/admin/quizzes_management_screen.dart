import 'package:flutter/material.dart';
import 'package:bitirme_3/services/admin_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bitirme_3/models/quiz.dart';

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

      if (mounted) {
        setState(() {
          _quizzes = snapshot.docs;
          _filteredQuizzes = snapshot.docs;
          _isLoading = false;
        });

        // Sonuçları logla - Debug için
        print('Yüklenen quiz sayısı: ${snapshot.docs.length}');
        for (var doc in snapshot.docs) {
          print('Quiz ID: ${doc.id}, Başlık: ${doc.data()['title']}');
        }
      }
    } catch (e) {
      print('Quizler yüklenirken hata: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
        onPressed: _showAddQuizDialog,
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
                                      _showAddQuestionDialog(quiz.id);
                                    },
                                    tooltip: 'Soru Ekle',
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

  void _showAddQuizDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final timeLimitController = TextEditingController(text: '30');
    final moduleIdController = TextEditingController();
    final trainingIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Quiz Ekle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Başlık',
                  hintText: 'Quiz başlığını girin',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Quiz açıklamasını girin',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: timeLimitController,
                decoration: const InputDecoration(
                  labelText: 'Süre Limiti (dakika)',
                  hintText: 'Quiz süresi',
                ),
                keyboardType: TextInputType.number,
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
                controller: trainingIdController,
                decoration: const InputDecoration(
                  labelText: 'Eğitim ID (İsteğe bağlı)',
                  hintText: 'Bağlı olduğu eğitim ID',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Not: Quiz oluşturduktan sonra ayrı bir ekrandan sorular ekleyebileceksiniz.',
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
                // Quiz verisini hazırla
                final quizData = {
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'timeLimit': int.tryParse(timeLimitController.text) ?? 30,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                };

                // Eğer modül ID girilmişse ekle
                if (moduleIdController.text.trim().isNotEmpty) {
                  quizData['moduleId'] = moduleIdController.text.trim();
                }

                // Eğer eğitim ID girilmişse ekle
                if (trainingIdController.text.trim().isNotEmpty) {
                  quizData['trainingId'] = trainingIdController.text.trim();
                }

                // Firebase'e ekle
                await FirebaseFirestore.instance
                    .collection('quizzes')
                    .add(quizData);

                if (mounted) {
                  Navigator.pop(context);

                  // Quiz ekledikten sonra listeyi hemen güncelle
                  _loadQuizzes();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Quiz başarıyla eklendi. Şimdi sorular ekleyebilirsiniz.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Quiz eklenirken hata oluştu: $e'),
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

  // Quiz'e soru eklemek için form
  void _showAddQuestionDialog(String quizId) {
    final textController = TextEditingController();
    final explanationController = TextEditingController();
    final pointsController = TextEditingController(text: '5');
    final orderController = TextEditingController(text: '1');
    QuestionType selectedType = QuestionType.multipleChoice;

    // Cevap seçenekleri için
    List<Map<String, dynamic>> answers = [
      {'id': '1', 'text': '', 'isCorrect': true},
      {'id': '2', 'text': '', 'isCorrect': false},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Soru Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    labelText: 'Soru Metni',
                    hintText: 'Soruyu girin',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<QuestionType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Soru Tipi',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                        value: QuestionType.multipleChoice,
                        child: Text('Çoktan Seçmeli')),
                    DropdownMenuItem(
                        value: QuestionType.trueFalse,
                        child: Text('Doğru/Yanlış')),
                    DropdownMenuItem(
                        value: QuestionType.fillInBlank,
                        child: Text('Boşluk Doldurma')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedType = value;
                        // Soru tipi değiştiğinde cevapları yeniden düzenle
                        if (value == QuestionType.trueFalse) {
                          answers = [
                            {'id': '1', 'text': 'Doğru', 'isCorrect': true},
                            {'id': '2', 'text': 'Yanlış', 'isCorrect': false},
                          ];
                        } else if (value == QuestionType.fillInBlank) {
                          answers = [
                            {'id': '1', 'text': '', 'isCorrect': true},
                          ];
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pointsController,
                  decoration: const InputDecoration(
                    labelText: 'Puan',
                    hintText: 'Soru puanı',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: orderController,
                  decoration: const InputDecoration(
                    labelText: 'Sıra',
                    hintText: 'Soru sırası',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: explanationController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    hintText: 'Cevap sonrası gösterilecek açıklama',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cevap Seçenekleri',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),

                // Cevap seçenekleri listesi
                ...answers.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> answer = entry.value;
                  final textController =
                      TextEditingController(text: answer['text'] as String);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: textController,
                            decoration: InputDecoration(
                              labelText: 'Seçenek ${index + 1}',
                              hintText: 'Cevap metnini girin',
                            ),
                            onChanged: (value) {
                              setState(() {
                                answers[index]['text'] = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Checkbox(
                          value: answer['isCorrect'] as bool,
                          onChanged: (value) {
                            setState(() {
                              // Çoktan seçmeli sorularda sadece bir doğru cevap olabilir
                              if (selectedType == QuestionType.multipleChoice) {
                                for (var i = 0; i < answers.length; i++) {
                                  answers[i]['isCorrect'] =
                                      i == index && value == true;
                                }
                              } else {
                                answers[index]['isCorrect'] = value ?? false;
                              }
                            });
                          },
                        ),
                        if (selectedType == QuestionType.multipleChoice &&
                            answers.length > 2)
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                answers.removeAt(index);
                              });
                            },
                          ),
                      ],
                    ),
                  );
                }).toList(),

                // Çoktan seçmeli sorularda seçenek ekle butonu
                if (selectedType == QuestionType.multipleChoice)
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Seçenek Ekle'),
                    onPressed: () {
                      setState(() {
                        answers.add({
                          'id': (answers.length + 1).toString(),
                          'text': '',
                          'isCorrect': false,
                        });
                      });
                    },
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
                if (textController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Soru metni boş olamaz'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Cevapları kontrol et
                bool hasValidAnswers = false;
                for (var answer in answers) {
                  if ((answer['text'] as String).trim().isNotEmpty) {
                    hasValidAnswers = true;
                    break;
                  }
                }

                if (!hasValidAnswers) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('En az bir geçerli cevap seçeneği olmalıdır'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  // Soru verisini hazırla
                  final questionData = {
                    'text': textController.text.trim(),
                    'type': selectedType.toString().split('.').last,
                    'points': int.tryParse(pointsController.text) ?? 5,
                    'explanation': explanationController.text.trim(),
                    'order': int.tryParse(orderController.text) ?? 1,
                    'answers': answers
                        .map((a) => {
                              'id': a['id'],
                              'text': a['text'],
                              'isCorrect': a['isCorrect'],
                            })
                        .toList(),
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  // Firebase'e ekle
                  await FirebaseFirestore.instance
                      .collection('quizzes')
                      .doc(quizId)
                      .collection('questions')
                      .add(questionData);

                  if (mounted) {
                    Navigator.pop(context);

                    // Soru ekledikten sonra listeyi güncelle
                    _loadQuizzes();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Soru başarıyla eklendi'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Soru eklenirken hata oluştu: $e'),
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
