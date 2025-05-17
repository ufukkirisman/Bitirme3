import 'package:flutter/material.dart';
import 'package:bitirme_3/services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bitirme_3/screens/modules_screen.dart';
import 'package:bitirme_3/screens/training_screen.dart';
import 'package:bitirme_3/screens/roadmap_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late TabController _tabController;
  final String userName = 'Kullanıcı';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userName = _authService.currentUser?.displayName ?? "Kullanıcı";

    return Scaffold(
      body: Column(
        children: [
          // Hoş geldin banner'ı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade700,
                  Colors.blue.shade500,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hoş Geldiniz,',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          Text(
                            userName,
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Admin paneli butonu
                          IconButton(
                            icon: const Icon(Icons.admin_panel_settings,
                                color: Colors.white),
                            onPressed: () {
                              Navigator.pushNamed(context, '/admin/login');
                            },
                            tooltip: 'Admin Paneli',
                          ),
                          // Çıkış butonu
                          IconButton(
                            icon: const Icon(Icons.exit_to_app,
                                color: Colors.white),
                            onPressed: () async {
                              await _authService.signOut();
                              if (mounted) {
                                Navigator.pushReplacementNamed(
                                    context, '/login');
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Siber güvenlik eğitimlerinize devam edin',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tab Bar
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withOpacity(0.7),
                    isScrollable: true,
                    tabs: [
                      Tab(
                        icon: const Icon(Icons.school),
                        text: 'Modüller',
                        iconMargin: const EdgeInsets.only(bottom: 4),
                      ),
                      Tab(
                        icon: const Icon(Icons.quiz),
                        text: 'Quizler',
                        iconMargin: const EdgeInsets.only(bottom: 4),
                      ),
                      Tab(
                        icon: const Icon(Icons.computer),
                        text: 'Simülasyonlar',
                        iconMargin: const EdgeInsets.only(bottom: 4),
                      ),
                      Tab(
                        icon: const Icon(Icons.book),
                        text: 'Eğitimler',
                        iconMargin: const EdgeInsets.only(bottom: 4),
                      ),
                      Tab(
                        icon: const Icon(Icons.map),
                        text: 'Yol Haritası',
                        iconMargin: const EdgeInsets.only(bottom: 4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Tab View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Modüller sekmesi
                const ModulesTabView(),

                // Quizler sekmesi
                QuizesTabView(),

                // Simülasyonlar sekmesi
                SimulationsTabView(),

                // Eğitimler sekmesi
                TrainingsTabView(),

                // Yol Haritası sekmesi
                RoadmapsTabView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Modüller sekmesi içeriği
class ModulesTabView extends StatelessWidget {
  const ModulesTabView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ModulesScreen();
  }
}

// Quizler sekmesi içeriği
class QuizesTabView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.quiz,
            size: 80,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          Text(
            'Quizleriniz',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Yakında bu bölümde tamamlamanız gereken quizler ve sınavlar listelenecek.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/modules');
            },
            icon: const Icon(Icons.school),
            label: const Text('Modüllere Git'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// Simülasyonlar sekmesi içeriği
class SimulationsTabView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
            'Simülasyonlar',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Siber güvenlik becerilerinizi pratik yaparak geliştirin. Simülasyonlar yakında burada olacak.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/modules');
            },
            icon: const Icon(Icons.school),
            label: const Text('Modüllere Git'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// Eğitimler sekmesi içeriği
class TrainingsTabView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const TrainingScreen();
  }
}

// Yol Haritası sekmesi içeriği
class RoadmapsTabView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const RoadmapScreen();
  }
}
