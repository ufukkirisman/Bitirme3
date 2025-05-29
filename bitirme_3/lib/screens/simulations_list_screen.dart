import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bitirme_3/models/simulation.dart' as app_models;
import 'package:bitirme_3/screens/simulation_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class SimulationsListScreen extends StatefulWidget {
  const SimulationsListScreen({Key? key}) : super(key: key);

  @override
  _SimulationsListScreenState createState() => _SimulationsListScreenState();
}

class _SimulationsListScreenState extends State<SimulationsListScreen> {
  bool _isLoading = true;
  List<app_models.Simulation> _simulations = [];
  String _errorMessage = '';
  // Tamamlanmış simülasyonların ID'lerini tutar
  Set<String> _completedSimulationIds = {};
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadSimulations();
  }

  Future<void> _loadSimulations() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });
      }

      // Kullanıcının tamamladığı simülasyonları getir
      await _loadCompletedSimulations();

      // Tüm simülasyonları getir
      final snapshot =
          await FirebaseFirestore.instance.collection('simulations').get();

      final simulations = snapshot.docs.map((doc) {
        return app_models.Simulation.fromMap(doc.data(), doc.id);
      }).toList();

      if (mounted) {
        setState(() {
          _simulations = simulations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Simülasyonlar yüklenirken hata oluştu: $e';
        });
      }
    }
  }

  // Kullanıcının tamamladığı simülasyonları yükler
  Future<void> _loadCompletedSimulations() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return;
      }

      // Yöntem 1: simulation_results koleksiyonundan kontrol et
      final resultsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('simulation_results')
          .where('completed', isEqualTo: true)
          .get();

      // Yöntem 2: progress koleksiyonundan kontrol et
      final progressSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .where('type', isEqualTo: 'simulation')
          .where('completed', isEqualTo: true)
          .get();

      // Yöntem 3: Kullanıcı dokümanından completedSimulations alanını kontrol et
      final userDoc = await _firestore.collection('users').doc(userId).get();
      List<String> completedFromUserDoc = [];

      if (userDoc.exists &&
          userDoc.data()?.containsKey('completedSimulations') == true) {
        completedFromUserDoc =
            List<String>.from(userDoc.data()?['completedSimulations'] ?? []);
      }

      // Tüm kaynaklardan gelen simülasyon ID'lerini birleştir
      Set<String> allCompletedIds = {};

      // Yöntem 1'den gelen ID'ler
      allCompletedIds.addAll(resultsSnapshot.docs
          .map((doc) => doc.data()['simulationId'] as String));

      // Yöntem 2'den gelen ID'ler
      allCompletedIds.addAll(
          progressSnapshot.docs.map((doc) => doc.data()['itemId'] as String));

      // Yöntem 3'ten gelen ID'ler
      allCompletedIds.addAll(completedFromUserDoc);

      if (mounted) {
        setState(() {
          _completedSimulationIds = allCompletedIds;
        });
      }

      print('Tamamlanmış simülasyon sayısı: ${_completedSimulationIds.length}');
      if (_completedSimulationIds.isNotEmpty) {
        print(
            'Tamamlanan simülasyonlar: ${_completedSimulationIds.join(", ")}');
      }
    } catch (e) {
      print('Tamamlanmış simülasyonlar yüklenirken hata: $e');
    }
  }

  // Belirli bir simülasyonun tamamlanıp tamamlanmadığını kontrol eder
  bool _isSimulationCompleted(String simulationId) {
    return _completedSimulationIds.contains(simulationId);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSimulations,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_simulations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.computer,
              size: 80,
              color: Colors.purple,
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz Simülasyon Yok',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Şu anda mevcut simülasyon bulunmamaktadır.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSimulations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _simulations.length,
        itemBuilder: (context, index) {
          final simulation = _simulations[index];
          final bool isCompleted = _isSimulationCompleted(simulation.id);

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            // Tamamlanmış simülasyonları belirtmek için kenarlık ekle
            shape: isCompleted
                ? RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Colors.green, width: 2),
                  )
                : null,
            child: InkWell(
              onTap: () {
                // Eğer tamamlanmış simülasyon ise tekrar yapmasına izin verme
                if (isCompleted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bu simülasyonu zaten tamamladınız!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SimulationScreen(simulationId: simulation.id),
                  ),
                ).then((_) {
                  // Simülasyon ekranından dönüldüğünde listeyi yenile
                  _loadSimulations();
                });
              },
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF9C27B0).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isCompleted
                                    ? Icons.check_circle
                                    : Icons.computer,
                                color: isCompleted
                                    ? Colors.green
                                    : const Color(0xFF9C27B0),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    simulation.title,
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isCompleted ? Colors.green : null,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    simulation.description,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF101823),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF9C27B0),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${simulation.steps.length} Adım',
                                style: const TextStyle(
                                  color: Color(0xFF9C27B0),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF101823),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFFF9800),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Color(0xFFFF9800),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Seviye ${simulation.difficultyLevel}',
                                    style: const TextStyle(
                                      color: Color(0xFFFF9800),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF101823),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF00BCD4),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _getSimulationTypeText(simulation.type),
                                style: const TextStyle(
                                  color: Color(0xFF00BCD4),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            // Tamamlanmış simülasyon durumunu göster
                            if (isCompleted)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF101823),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.green,
                                    width: 1,
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Tamamlandı',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Tamamlanmış rozeti
                  if (isCompleted)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: Tooltip(
                        message: 'Bu simülasyon tamamlandı',
                        child: Icon(
                          Icons.verified,
                          color: Colors.green,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getSimulationTypeText(app_models.SimulationType type) {
    switch (type) {
      case app_models.SimulationType.networkAnalysis:
        return 'Ağ Analizi';
      case app_models.SimulationType.penetrationTesting:
        return 'Sızma Testi';
      case app_models.SimulationType.forensicAnalysis:
        return 'Adli Analiz';
      case app_models.SimulationType.malwareAnalysis:
        return 'Zararlı Yazılım Analizi';
      case app_models.SimulationType.cryptography:
        return 'Kriptografi';
      case app_models.SimulationType.socialEngineering:
        return 'Sosyal Mühendislik';
      default:
        return 'Diğer';
    }
  }
}
