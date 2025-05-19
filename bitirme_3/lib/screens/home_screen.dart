import 'package:flutter/material.dart';
import 'package:bitirme_3/services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bitirme_3/screens/modules_screen.dart';
import 'package:bitirme_3/screens/training_screen.dart';
import 'package:bitirme_3/screens/roadmap_screen.dart';
import 'package:bitirme_3/screens/quizzes_list_screen.dart';
import 'package:bitirme_3/screens/simulations_list_screen.dart';

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
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F1923),
                  Color(0xFF162435),
                  Color(0xFF1C2D40),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 15,
                  offset: Offset(0, 5),
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
                              color: Colors.white.withOpacity(0.7),
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            userName,
                            style: GoogleFonts.poppins(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color:
                                      const Color(0xFF00CCFF).withOpacity(0.3),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Admin paneli butonu
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.admin_panel_settings,
                                  color: Color(0xFF00CCFF), size: 28),
                              onPressed: () {
                                Navigator.pushNamed(context, '/admin/login');
                              },
                              tooltip: 'Admin Paneli',
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Çıkış butonu
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.exit_to_app,
                                  color: Color(0xFFFF5252), size: 28),
                              onPressed: () async {
                                await _authService.signOut();
                                if (mounted) {
                                  Navigator.pushReplacementNamed(
                                      context, '/login');
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF00FF8F).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Siber güvenlik eğitimlerinize devam edin',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF00FF8F),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tab Bar
                  Container(
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF101823),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF1C2D40),
                        width: 1,
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFF00CCFF),
                      indicatorWeight: 3,
                      labelColor: const Color(0xFF00CCFF),
                      unselectedLabelColor: Colors.white.withOpacity(0.6),
                      labelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      unselectedLabelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      indicatorSize: TabBarIndicatorSize.label,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 0),
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
                  ),
                ],
              ),
            ),
          ),

          // Tab View
          Expanded(
            child: Container(
              color: const Color(
                  0xFF0A121B), // Arka plan rengini daha koyu bir tona ayarla
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
    return const QuizzesListScreen();
  }
}

// Simülasyonlar sekmesi içeriği
class SimulationsTabView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SimulationsListScreen();
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
