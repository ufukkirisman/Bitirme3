import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bitirme_3/models/admin.dart';
import 'package:bitirme_3/models/module.dart';
import 'package:bitirme_3/models/quiz.dart';
import 'package:bitirme_3/models/simulation.dart';
import 'package:bitirme_3/models/training.dart';
import 'package:bitirme_3/models/roadmap.dart';

class AdminService {
  // Singleton pattern
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Admin kullanıcısını kontrol et
  Future<Admin?> checkAdminStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      final adminDoc = await _db.collection('admins').doc(user.uid).get();
      if (!adminDoc.exists) {
        return null;
      }

      return Admin.fromMap(adminDoc.data()!, adminDoc.id);
    } catch (e) {
      print('Admin kontrolü hatası: $e');
      return null;
    }
  }

  // Admin kaydını doğrula ve düzelt
  Future<bool> validateAndFixAdminRecord(
      String uid, String email, String name) async {
    try {
      print('Admin kaydı doğrulanıyor ve düzeltiliyor. UID: $uid');
      final adminDoc = await _db.collection('admins').doc(uid).get();

      if (!adminDoc.exists) {
        // Admin kaydı yok, yeni bir kayıt oluştur
        print('Admin kaydı bulunamadı, yeni oluşturuluyor');
        await _db.collection('admins').doc(uid).set({
          'email': email,
          'name': name,
          'permissions':
              'superAdmin', // Tek bir string olarak superAdmin değeri
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
        print('Yeni admin kaydı oluşturuldu (string permissions ile)');
        return true;
      } else {
        // Admin kaydı var, gerekirse güncelle
        print('Mevcut admin kaydı bulundu: ${adminDoc.data()}');

        // Eksik alanları kontrol et ve güncelle
        Map<String, dynamic> updates = {};
        final data = adminDoc.data();

        if (data == null) {
          print('Admin belgesi var ama veri yok!');
          return false;
        }

        // Permissions alanını kontrol et
        final permissions = data['permissions'];
        if (permissions == null) {
          // Permissions yok, string olarak ekle
          updates['permissions'] = 'superAdmin';
          print('Permissions eksik, superAdmin olarak ayarlanacak');
        } else if (permissions is List) {
          // Permissions liste ise, string'e dönüştür
          updates['permissions'] = 'superAdmin';
          print(
              'Permissions liste formatında, superAdmin string formatına dönüştürülecek');
        }

        if (data['createdAt'] == null) {
          updates['createdAt'] = FieldValue.serverTimestamp();
          print('Oluşturma tarihi güncellenecek');
        }

        if (updates.isNotEmpty) {
          await _db.collection('admins').doc(uid).update(updates);
          print('Admin kaydı güncellendi');
        } else {
          print('Güncelleme gerektiren bir alan bulunamadı');
        }

        return true;
      }
    } catch (e) {
      print('Admin kaydı doğrulanırken hata: $e');
      return false;
    }
  }

  // Admin girişi yap
  Future<Admin?> adminLogin(String email, String password) async {
    try {
      print('Admin giriş denemesi: $email');
      // Önce Firebase Auth ile giriş yap
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        print('Firebase Auth: Kullanıcı null döndü');
        return null;
      }

      print('Firebase Auth başarılı, UID: ${userCredential.user!.uid}');

      // Admin kaydını doğrula ve düzelt
      final String uid = userCredential.user!.uid;
      final String name =
          userCredential.user!.displayName ?? email.split('@')[0];
      await validateAndFixAdminRecord(uid, email, name);

      // Ardından admin koleksiyonundan kontrol et
      final adminDoc = await _db.collection('admins').doc(uid).get();

      print('Admin belge sorgusu yapıldı, belge var mı? ${adminDoc.exists}');

      if (!adminDoc.exists) {
        // Eğer admin değilse çıkış yap
        print('Admin değil, oturum kapatılıyor');
        await _auth.signOut();
        return null;
      }

      // Son giriş zamanını güncelle
      try {
        await _db.collection('admins').doc(uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
        print('Son giriş zamanı güncellendi');
      } catch (updateError) {
        print('Son giriş zamanı güncellenirken hata: $updateError');
        // Güncelleme başarısız olsa bile devam et
      }

      final adminData = adminDoc.data();
      print('Admin verileri: $adminData');

      return Admin.fromMap(adminDoc.data()!, adminDoc.id);
    } catch (e) {
      print('Admin girişi hatası: $e');
      return null;
    }
  }

  // Admin çıkışı yap
  Future<void> adminLogout() async {
    await _auth.signOut();
  }

  // Tüm kullanıcıları getir
  Future<List<UserSummary>> getAllUsers() async {
    try {
      final usersSnapshot = await _db.collection('users').get();
      return usersSnapshot.docs
          .map((doc) => UserSummary.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Kullanıcı listesi alınamadı: $e');
      return [];
    }
  }

  // Module CRUD Operations
  // Modül ekle
  Future<bool> addModule(Module module) async {
    try {
      await _db.collection('modules').add(module.toMap());
      return true;
    } catch (e) {
      print('Modül eklenemedi: $e');
      return false;
    }
  }

  // Modülü güncelle
  Future<bool> updateModule(String moduleId, Module module) async {
    try {
      await _db.collection('modules').doc(moduleId).update(module.toMap());
      return true;
    } catch (e) {
      print('Modül güncellenemedi: $e');
      return false;
    }
  }

  // Modülü sil
  Future<bool> deleteModule(String moduleId) async {
    try {
      // Önce derslerini bul
      final lessonsSnapshot = await _db
          .collection('modules')
          .doc(moduleId)
          .collection('lessons')
          .get();

      // Batch işlemi başlat
      final batch = _db.batch();

      // Tüm dersleri silme işlemine ekle
      for (var lesson in lessonsSnapshot.docs) {
        batch.delete(lesson.reference);
      }

      // Ana modülü silme işlemine ekle
      batch.delete(_db.collection('modules').doc(moduleId));

      // Batch işlemini çalıştır
      await batch.commit();
      return true;
    } catch (e) {
      print('Modül silinemedi: $e');
      return false;
    }
  }

  // Tüm modülleri getir
  Future<List<Module>> getAllModules() async {
    try {
      final snapshot = await _db.collection('modules').get();
      return snapshot.docs
          .map((doc) => Module.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Modüller getirilemedi: $e');
      return [];
    }
  }

  // Quiz CRUD Operations
  // Quiz ekle
  Future<bool> addQuiz(Quiz quiz) async {
    try {
      await _db.collection('quizzes').add(quiz.toMap());
      return true;
    } catch (e) {
      print('Quiz eklenemedi: $e');
      return false;
    }
  }

  // Quiz güncelle
  Future<bool> updateQuiz(String quizId, Quiz quiz) async {
    try {
      await _db.collection('quizzes').doc(quizId).update(quiz.toMap());
      return true;
    } catch (e) {
      print('Quiz güncellenemedi: $e');
      return false;
    }
  }

  // Quiz sil
  Future<bool> deleteQuiz(String quizId) async {
    try {
      await _db.collection('quizzes').doc(quizId).delete();
      return true;
    } catch (e) {
      print('Quiz silinemedi: $e');
      return false;
    }
  }

  // Tüm quizleri getir
  Future<List<Quiz>> getAllQuizzes() async {
    try {
      final snapshot = await _db.collection('quizzes').get();
      return snapshot.docs
          .map((doc) => Quiz.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Quizler getirilemedi: $e');
      return [];
    }
  }

  // Simulation CRUD Operations
  // Simülasyon ekle
  Future<bool> addSimulation(Simulation simulation) async {
    try {
      await _db.collection('simulations').add(simulation.toMap());
      return true;
    } catch (e) {
      print('Simülasyon eklenemedi: $e');
      return false;
    }
  }

  // Simülasyon güncelle
  Future<bool> updateSimulation(
      String simulationId, Simulation simulation) async {
    try {
      await _db
          .collection('simulations')
          .doc(simulationId)
          .update(simulation.toMap());
      return true;
    } catch (e) {
      print('Simülasyon güncellenemedi: $e');
      return false;
    }
  }

  // Simülasyon sil
  Future<bool> deleteSimulation(String simulationId) async {
    try {
      await _db.collection('simulations').doc(simulationId).delete();
      return true;
    } catch (e) {
      print('Simülasyon silinemedi: $e');
      return false;
    }
  }

  // Tüm simülasyonları getir
  Future<List<Simulation>> getAllSimulations() async {
    try {
      final snapshot = await _db.collection('simulations').get();
      return snapshot.docs
          .map((doc) => Simulation.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Simülasyonlar getirilemedi: $e');
      return [];
    }
  }

  // Training CRUD Operations
  // Eğitim ekle
  Future<bool> addTraining(Training training) async {
    try {
      await _db.collection('trainings').add(training.toMap());
      return true;
    } catch (e) {
      print('Eğitim eklenemedi: $e');
      return false;
    }
  }

  // Eğitim güncelle
  Future<bool> updateTraining(String trainingId, Training training) async {
    try {
      await _db
          .collection('trainings')
          .doc(trainingId)
          .update(training.toMap());
      return true;
    } catch (e) {
      print('Eğitim güncellenemedi: $e');
      return false;
    }
  }

  // Eğitim sil
  Future<bool> deleteTraining(String trainingId) async {
    try {
      await _db.collection('trainings').doc(trainingId).delete();
      return true;
    } catch (e) {
      print('Eğitim silinemedi: $e');
      return false;
    }
  }

  // Tüm eğitimleri getir
  Future<List<Training>> getAllTrainings() async {
    try {
      final snapshot = await _db.collection('trainings').get();
      return snapshot.docs
          .map((doc) => Training.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Eğitimler getirilemedi: $e');
      return [];
    }
  }

  // Roadmap CRUD Operations
  // Yol haritası ekle
  Future<bool> addRoadmap(Roadmap roadmap) async {
    try {
      await _db.collection('roadmaps').add(roadmap.toMap());
      return true;
    } catch (e) {
      print('Yol haritası eklenemedi: $e');
      return false;
    }
  }

  // Yol haritası güncelle
  Future<bool> updateRoadmap(String roadmapId, Roadmap roadmap) async {
    try {
      await _db.collection('roadmaps').doc(roadmapId).update(roadmap.toMap());
      return true;
    } catch (e) {
      print('Yol haritası güncellenemedi: $e');
      return false;
    }
  }

  // Yol haritası sil
  Future<bool> deleteRoadmap(String roadmapId) async {
    try {
      await _db.collection('roadmaps').doc(roadmapId).delete();
      return true;
    } catch (e) {
      print('Yol haritası silinemedi: $e');
      return false;
    }
  }

  // Tüm yol haritalarını getir
  Future<List<Roadmap>> getAllRoadmaps() async {
    try {
      final snapshot = await _db.collection('roadmaps').get();
      return snapshot.docs
          .map((doc) => Roadmap.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Yol haritaları getirilemedi: $e');
      return [];
    }
  }

  // Kullanıcı detayını getir
  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return null;
      }

      final progressSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('progress')
          .get();

      final quizResultsSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('quiz_results')
          .get();

      final simulationResultsSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('simulation_results')
          .get();

      return {
        'userInfo': userDoc.data(),
        'progress': progressSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList(),
        'quizResults': quizResultsSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList(),
        'simulationResults': simulationResultsSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList(),
      };
    } catch (e) {
      print('Kullanıcı detayları alınamadı: $e');
      return null;
    }
  }

  // Kullanıcıyı aktif/pasif yap
  Future<bool> toggleUserStatus(String userId, bool isActive) async {
    try {
      await _db.collection('users').doc(userId).update({
        'isActive': isActive,
      });
      return true;
    } catch (e) {
      print('Kullanıcı durumu değiştirilemedi: $e');
      return false;
    }
  }
}
