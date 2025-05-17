import 'package:flutter/material.dart';
import 'package:bitirme_3/models/training.dart';
import 'package:bitirme_3/services/training_service.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({Key? key}) : super(key: key);

  @override
  _TrainingScreenState createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  final TrainingService _trainingService = TrainingService();
  bool _isLoading = true;
  List<Training> _trainings = [];

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
      final trainings = await _trainingService.getTrainings();
      setState(() {
        _trainings = trainings;
        _isLoading = false;
      });
    } catch (e) {
      print('Eğitimler yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
      // Hata mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Eğitimler yüklenirken bir hata oluştu.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getLevelText(TrainingLevel level) {
    switch (level) {
      case TrainingLevel.beginner:
        return 'Başlangıç';
      case TrainingLevel.intermediate:
        return 'Orta Seviye';
      case TrainingLevel.advanced:
        return 'İleri Seviye';
      case TrainingLevel.expert:
        return 'Uzman';
      default:
        return 'Bilinmiyor';
    }
  }

  Color _getLevelColor(TrainingLevel level) {
    switch (level) {
      case TrainingLevel.beginner:
        return Colors.green;
      case TrainingLevel.intermediate:
        return Colors.blue;
      case TrainingLevel.advanced:
        return Colors.orange;
      case TrainingLevel.expert:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eğitimler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrainings,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trainings.isEmpty
              ? const Center(
                  child: Text(
                    'Henüz eğitim bulunmuyor.',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTrainings,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _trainings.length,
                    itemBuilder: (context, index) {
                      final training = _trainings[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        elevation: 5.0,
                        margin: const EdgeInsets.only(bottom: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Eğitim Görseli
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.asset(
                                training.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade800,
                                    child: const Center(
                                      child: Icon(
                                        Icons.school,
                                        size: 50,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Eğitim İçeriği
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Seviye etiketi
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0, vertical: 4.0),
                                    decoration: BoxDecoration(
                                      color: _getLevelColor(training.level)
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4.0),
                                      border: Border.all(
                                        color: _getLevelColor(training.level),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Text(
                                      _getLevelText(training.level),
                                      style: TextStyle(
                                        color: _getLevelColor(training.level),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  // Eğitim Başlığı
                                  Text(
                                    training.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  // Eğitmen
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.person,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4.0),
                                      Text(
                                        'Eğitmen: ${training.instructor}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4.0),
                                  // Süre
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4.0),
                                      Text(
                                        'Süre: ${training.durationHours} saat',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12.0),
                                  // Açıklama
                                  Text(
                                    training.description,
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                    ),
                                  ),
                                  const SizedBox(height: 16.0),
                                  // İlerleme Durumu
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'İlerleme Durumu',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '%${training.progress}',
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8.0),
                                      LinearProgressIndicator(
                                        value: training.progress / 100,
                                        backgroundColor: Colors.grey.shade800,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Theme.of(context)
                                                    .colorScheme
                                                    .primary),
                                        minHeight: 8,
                                        borderRadius:
                                            BorderRadius.circular(4.0),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16.0),
                                  // Beceriler
                                  Wrap(
                                    spacing: 8.0,
                                    runSpacing: 8.0,
                                    children: training.skills.map((skill) {
                                      return Chip(
                                        label: Text(skill),
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                        side: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary
                                              .withOpacity(0.5),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 16.0),
                                  // Devam Et Butonu
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        // Eğitim detay sayfasına git
                                        Navigator.pushNamed(
                                          context,
                                          '/training/${training.id}',
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12.0),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                      ),
                                      child: Text(
                                        training.progress > 0
                                            ? 'Devam Et'
                                            : 'Başla',
                                        style: const TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class TrainingDetailScreen extends StatelessWidget {
  final String trainingId;

  const TrainingDetailScreen({Key? key, required this.trainingId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eğitim Detayı'),
      ),
      body: const Center(
        child: Text('Eğitim detay sayfası henüz yapım aşamasında...'),
      ),
    );
  }
}
