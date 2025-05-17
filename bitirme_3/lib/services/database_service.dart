import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  // Singleton örneği oluştur
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcı ID'sini alma
  String? get currentUserId => _auth.currentUser?.uid;

  // ============ MODÜLLER ============

  // Tüm modülleri getir
  Future<List<DocumentSnapshot>> getModules() async {
    try {
      final snapshot = await _db
          .collection('modules')
          .orderBy('order', descending: false)
          .get();
      return snapshot.docs;
    } catch (e) {
      print('Modüller getirilirken hata: $e');
      return [];
    }
  }

  // Modül detayını getir
  Future<DocumentSnapshot?> getModuleById(String moduleId) async {
    try {
      return await _db.collection('modules').doc(moduleId).get();
    } catch (e) {
      print('Modül detayı getirme hatası: $e');
      return null;
    }
  }

  // Modül ilerleme durumunu güncelle
  Future<void> updateModuleProgress(String moduleId, int progress) async {
    try {
      if (currentUserId == null) return;

      // Önce kullanıcının modül ilerleme verilerini al
      await _db.collection('modules').doc(moduleId).update({
        'progress': progress,
      });

      // Kullanıcının ilerleme kaydını güncelle
      await _db
          .collection('users')
          .doc(currentUserId)
          .collection('module_progress')
          .doc(moduleId)
          .set({
        'progress': progress,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Modül ilerleme durumu güncelleme hatası: $e');
    }
  }

  // ============ İÇERİK ÖĞELERİ ============

  // Ders İçeriği
  Future<DocumentSnapshot?> getLessonById(String lessonId) async {
    try {
      return await _db.collection('lessons').doc(lessonId).get();
    } catch (e) {
      print('Ders getirme hatası: $e');
      return null;
    }
  }

  // Dersi tamamlandı olarak işaretle
  Future<void> markLessonAsCompleted(String lessonId, String moduleId) async {
    try {
      if (currentUserId == null) return;

      // Kullanıcının ilerleme kaydını güncelle
      await _db
          .collection('users')
          .doc(currentUserId)
          .collection('progress')
          .doc(lessonId)
          .set({
        'completed': true,
        'completedAt': FieldValue.serverTimestamp(),
        'moduleId': moduleId,
      });

      // Modül ilerlemesini hesapla ve güncelle
      await _recalculateModuleProgress(moduleId);
    } catch (e) {
      print('Ders tamamlama hatası: $e');
    }
  }

  // Quiz İçeriği
  Future<DocumentSnapshot?> getQuizById(String quizId) async {
    try {
      return await _db.collection('quizzes').doc(quizId).get();
    } catch (e) {
      print('Quiz getirme hatası: $e');
      return null;
    }
  }

  // Quiz sonucunu kaydet
  Future<void> saveQuizResult(
      String quizId, String moduleId, int score, int totalPoints) async {
    try {
      if (currentUserId == null) return;

      final percentage = (score / totalPoints) * 100;
      final isPassed = percentage >= 70;

      await _db
          .collection('users')
          .doc(currentUserId)
          .collection('quiz_results')
          .doc(quizId)
          .set({
        'quizId': quizId,
        'moduleId': moduleId,
        'score': score,
        'totalPoints': totalPoints,
        'percentage': percentage,
        'passed': isPassed,
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Quiz başarılı ise ilerleme olarak işaretle
      if (isPassed) {
        await _db
            .collection('users')
            .doc(currentUserId)
            .collection('progress')
            .doc(quizId)
            .set({
          'completed': true,
          'completedAt': FieldValue.serverTimestamp(),
          'moduleId': moduleId,
        });

        // Modül ilerlemesini güncelle
        await _recalculateModuleProgress(moduleId);
      }
    } catch (e) {
      print('Quiz sonucu kaydetme hatası: $e');
    }
  }

  // Simülasyon İçeriği
  Future<DocumentSnapshot?> getSimulationById(String simulationId) async {
    try {
      return await _db.collection('simulations').doc(simulationId).get();
    } catch (e) {
      print('Simülasyon getirme hatası: $e');
      return null;
    }
  }

  // Simülasyon tamamlama durumunu kaydet
  Future<void> saveSimulationResult(
      String simulationId, String moduleId) async {
    try {
      if (currentUserId == null) return;

      await _db
          .collection('users')
          .doc(currentUserId)
          .collection('simulation_results')
          .doc(simulationId)
          .set({
        'simulationId': simulationId,
        'moduleId': moduleId,
        'completed': true,
        'completedAt': FieldValue.serverTimestamp(),
      });

      // İlerleme olarak işaretle
      await _db
          .collection('users')
          .doc(currentUserId)
          .collection('progress')
          .doc(simulationId)
          .set({
        'completed': true,
        'completedAt': FieldValue.serverTimestamp(),
        'moduleId': moduleId,
      });

      // Modül ilerlemesini güncelle
      await _recalculateModuleProgress(moduleId);
    } catch (e) {
      print('Simülasyon sonucu kaydetme hatası: $e');
    }
  }

  // ============ KULLANICI PROFİLİ ============

  // Kullanıcı profilini getir
  Future<DocumentSnapshot?> getUserProfile() async {
    try {
      if (currentUserId == null) return null;
      return await _db.collection('users').doc(currentUserId).get();
    } catch (e) {
      print('Kullanıcı profili getirme hatası: $e');
      return null;
    }
  }

  // Kullanıcı profilini güncelle
  Future<void> updateUserProfile(Map<String, dynamic> userData) async {
    try {
      if (currentUserId == null) return;
      await _db
          .collection('users')
          .doc(currentUserId)
          .set(userData, SetOptions(merge: true));
    } catch (e) {
      print('Kullanıcı profili güncelleme hatası: $e');
    }
  }

  // ============ YARDIMCI METODLAR ============

  // Modül ilerleme durumunu yeniden hesapla
  Future<void> _recalculateModuleProgress(String moduleId) async {
    try {
      if (currentUserId == null) return;

      // Modül içeriklerini getir
      final moduleDoc = await _db.collection('modules').doc(moduleId).get();
      final List<dynamic> contents = moduleDoc.data()?['contents'] ?? [];

      if (contents.isEmpty) return;

      // Kullanıcının ilerleme verilerini getir
      final progressQuery = await _db
          .collection('users')
          .doc(currentUserId)
          .collection('progress')
          .where('moduleId', isEqualTo: moduleId)
          .get();

      // İlerleme durumunu hesapla
      final completedContents = <String>{};
      for (final doc in progressQuery.docs) {
        if (doc.data()['completed'] == true) {
          completedContents.add(doc.id);
        }
      }

      // Tamamlanan içerik sayılarını hesapla
      int totalContents = contents.length;
      int completedCount = 0;

      for (final content in contents) {
        final contentId = content['id'];
        if (completedContents.contains(contentId)) {
          completedCount++;
        }
      }

      // İlerleme yüzdesini hesapla ve güncelle
      final progress = totalContents > 0
          ? (completedCount / totalContents * 100).round()
          : 0;

      await updateModuleProgress(moduleId, progress);
    } catch (e) {
      print('Modül ilerleme hesaplama hatası: $e');
    }
  }

  // Kullanıcının tüm modüllerdeki ilerleme durumunu yeniden hesapla
  Future<void> recalculateAllModuleProgress() async {
    try {
      if (currentUserId == null) return;

      final modules = await getModules();
      for (final module in modules) {
        await _recalculateModuleProgress(module.id);
      }
    } catch (e) {
      print('Tüm modül ilerlemelerini hesaplama hatası: $e');
    }
  }
}
