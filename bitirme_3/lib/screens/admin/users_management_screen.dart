import 'package:flutter/material.dart';
import 'package:bitirme_3/models/admin.dart';
import 'package:bitirme_3/services/admin_service.dart';
import 'package:bitirme_3/screens/admin/user_detail_screen.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({Key? key}) : super(key: key);

  @override
  _UsersManagementScreenState createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  List<UserSummary> _users = [];
  String _searchQuery = '';
  List<UserSummary> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _adminService.getAllUsers();
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      print('Kullanıcılar yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
      // Hata mesajı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kullanıcılar yüklenirken bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((user) {
          return user.displayName.toLowerCase().contains(query.toLowerCase()) ||
              user.email.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _toggleUserStatus(UserSummary user) async {
    try {
      final success =
          await _adminService.toggleUserStatus(user.id, !user.isActive);
      if (success) {
        // Kullanıcı listesini yeniden yükle
        await _loadUsers();
      } else {
        // Hata mesajı göster
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kullanıcı durumu değiştirilemedi.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Kullanıcı durumu değiştirme hatası: $e');
      // Hata mesajı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kullanıcı durumu değiştirme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewUserDetails(UserSummary user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailScreen(userId: user.id),
      ),
    ).then((_) {
      // Kullanıcı detay sayfasından döndüğünde listeyi güncelle
      _loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Yönetimi'),
        backgroundColor: Colors.blueGrey.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama Çubuğu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Kullanıcı Ara',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _filterUsers('');
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
              ),
              onChanged: _filterUsers,
            ),
          ),
          // Kullanıcı Listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? const Center(
                        child: Text(
                          'Kullanıcı bulunamadı.',
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blueGrey.shade700,
                                child: Text(
                                  user.displayName.isNotEmpty
                                      ? user.displayName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                user.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(user.email),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Aktif/Pasif durum
                                  Switch(
                                    value: user.isActive,
                                    onChanged: (value) =>
                                        _toggleUserStatus(user),
                                    activeColor: Colors.green,
                                  ),
                                  // Detaylar butonu
                                  IconButton(
                                    icon: const Icon(Icons.info_outline),
                                    onPressed: () => _viewUserDetails(user),
                                    tooltip: 'Detaylar',
                                  ),
                                ],
                              ),
                              onTap: () => _viewUserDetails(user),
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
