import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bitirme_3/services/database_service.dart';

class LessonScreen extends StatefulWidget {
  final String lessonId;
  final dynamic arguments;

  const LessonScreen({
    Key? key,
    required this.lessonId,
    this.arguments,
  }) : super(key: key);

  @override
  _LessonScreenState createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _lessonData;
  String _errorMessage = '';
  bool _isLessonCompleted = false;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _fetchLessonDetails();
  }

  Future<void> _fetchLessonDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Ders verilerini DatabaseService üzerinden al
      final lessonDoc = await _databaseService.getLessonById(widget.lessonId);

      if (lessonDoc == null || !lessonDoc.exists) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Ders bulunamadı';
        });
        return;
      }

      // Kullanıcının bu dersi tamamlayıp tamamlamadığını kontrol et
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final userProgressDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('progress')
            .doc(widget.lessonId)
            .get();

        _isLessonCompleted = userProgressDoc.exists &&
            userProgressDoc.data()?['completed'] == true;
      }

      setState(() {
        _lessonData = lessonDoc.data() as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Ders detayları yüklenirken hata oluştu: $e';
      });
    }
  }

  Future<void> _markLessonAsCompleted() async {
    try {
      String? moduleId;
      if (widget.arguments != null && widget.arguments is Map) {
        moduleId = widget.arguments['moduleId'];
      }

      if (moduleId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Modül bilgisi bulunamadı'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // DatabaseService kullanarak dersi tamamlandı olarak işaretle
      await _databaseService.markLessonAsCompleted(widget.lessonId, moduleId);

      setState(() {
        _isLessonCompleted = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ders tamamlandı olarak işaretlendi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _lessonData?['title'] ?? 'Ders Detayı',
        ),
        actions: [
          if (_isLessonCompleted)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Icon(Icons.check_circle, color: Colors.green),
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar:
          !_isLoading && _lessonData != null && !_isLessonCompleted
              ? BottomAppBar(
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: ElevatedButton(
                      onPressed: _markLessonAsCompleted,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'DERSİ TAMAMLA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                )
              : null,
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
              onPressed: _fetchLessonDetails,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_lessonData == null) {
      return const Center(
        child: Text('Ders verileri bulunamadı'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst bilgi paneli
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF101823), Color(0xFF162435)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ders başlığı
                Text(
                  _lessonData!['title'] ?? 'İsimsiz Ders',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00FF8F),
                  ),
                ),

                const SizedBox(height: 12),

                // Ders meta bilgileri (süre, zorluk vb)
                Row(
                  children: [
                    const Icon(Icons.timer, size: 16, color: Color(0xFF00CCFF)),
                    const SizedBox(width: 4),
                    Text(
                      '${_lessonData!['duration'] ?? 0} dakika',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    if (_lessonData?['difficulty'] != null) ...[
                      const Icon(Icons.trending_up,
                          size: 16, color: Color(0xFF00CCFF)),
                      const SizedBox(width: 4),
                      Text(
                        _getDifficultyText(_lessonData!['difficulty']),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                    if (_isLessonCompleted) ...[
                      const Spacer(),
                      const Icon(Icons.check_circle,
                          color: Color(0xFF00FF8F), size: 16),
                      const SizedBox(width: 4),
                      const Text(
                        'Tamamlandı',
                        style: TextStyle(color: Color(0xFF00FF8F)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Ders video içeriği (varsa)
          if (_lessonData?['videoUrl'] != null)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0F1923),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1C2D40)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  size: 70,
                  color: Color(0xFF00CCFF),
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Ders içeriği başlığı
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF00AACC).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'İÇERİK',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00CCFF),
                letterSpacing: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Ders içeriği
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1923),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1C2D40)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sahte kod blokları veya kod örnekleri için
                if (_lessonData?['content']?.contains('```') ?? false) ...[
                  // İçeriği kod bloklarına ayırma ve formatlama kodları buraya gelebilir
                  Text(
                    _lessonData!['content'] ?? 'İçerik bulunmamaktadır.',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.white,
                    ),
                  ),
                ] else
                  Text(
                    _lessonData!['content'] ?? 'İçerik bulunmamaktadır.',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Uyarılar ve ipuçları (varsa)
          if (_lessonData?['tips'] != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'İPUÇLARI',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF9800),
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1500).withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFFFF9800).withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Color(0xFFFF9800),
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _lessonData!['tips'],
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Dersle ilgili ek kaynaklar (varsa)
          if (_lessonData?['resources'] != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF00AACC).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'EK KAYNAKLAR',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00CCFF),
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ..._buildResourcesList(_lessonData!['resources']),
          ],

          const SizedBox(height: 40),

          // Tamamlandı butonu
          if (!_isLessonCompleted)
            Padding(
              padding: const EdgeInsets.only(top: 20.0, bottom: 40.0),
              child: Center(
                child: ElevatedButton(
                  onPressed: _markLessonAsCompleted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00AACC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('DERSİ TAMAMLA'),
                      SizedBox(width: 8),
                      Icon(Icons.check_circle_outline, size: 20),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getDifficultyText(int difficulty) {
    switch (difficulty) {
      case 1:
        return 'Başlangıç';
      case 2:
        return 'Kolay';
      case 3:
        return 'Orta';
      case 4:
        return 'Zor';
      case 5:
        return 'İleri';
      default:
        return 'Bilinmiyor';
    }
  }

  List<Widget> _buildResourcesList(List<dynamic> resources) {
    return resources.map<Widget>((resource) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Card(
          color: const Color(0xFF0F1923),
          elevation: 4,
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00AACC).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.link, color: Color(0xFF00CCFF)),
            ),
            title: Text(
              resource['title'] ?? 'Kaynak',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              resource['description'] ?? '',
              style: TextStyle(color: Colors.grey.shade400),
            ),
            trailing: const Icon(Icons.open_in_new, color: Color(0xFF00CCFF)),
            onTap: () {
              // URL'yi aç
              // url_launcher paketi ile açılabilir
            },
          ),
        ),
      );
    }).toList();
  }
}
