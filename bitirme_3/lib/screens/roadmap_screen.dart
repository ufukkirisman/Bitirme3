import 'package:flutter/material.dart';
import 'package:bitirme_3/models/roadmap.dart';
import 'package:bitirme_3/services/roadmap_service.dart';

class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({Key? key}) : super(key: key);

  @override
  _RoadmapScreenState createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  final RoadmapService _roadmapService = RoadmapService();
  bool _isLoading = true;
  List<Roadmap> _roadmaps = [];

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
      final roadmaps = await _roadmapService.getRoadmaps();
      setState(() {
        _roadmaps = roadmaps;
        _isLoading = false;
      });
    } catch (e) {
      print('Yol haritaları yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
      // Hata mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yol haritaları yüklenirken bir hata oluştu.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getCareerPathText(CareerPath path) {
    switch (path) {
      case CareerPath.networkSecurity:
        return 'Ağ Güvenliği';
      case CareerPath.applicationSecurity:
        return 'Uygulama Güvenliği';
      case CareerPath.cloudSecurity:
        return 'Bulut Güvenliği';
      case CareerPath.penetrationTesting:
        return 'Sızma Testi';
      case CareerPath.securityAnalyst:
        return 'Güvenlik Analisti';
      case CareerPath.incidentResponse:
        return 'Olay Müdahale';
      case CareerPath.cryptography:
        return 'Kriptografi';
      default:
        return 'Bilinmiyor';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kariyer Yol Haritaları'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRoadmaps,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _roadmaps.isEmpty
              ? const Center(
                  child: Text(
                    'Henüz yol haritası bulunmuyor.',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRoadmaps,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _roadmaps.length,
                    itemBuilder: (context, index) {
                      final roadmap = _roadmaps[index];
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
                            // Yol Haritası Görseli
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Resim
                                  Image.asset(
                                    roadmap.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade800,
                                        child: const Center(
                                          child: Icon(
                                            Icons.map,
                                            size: 50,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  // Koyulaştırıcı katman
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.7),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Kategori ve süre bilgisi
                                  Positioned(
                                    bottom: 16,
                                    left: 16,
                                    right: 16,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Kategori
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0, vertical: 4.0),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black54.withOpacity(0.7),
                                            borderRadius:
                                                BorderRadius.circular(4.0),
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                              width: 1.0,
                                            ),
                                          ),
                                          child: Text(
                                            roadmap.category,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12.0,
                                            ),
                                          ),
                                        ),
                                        // Tahmini süre
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0, vertical: 4.0),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black54.withOpacity(0.7),
                                            borderRadius:
                                                BorderRadius.circular(4.0),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${roadmap.estimatedDurationWeeks} hafta',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12.0,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Yol Haritası İçeriği
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Kariyer Yolu
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0, vertical: 4.0),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4.0),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Text(
                                      _getCareerPathText(roadmap.careerPath),
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  // Başlık
                                  Text(
                                    roadmap.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 12.0),
                                  // Açıklama
                                  Text(
                                    roadmap.description,
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
                                            '%${roadmap.progress}',
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
                                        value: roadmap.progress / 100,
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
                                  // Adım Sayısı ve Devam Et Butonu
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Adım sayısı
                                      Text(
                                        '${roadmap.steps.length} adım',
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      // Devam Et Butonu
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          // Yol haritası detay sayfasına git
                                          Navigator.pushNamed(
                                            context,
                                            '/roadmap/${roadmap.id}',
                                          );
                                        },
                                        icon: const Icon(Icons.map),
                                        label: Text(
                                          roadmap.progress > 0
                                              ? 'Devam Et'
                                              : 'Haritayı Görüntüle',
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0, vertical: 8.0),
                                        ),
                                      ),
                                    ],
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

class RoadmapDetailScreen extends StatelessWidget {
  final String roadmapId;

  const RoadmapDetailScreen({Key? key, required this.roadmapId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yol Haritası Detayı'),
      ),
      body: const Center(
        child: Text('Yol haritası detay sayfası henüz yapım aşamasında...'),
      ),
    );
  }
}
