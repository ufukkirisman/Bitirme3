import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bitirme_3/models/module.dart';
import 'package:bitirme_3/services/module_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ModuleDetailScreen extends StatefulWidget {
  final String moduleId;

  const ModuleDetailScreen({
    Key? key,
    required this.moduleId,
  }) : super(key: key);

  @override
  _ModuleDetailScreenState createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _moduleData;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchModuleDetails();
  }

  Future<void> _fetchModuleDetails() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });
      }

      final moduleDoc = await FirebaseFirestore.instance
          .collection('modules')
          .doc(widget.moduleId)
          .get();

      if (!moduleDoc.exists) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Modül bulunamadı';
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _moduleData = moduleDoc.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Modül detayları yüklenirken hata oluştu: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _moduleData?['title'] ?? 'Modül Detayı',
        ),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchModuleDetails,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_moduleData == null) {
      return const Center(
        child: Text('Modül verileri bulunamadı'),
      );
    }

    // İçerik listesi
    List<dynamic> contentList = _moduleData?['contents'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modül resmi
          if (_moduleData?['imageUrl'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _moduleData!['imageUrl'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.blue.shade100,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 20),

          // Modül başlığı
          Text(
            _moduleData!['title'] ?? 'İsimsiz Modül',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          // Modül açıklaması
          Text(
            _moduleData!['description'] ?? 'Açıklama yok',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 24),

          // İlerleme durumu
          if (_moduleData?['progress'] != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'İlerleme',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text('${_moduleData?['progress']}%'),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_moduleData?['progress'] as num) / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    (_moduleData?['progress'] as num) > 0
                        ? Colors.green
                        : Colors.blue.shade300,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  minHeight: 10,
                ),
                const SizedBox(height: 24),
              ],
            ),

          // İçerik listesi başlığı
          const Text(
            'İçerikler',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // İçerik listesi boşsa
          if (contentList.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('Bu modül için içerik bulunmamaktadır'),
              ),
            ),

          // İçerik listesi
          ...contentList.map((content) => _buildContentItem(content)).toList(),
        ],
      ),
    );
  }

  Widget _buildContentItem(Map<String, dynamic> content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          // İçerik tipine göre yönlendirme
          if (content['type'] == 'lesson') {
            Navigator.pushNamed(
              context,
              '/lesson/${content['id']}',
              arguments: {
                'moduleId': widget.moduleId,
                'lessonId': content['id'],
              },
            );
          } else if (content['type'] == 'quiz') {
            Navigator.pushNamed(
              context,
              '/quiz/${content['id']}',
              arguments: content['id'],
            );
          } else if (content['type'] == 'simulation') {
            Navigator.pushNamed(
              context,
              '/simulation/${content['id']}',
              arguments: content['id'],
            );
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // İçerik tipine göre ikon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getContentColor(content['type']),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    _getContentIcon(content['type']),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // İçerik bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content['title'] ?? 'İsimsiz İçerik',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (content['description'] != null)
                      Text(
                        content['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Tamamlandı işareti
              if (content['completed'] == true)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // İçerik tipine göre ikon seçme
  IconData _getContentIcon(String? type) {
    switch (type) {
      case 'lesson':
        return Icons.article;
      case 'quiz':
        return Icons.quiz;
      case 'simulation':
        return Icons.science;
      default:
        return Icons.description;
    }
  }

  // İçerik tipine göre renk seçme
  Color _getContentColor(String? type) {
    switch (type) {
      case 'lesson':
        return Colors.blue;
      case 'quiz':
        return Colors.orange;
      case 'simulation':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
