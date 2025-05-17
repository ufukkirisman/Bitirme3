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

  // Modül ekle
  Future<bool> addModule(Module module) async {
    try {
      await _db.collection('modules').add({
        'title': module.title,
        'description': module.description,
        'imageUrl': module.imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Modül eklenemedi: $e');
      return false;
    }
  }

  // Modülü güncelle
  Future<bool> updateModule(String moduleId, Map<String, dynamic> data) async {
    try {
      await _db.collection('modules').doc(moduleId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
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

  // Quiz ekle
  Future<bool> addQuiz(Quiz quiz) async {
    try {
      final docRef = await _db.collection('quizzes').add({
        'title': quiz.title,
        'description': quiz.description,
        'timeLimit': quiz.timeLimit,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Soruları ekle
      for (var question in quiz.questions) {
        await docRef.collection('questions').add({
          'text': question.text,
          'type': question.type.toString().split('.').last,
          'explanation': question.explanation,
          'points': question.points,
          // Cevapları ekle
          'answers': question.answers
              .map((answer) => {
                    'text': answer.text,
                    'isCorrect': answer.isCorrect,
                  })
              .toList(),
        });
      }

      return true;
    } catch (e) {
      print('Quiz eklenemedi: $e');
      return false;
    }
  }

  // Quiz güncelle
  Future<bool> updateQuiz(String quizId, Map<String, dynamic> data,
      List<Question>? questions) async {
    try {
      // Ana quiz verisini güncelle
      await _db.collection('quizzes').doc(quizId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Eğer sorular da güncellenmişse
      if (questions != null) {
        // Önce tüm mevcut soruları sil
        final questionsSnapshot = await _db
            .collection('quizzes')
            .doc(quizId)
            .collection('questions')
            .get();

        final batch = _db.batch();
        for (var doc in questionsSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        // Yeni soruları ekle
        for (var question in questions) {
          await _db
              .collection('quizzes')
              .doc(quizId)
              .collection('questions')
              .add({
            'text': question.text,
            'type': question.type.toString().split('.').last,
            'explanation': question.explanation,
            'points': question.points,
            'answers': question.answers
                .map((answer) => {
                      'text': answer.text,
                      'isCorrect': answer.isCorrect,
                    })
                .toList(),
          });
        }
      }

      return true;
    } catch (e) {
      print('Quiz güncellenemedi: $e');
      return false;
    }
  }

  // Quiz sil
  Future<bool> deleteQuiz(String quizId) async {
    try {
      // Önce soruları sil
      final questionsSnapshot = await _db
          .collection('quizzes')
          .doc(quizId)
          .collection('questions')
          .get();

      final batch = _db.batch();
      for (var doc in questionsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Quizi sil
      batch.delete(_db.collection('quizzes').doc(quizId));
      await batch.commit();

      return true;
    } catch (e) {
      print('Quiz silinemedi: $e');
      return false;
    }
  }

  // Simülasyon ekle
  Future<bool> addSimulation(Simulation simulation) async {
    try {
      final docRef = await _db.collection('simulations').add({
        'title': simulation.title,
        'description': simulation.description,
        'type': simulation.type.toString().split('.').last,
        'difficultyLevel': simulation.difficultyLevel,
        'imageUrl': simulation.imageUrl,
        'parameters': simulation.parameters,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Simülasyon adımlarını ekle
      for (var step in simulation.steps) {
        await docRef.collection('steps').add({
          'title': step.title,
          'description': step.description,
          'commands': step.commands,
          'expectedOutput': step.expectedOutput,
          'imageUrl': step.imageUrl,
          'order': step.id, // Sıralama için id kullanıyoruz
        });
      }

      return true;
    } catch (e) {
      print('Simülasyon eklenemedi: $e');
      return false;
    }
  }

  // Simülasyon güncelle
  Future<bool> updateSimulation(String simulationId, Map<String, dynamic> data,
      List<SimulationStep>? steps) async {
    try {
      // Ana simülasyon verisini güncelle
      await _db.collection('simulations').doc(simulationId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Adımlar da güncellenmişse
      if (steps != null) {
        // Önce mevcut adımları sil
        final stepsSnapshot = await _db
            .collection('simulations')
            .doc(simulationId)
            .collection('steps')
            .get();

        final batch = _db.batch();
        for (var doc in stepsSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        // Yeni adımları ekle
        for (var step in steps) {
          await _db
              .collection('simulations')
              .doc(simulationId)
              .collection('steps')
              .add({
            'title': step.title,
            'description': step.description,
            'commands': step.commands,
            'expectedOutput': step.expectedOutput,
            'imageUrl': step.imageUrl,
            'order': step.id,
          });
        }
      }

      return true;
    } catch (e) {
      print('Simülasyon güncellenemedi: $e');
      return false;
    }
  }

  // Simülasyon sil
  Future<bool> deleteSimulation(String simulationId) async {
    try {
      // Önce adımları sil
      final stepsSnapshot = await _db
          .collection('simulations')
          .doc(simulationId)
          .collection('steps')
          .get();

      final batch = _db.batch();
      for (var doc in stepsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Simülasyonu sil
      batch.delete(_db.collection('simulations').doc(simulationId));
      await batch.commit();

      return true;
    } catch (e) {
      print('Simülasyon silinemedi: $e');
      return false;
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

  // Eğitim ekle/güncelle/sil işlemleri
  Future<bool> addTraining(Training training) async {
    try {
      final trainingData = {
        'title': training.title,
        'description': training.description,
        'imageUrl': training.imageUrl,
        'instructor': training.instructor,
        'durationHours': training.durationHours,
        'level': training.level.toString().split('.').last,
        'skills': training.skills,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _db.collection('trainings').add(trainingData);

      // İçerikleri ekle
      for (var content in training.contents) {
        await docRef.collection('contents').add({
          'title': content.title,
          'description': content.description,
          'type': content.type.toString().split('.').last,
          'durationMinutes': content.durationMinutes,
          'resourceUrl': content.resourceUrl,
        });
      }

      return true;
    } catch (e) {
      print('Eğitim eklenemedi: $e');
      return false;
    }
  }

  // Eğitim güncelle
  Future<bool> updateTraining(String trainingId, Map<String, dynamic> data,
      List<TrainingContent>? contents) async {
    try {
      // Ana eğitim verisini güncelle
      await _db.collection('trainings').doc(trainingId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // İçerikler de güncellenmişse
      if (contents != null) {
        // Önce mevcut içerikleri sil
        final contentsSnapshot = await _db
            .collection('trainings')
            .doc(trainingId)
            .collection('contents')
            .get();

        final batch = _db.batch();
        for (var doc in contentsSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        // Yeni içerikleri ekle
        for (var content in contents) {
          await _db
              .collection('trainings')
              .doc(trainingId)
              .collection('contents')
              .add({
            'title': content.title,
            'description': content.description,
            'type': content.type.toString().split('.').last,
            'durationMinutes': content.durationMinutes,
            'resourceUrl': content.resourceUrl,
          });
        }
      }

      return true;
    } catch (e) {
      print('Eğitim güncellenemedi: $e');
      return false;
    }
  }

  // Eğitim sil
  Future<bool> deleteTraining(String trainingId) async {
    try {
      // Önce içerikleri sil
      final contentsSnapshot = await _db
          .collection('trainings')
          .doc(trainingId)
          .collection('contents')
          .get();

      final batch = _db.batch();
      for (var doc in contentsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Eğitimi sil
      batch.delete(_db.collection('trainings').doc(trainingId));
      await batch.commit();

      return true;
    } catch (e) {
      print('Eğitim silinemedi: $e');
      return false;
    }
  }

  // Yol haritası ekle
  Future<bool> addRoadmap(Roadmap roadmap) async {
    try {
      final roadmapData = {
        'title': roadmap.title,
        'description': roadmap.description,
        'imageUrl': roadmap.imageUrl,
        'category': roadmap.category,
        'estimatedDurationWeeks': roadmap.estimatedDurationWeeks,
        'careerPath': roadmap.careerPath.toString().split('.').last,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _db.collection('roadmaps').add(roadmapData);

      // Adımları ekle
      for (var step in roadmap.steps) {
        final stepRef = await docRef.collection('steps').add({
          'title': step.title,
          'description': step.description,
          'order': step.order,
          'requiredSkills': step.requiredSkills,
          'relatedModuleIds': step.relatedModuleIds,
        });

        // Kaynakları ekle
        for (var resource in step.resources) {
          await stepRef.collection('resources').add({
            'title': resource.title,
            'type': resource.type.toString().split('.').last,
            'url': resource.url,
            'isRequired': resource.isRequired,
          });
        }
      }

      return true;
    } catch (e) {
      print('Yol haritası eklenemedi: $e');
      return false;
    }
  }

  // Yol haritası güncelle
  Future<bool> updateRoadmap(String roadmapId, Map<String, dynamic> data,
      List<RoadmapStep>? steps) async {
    try {
      // Ana yol haritası verisini güncelle
      await _db.collection('roadmaps').doc(roadmapId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Adımlar da güncellenmişse
      if (steps != null) {
        // Önce tüm adımları sil (kaynaklar dahil)
        final stepsSnapshot = await _db
            .collection('roadmaps')
            .doc(roadmapId)
            .collection('steps')
            .get();

        // Her adım için önce kaynakları sil
        for (var stepDoc in stepsSnapshot.docs) {
          final resourcesSnapshot =
              await stepDoc.reference.collection('resources').get();

          final resourceBatch = _db.batch();
          for (var resourceDoc in resourcesSnapshot.docs) {
            resourceBatch.delete(resourceDoc.reference);
          }
          await resourceBatch.commit();
        }

        // Sonra adımları sil
        final stepBatch = _db.batch();
        for (var doc in stepsSnapshot.docs) {
          stepBatch.delete(doc.reference);
        }
        await stepBatch.commit();

        // Yeni adımları ekle
        for (var step in steps) {
          final stepRef = await _db
              .collection('roadmaps')
              .doc(roadmapId)
              .collection('steps')
              .add({
            'title': step.title,
            'description': step.description,
            'order': step.order,
            'requiredSkills': step.requiredSkills,
            'relatedModuleIds': step.relatedModuleIds,
          });

          // Kaynakları ekle
          for (var resource in step.resources) {
            await stepRef.collection('resources').add({
              'title': resource.title,
              'type': resource.type.toString().split('.').last,
              'url': resource.url,
              'isRequired': resource.isRequired,
            });
          }
        }
      }

      return true;
    } catch (e) {
      print('Yol haritası güncellenemedi: $e');
      return false;
    }
  }

  // Yol haritası sil
  Future<bool> deleteRoadmap(String roadmapId) async {
    try {
      // Önce adımları ve kaynakları sil
      final stepsSnapshot = await _db
          .collection('roadmaps')
          .doc(roadmapId)
          .collection('steps')
          .get();

      // Her adım için kaynakları sil
      for (var stepDoc in stepsSnapshot.docs) {
        final resourcesSnapshot =
            await stepDoc.reference.collection('resources').get();

        final resourceBatch = _db.batch();
        for (var resourceDoc in resourcesSnapshot.docs) {
          resourceBatch.delete(resourceDoc.reference);
        }
        await resourceBatch.commit();
      }

      // Sonra adımları sil
      final stepBatch = _db.batch();
      for (var stepDoc in stepsSnapshot.docs) {
        stepBatch.delete(stepDoc.reference);
      }
      await stepBatch.commit();

      // Yol haritasını sil
      await _db.collection('roadmaps').doc(roadmapId).delete();

      return true;
    } catch (e) {
      print('Yol haritası silinemedi: $e');
      return false;
    }
  }
}
