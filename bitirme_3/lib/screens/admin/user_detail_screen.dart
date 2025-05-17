import 'package:flutter/material.dart';
import 'package:bitirme_3/services/admin_service.dart';
import 'package:intl/intl.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;

  const UserDetailScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _UserDetailScreenState createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  Map<String, dynamic>? _userDetails;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userDetails = await _adminService.getUserDetails(widget.userId);
      setState(() {
        _userDetails = userDetails;
        _isLoading = false;
      });
    } catch (e) {
      print('Kullanıcı detayları yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
      // Hata mesajı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Kullanıcı detayları yüklenirken bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleUserStatus() async {
    if (_userDetails == null) return;

    final isActive = _userDetails!['userInfo']['isActive'] ?? true;
    try {
      final success =
          await _adminService.toggleUserStatus(widget.userId, !isActive);
      if (success) {
        // Kullanıcı detaylarını yeniden yükle
        await _loadUserDetails();
        // Başarı mesajı göster
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Kullanıcı ${!isActive ? 'aktifleştirildi' : 'pasifleştirildi'}.'),
              backgroundColor: Colors.green,
            ),
          );
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Detayları'),
        backgroundColor: Colors.blueGrey.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserDetails,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userDetails == null
              ? const Center(
                  child: Text(
                    'Kullanıcı detayları bulunamadı.',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kullanıcı başlık kartı
                      Card(
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blueGrey.shade700,
                                radius: 50,
                                child: Text(
                                  _userDetails!['userInfo']['displayName'] !=
                                              null &&
                                          _userDetails!['userInfo']
                                                  ['displayName']
                                              .toString()
                                              .isNotEmpty
                                      ? _userDetails!['userInfo']['displayName']
                                          .toString()[0]
                                          .toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16.0),
                              Text(
                                _userDetails!['userInfo']['displayName'] ??
                                    'İsimsiz Kullanıcı',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                _userDetails!['userInfo']['email'] ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Durum: ${_userDetails!['userInfo']['isActive'] == true ? 'Aktif' : 'Pasif'}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _userDetails!['userInfo']
                                                  ['isActive'] ==
                                              true
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 16.0),
                                  ElevatedButton(
                                    onPressed: _toggleUserStatus,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _userDetails!['userInfo']
                                                  ['isActive'] ==
                                              true
                                          ? Colors.red
                                          : Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text(_userDetails!['userInfo']
                                                ['isActive'] ==
                                            true
                                        ? 'Pasifleştir'
                                        : 'Aktifleştir'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      // Kullanıcı detay kartları
                      Card(
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bilgiler',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(),
                              _buildInfoRow(
                                'Son Giriş',
                                _userDetails!['userInfo']['lastLogin'] != null
                                    ? DateFormat('dd.MM.yyyy HH:mm').format(
                                        DateTime.parse(_userDetails!['userInfo']
                                                ['lastLogin']
                                            .toDate()
                                            .toString()))
                                    : 'Hiç giriş yapmadı',
                              ),
                              _buildInfoRow(
                                'Kayıt Tarihi',
                                _userDetails!['userInfo']['createdAt'] != null
                                    ? DateFormat('dd.MM.yyyy HH:mm').format(
                                        DateTime.parse(_userDetails!['userInfo']
                                                ['createdAt']
                                            .toDate()
                                            .toString()))
                                    : 'Bilinmiyor',
                              ),
                              _buildInfoRow(
                                'Telefon',
                                _userDetails!['userInfo']['phoneNumber'] ??
                                    'Belirtilmemiş',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      // İlerleme Özeti
                      Card(
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'İlerleme Durumu',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(),
                              _buildInfoRow(
                                'Tamamlanan İçerikler',
                                (_userDetails!['progress'] as List<dynamic>?)
                                        ?.length
                                        .toString() ??
                                    '0',
                              ),
                              _buildInfoRow(
                                'Tamamlanan Quizler',
                                (_userDetails!['quizResults'] as List<dynamic>?)
                                        ?.length
                                        .toString() ??
                                    '0',
                              ),
                              _buildInfoRow(
                                'Tamamlanan Simülasyonlar',
                                (_userDetails!['simulationResults']
                                            as List<dynamic>?)
                                        ?.length
                                        .toString() ??
                                    '0',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      // Quiz Sonuçları
                      if ((_userDetails!['quizResults'] as List<dynamic>?)
                              ?.isNotEmpty ??
                          false)
                        Card(
                          elevation: 4.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Quiz Sonuçları',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Divider(),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: (_userDetails!['quizResults']
                                          as List<dynamic>)
                                      .length,
                                  itemBuilder: (context, index) {
                                    final quizResult =
                                        (_userDetails!['quizResults']
                                            as List<dynamic>)[index];
                                    return ListTile(
                                      title: Text(
                                          'Quiz ID: ${quizResult['quizId']}'),
                                      subtitle: Text(
                                          'Puan: ${quizResult['score']}/${quizResult['totalPoints']} (${quizResult['percentage']}%)'),
                                      trailing: Icon(
                                        quizResult['passed'] == true
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: quizResult['passed'] == true
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
