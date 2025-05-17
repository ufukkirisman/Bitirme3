import 'package:flutter/material.dart';
import 'package:bitirme_3/models/admin.dart';
import 'package:bitirme_3/services/admin_service.dart';
import 'package:bitirme_3/screens/admin/users_management_screen.dart';
import 'package:bitirme_3/screens/admin/modules_management_screen.dart';
import 'package:bitirme_3/screens/admin/quizzes_management_screen.dart';
import 'package:bitirme_3/screens/admin/simulations_management_screen.dart';
import 'package:bitirme_3/screens/admin/trainings_management_screen.dart';
import 'package:bitirme_3/screens/admin/roadmaps_management_screen.dart';

class AdminDashboard extends StatefulWidget {
  final Admin admin;

  const AdminDashboard({Key? key, required this.admin}) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminService _adminService = AdminService();
  bool _isLoading = false;

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });

    await _adminService.adminLogout();

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/admin/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Paneli'),
        backgroundColor: Colors.blueGrey.shade800,
        actions: [
          IconButton(
            icon: _isLoading
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2.0,
                  )
                : const Icon(Icons.exit_to_app),
            onPressed: _isLoading ? null : _logout,
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blueGrey.shade900,
              Colors.blueGrey.shade800,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Admin bilgileri
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: 4.0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blueGrey.shade700,
                            radius: 30,
                            child: Text(
                              widget.admin.name.isNotEmpty
                                  ? widget.admin.name[0].toUpperCase()
                                  : 'A',
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.admin.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  widget.admin.email,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      const Text(
                        'İzinler:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: widget.admin.permissions.map((permission) {
                          return Chip(
                            label: Text(_getPermissionText(permission)),
                            backgroundColor: Colors.blueGrey.shade700,
                            labelStyle: const TextStyle(color: Colors.white),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              const Text(
                'Yönetim Panelleri',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16.0),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  children: [
                    // Kullanıcı Yönetimi
                    _buildAdminTile(
                      title: 'Kullanıcı Yönetimi',
                      icon: Icons.people,
                      color: Colors.blue,
                      permission: AdminPermission.viewUsers,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UsersManagementScreen(),
                          ),
                        );
                      },
                    ),
                    // Modül Yönetimi
                    _buildAdminTile(
                      title: 'Modül Yönetimi',
                      icon: Icons.school,
                      color: Colors.green,
                      permission: AdminPermission.manageModules,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ModulesManagementScreen(),
                          ),
                        );
                      },
                    ),
                    // Quiz Yönetimi
                    _buildAdminTile(
                      title: 'Quiz Yönetimi',
                      icon: Icons.quiz,
                      color: Colors.orange,
                      permission: AdminPermission.manageQuizzes,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const QuizzesManagementScreen(),
                          ),
                        );
                      },
                    ),
                    // Simülasyon Yönetimi
                    _buildAdminTile(
                      title: 'Simülasyon Yönetimi',
                      icon: Icons.computer,
                      color: Colors.purple,
                      permission: AdminPermission.manageSimulations,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const SimulationsManagementScreen(),
                          ),
                        );
                      },
                    ),
                    // Eğitim Yönetimi
                    _buildAdminTile(
                      title: 'Eğitim Yönetimi',
                      icon: Icons.book,
                      color: Colors.red,
                      permission: AdminPermission.manageTrainings,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const TrainingsManagementScreen(),
                          ),
                        );
                      },
                    ),
                    // Yol Haritası Yönetimi
                    _buildAdminTile(
                      title: 'Yol Haritası Yönetimi',
                      icon: Icons.map,
                      color: Colors.teal,
                      permission: AdminPermission.manageRoadmaps,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const RoadmapsManagementScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminTile({
    required String title,
    required IconData icon,
    required Color color,
    required AdminPermission permission,
    required VoidCallback onTap,
  }) {
    final bool hasPermission = widget.admin.hasPermission(permission);

    return InkWell(
      onTap: hasPermission ? onTap : null,
      borderRadius: BorderRadius.circular(16.0),
      child: Opacity(
        opacity: hasPermission ? 1.0 : 0.5,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 4.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: color,
                ),
                const SizedBox(height: 16.0),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (!hasPermission)
                  const Text(
                    '(İzin Yok)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getPermissionText(AdminPermission permission) {
    switch (permission) {
      case AdminPermission.viewUsers:
        return 'Kullanıcıları Görüntüleme';
      case AdminPermission.manageUsers:
        return 'Kullanıcı Yönetimi';
      case AdminPermission.manageModules:
        return 'Modül Yönetimi';
      case AdminPermission.manageQuizzes:
        return 'Quiz Yönetimi';
      case AdminPermission.manageSimulations:
        return 'Simülasyon Yönetimi';
      case AdminPermission.manageTrainings:
        return 'Eğitim Yönetimi';
      case AdminPermission.manageRoadmaps:
        return 'Yol Haritası Yönetimi';
      case AdminPermission.superAdmin:
        return 'Süper Admin';
      default:
        return 'Bilinmeyen İzin';
    }
  }
}
