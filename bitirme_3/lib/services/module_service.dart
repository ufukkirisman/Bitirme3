import 'package:bitirme_3/models/module.dart';
import 'package:bitirme_3/models/quiz.dart';
import 'package:bitirme_3/models/simulation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ModuleService {
  // Singleton pattern
  static final ModuleService _instance = ModuleService._internal();
  factory ModuleService() => _instance;
  ModuleService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcı ID'sini alma
  String? get currentUserId => _auth.currentUser?.uid;

  // Tüm modülleri getir
  Future<List<Module>> getModules() async {
    try {
      final snapshot = await _db
          .collection('modules')
          .orderBy('order', descending: false)
          .get();

      print('Firebase\'den ${snapshot.docs.length} modül getirildi');

      List<Module> modules = [];
      for (var doc in snapshot.docs) {
        modules.add(Module.fromMap(doc.data(), doc.id));
      }

      // Eğer veri yoksa test verilerini kullan
      if (modules.isEmpty) {
        print('Firebase\'de modül bulunamadı, örnek veriler kullanılıyor');
        return _dummyModules;
      }

      return modules;
    } catch (e) {
      print('Modüller getirme hatası: $e');
      // Hata durumunda örnek verileri kullan
      return _dummyModules;
    }
  }

  // Belirli bir modülü getir
  Future<Module?> getModuleById(String moduleId) async {
    try {
      final doc = await _db.collection('modules').doc(moduleId).get();

      if (!doc.exists) {
        print('Modül bulunamadı: $moduleId');
        return null;
      }

      print('Modül bulundu: $moduleId');
      return Module.fromMap(doc.data()!, doc.id);
    } catch (e) {
      print('Modül detayı getirme hatası: $e');
      // Hata durumunda örnek modül dön
      try {
        return _dummyModules.firstWhere((module) => module.id == moduleId);
      } catch (e) {
        return null;
      }
    }
  }

  // Belirli bir dersi getir
  Future<Lesson?> getLessonById(String moduleId, String lessonId) async {
    try {
      // Önce modüle ait dersleri Firebase'den al
      final lessonDoc = await _db
          .collection('modules')
          .doc(moduleId)
          .collection('lessons')
          .doc(lessonId)
          .get();

      if (!lessonDoc.exists) {
        print('Ders bulunamadı: $lessonId');
        return null;
      }

      print('Ders bulundu: $lessonId');

      final data = lessonDoc.data()!;

      // lesson veriyi oluştur
      return Lesson(
        id: lessonDoc.id,
        title: data['title'] ?? '',
        content: data['content'] ?? '',
        type: _getLessonType(data['type'] ?? 'theory'),
        durationMinutes: data['durationMinutes'] ?? 0,
        quizId: data['quizId'],
        simulationId: data['simulationId'],
      );
    } catch (e) {
      print('Ders detayı getirme hatası: $e');
      // Hata durumunda örnek ders dön
      try {
        final module =
            _dummyModules.firstWhere((module) => module.id == moduleId);
        return module.lessons.firstWhere((lesson) => lesson.id == lessonId);
      } catch (e) {
        return null;
      }
    }
  }

  // Quiz'i getir
  Future<Quiz?> getQuizById(String quizId) async {
    try {
      final doc = await _db.collection('quizzes').doc(quizId).get();

      if (!doc.exists) {
        print('Quiz bulunamadı: $quizId');
        return null;
      }

      // Quiz'in sorularını al
      final questionsSnapshot = await _db
          .collection('quizzes')
          .doc(quizId)
          .collection('questions')
          .orderBy('order', descending: false)
          .get();

      print('Quiz bulundu: $quizId, ${questionsSnapshot.docs.length} soru ile');

      // Quiz verisini oluştur
      final quizData = doc.data()!;

      // Soruları oluştur
      List<Question> questions = [];
      for (var questionDoc in questionsSnapshot.docs) {
        final qData = questionDoc.data();

        // Cevapları oluştur
        List<Answer> answers = [];
        if (qData['answers'] != null) {
          for (var answerMap in qData['answers']) {
            answers.add(Answer(
              id: answerMap['id'] ?? '',
              text: answerMap['text'] ?? '',
              isCorrect: answerMap['isCorrect'] ?? false,
            ));
          }
        }

        questions.add(Question(
          id: questionDoc.id,
          text: qData['text'] ?? '',
          type: _getQuestionType(qData['type'] ?? 'multipleChoice'),
          points: qData['points'] ?? 5,
          answers: answers,
          explanation: qData['explanation'] ?? '',
        ));
      }

      return Quiz(
        id: doc.id,
        title: quizData['title'] ?? '',
        description: quizData['description'] ?? '',
        timeLimit: quizData['timeLimit'] ?? 30,
        questions: questions,
        isCompleted: false, // Kullanıcı ilerlemesi için ayrıca kontrol edilmeli
      );
    } catch (e) {
      print('Quiz detayı getirme hatası: $e');
      // Hata durumunda örnek quiz dön
      try {
        return _dummyQuizzes.firstWhere((quiz) => quiz.id == quizId);
      } catch (e) {
        return null;
      }
    }
  }

  // Simülasyonu getir
  Future<Simulation?> getSimulationById(String simulationId) async {
    try {
      final doc = await _db.collection('simulations').doc(simulationId).get();

      if (!doc.exists) {
        print('Simülasyon bulunamadı: $simulationId');
        return null;
      }

      // Simülasyonun adımlarını al
      final stepsSnapshot = await _db
          .collection('simulations')
          .doc(simulationId)
          .collection('steps')
          .orderBy('order', descending: false)
          .get();

      print(
          'Simülasyon bulundu: $simulationId, ${stepsSnapshot.docs.length} adım ile');

      // Simülasyon verisini oluştur
      final simData = doc.data()!;

      // Adımları oluştur
      List<SimulationStep> steps = [];
      for (var stepDoc in stepsSnapshot.docs) {
        final sData = stepDoc.data();

        // Komutları oluştur
        List<String> commands = [];
        if (sData['commands'] != null) {
          for (var command in sData['commands']) {
            commands.add(command.toString());
          }
        }

        steps.add(SimulationStep(
          id: stepDoc.id,
          title: sData['title'] ?? '',
          description: sData['description'] ?? '',
          commands: commands,
          expectedOutput: sData['expectedOutput'] ?? '',
        ));
      }

      return Simulation(
        id: doc.id,
        title: simData['title'] ?? '',
        description: simData['description'] ?? '',
        type: _getSimulationType(simData['type'] ?? 'networkAnalysis'),
        difficultyLevel: simData['difficultyLevel'] ?? 1,
        imageUrl: simData['imageUrl'] ?? '',
        steps: steps,
      );
    } catch (e) {
      print('Simülasyon detayı getirme hatası: $e');
      // Hata durumunda örnek simülasyon dön
      try {
        return _dummySimulations.firstWhere((sim) => sim.id == simulationId);
      } catch (e) {
        return null;
      }
    }
  }

  // Kullanıcının modül ilerlemesini güncelle
  Future<void> updateModuleProgress(String moduleId, int progress) async {
    try {
      if (currentUserId == null) return;

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
      print('Modül ilerleme güncellemesi hatası: $e');
    }
  }

  // Kullanıcının quiz sonucunu kaydet
  Future<void> saveQuizResult(
    String quizId,
    String moduleId,
    int score,
    int totalPoints,
  ) async {
    try {
      if (currentUserId == null) return;

      final percentage = (score / totalPoints) * 100;
      final isPassed = percentage >= 70; // %70 geçme notu

      // Quiz sonucunu kaydet
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
        'isPassed': isPassed,
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Modül ilerlemesini güncelle
      if (isPassed) {
        await updateModuleProgress(moduleId, 100);
      }

      print('Quiz sonucu kaydedildi. Skor: $score/$totalPoints');
    } catch (e) {
      print('Quiz sonucu kaydetme hatası: $e');
      rethrow;
    }
  }

  // String'den LessonType'a çeviri
  LessonType _getLessonType(String type) {
    switch (type) {
      case 'quiz':
        return LessonType.quiz;
      case 'simulation':
        return LessonType.simulation;
      case 'theory':
      default:
        return LessonType.theory;
    }
  }

  // String'den QuestionType'a çeviri
  QuestionType _getQuestionType(String type) {
    switch (type) {
      case 'trueFalse':
        return QuestionType.trueFalse;
      case 'fillInBlank':
        return QuestionType.fillInBlank;
      case 'multipleChoice':
      default:
        return QuestionType.multipleChoice;
    }
  }

  // String'den SimulationType'a çeviri
  SimulationType _getSimulationType(String type) {
    switch (type) {
      case 'penetrationTesting':
        return SimulationType.penetrationTesting;
      case 'forensicAnalysis':
        return SimulationType.forensicAnalysis;
      case 'malwareAnalysis':
        return SimulationType.malwareAnalysis;
      case 'cryptography':
        return SimulationType.cryptography;
      case 'socialEngineering':
        return SimulationType.socialEngineering;
      case 'networkAnalysis':
      default:
        return SimulationType.networkAnalysis;
    }
  }
}

// Örnek veri
final List<Module> _dummyModules = [
  Module(
    id: 'mod001',
    title: 'Ağ Güvenliği Temelleri',
    description:
        'Firewall, IDS/IPS, VPN ve temel ağ güvenliği konuları hakkında bilgi edineceksiniz.',
    imageUrl: 'assets/images/network_security.jpg',
    progress: 30,
    lessons: [
      Lesson(
        id: 'les001',
        title: 'Ağ Güvenliği Giriş',
        content:
            'Ağ güvenliği, bilgisayar ağlarını yetkisiz erişimden, saldırılardan ve kötüye kullanımdan koruma pratiğidir...',
        type: LessonType.theory,
        durationMinutes: 15,
      ),
      Lesson(
        id: 'les002',
        title: 'Firewall Nedir?',
        content:
            'Firewall (Güvenlik Duvarı), ağ trafiğini izleyen ve belirlenmiş güvenlik kurallarına göre trafiği engelleyen veya izin veren bir ağ güvenlik sistemidir...',
        type: LessonType.theory,
        durationMinutes: 20,
      ),
      Lesson(
        id: 'les003',
        title: 'Ağ Güvenliği Testi',
        content:
            'Bu test, ağ güvenliği temellerini ne kadar anladığınızı ölçecektir.',
        type: LessonType.quiz,
        durationMinutes: 10,
        quizId: 'quiz001',
      ),
      Lesson(
        id: 'les004',
        title: 'Firewall Konfigürasyonu',
        content:
            'Bu simülasyon ile basit bir firewall nasıl yapılandırılır öğreneceksiniz.',
        type: LessonType.simulation,
        durationMinutes: 30,
        simulationId: 'sim001',
      ),
    ],
  ),
  Module(
    id: 'mod002',
    title: 'Kriptografi ve Şifreleme',
    description:
        'Şifreleme algoritmaları, hash fonksiyonları ve pratik uygulamaları hakkında bilgi edineceksiniz.',
    imageUrl: 'assets/images/cryptography.jpg',
    progress: 10,
    lessons: [
      Lesson(
        id: 'les005',
        title: 'Kriptografiye Giriş',
        content:
            'Kriptografi, verileri güvenli ve gizli tutmak için matematiksel yöntemlerin kullanılmasıdır...',
        type: LessonType.theory,
        durationMinutes: 15,
      ),
      Lesson(
        id: 'les006',
        title: 'Simetrik ve Asimetrik Şifreleme',
        content:
            'Şifreleme iki ana kategoriye ayrılır: simetrik ve asimetrik şifreleme...',
        type: LessonType.theory,
        durationMinutes: 25,
      ),
      Lesson(
        id: 'les007',
        title: 'Kriptografi Bilgi Testi',
        content:
            'Bu test, kriptografi temellerini ne kadar anladığınızı ölçecektir.',
        type: LessonType.quiz,
        durationMinutes: 15,
        quizId: 'quiz002',
      ),
      Lesson(
        id: 'les008',
        title: 'Basit Şifreleme Algoritması Uygulaması',
        content:
            'Bu simülasyonda basit bir Caesar şifreleme algoritması uygulayacaksınız.',
        type: LessonType.simulation,
        durationMinutes: 20,
        simulationId: 'sim002',
      ),
    ],
  ),
  Module(
    id: 'mod003',
    title: 'Web Uygulama Güvenliği',
    description:
        'SQL injection, XSS, CSRF ve diğer yaygın web zafiyetleri hakkında bilgi edineceksiniz.',
    imageUrl: 'assets/images/web_security.jpg',
    progress: 0,
    lessons: [
      Lesson(
        id: 'les009',
        title: 'Web Uygulama Güvenliği Temelleri',
        content:
            'Web uygulama güvenliği, web sitelerini ve uygulamalarını güvenlik tehditlerinden koruma pratiğidir...',
        type: LessonType.theory,
        durationMinutes: 20,
      ),
      Lesson(
        id: 'les010',
        title: 'SQL Injection Saldırıları',
        content:
            'SQL Injection, saldırganların zararlı SQL sorgularını uygulama arayüzünden enjekte etme tekniğidir...',
        type: LessonType.theory,
        durationMinutes: 25,
      ),
      Lesson(
        id: 'les011',
        title: 'Web Güvenliği Testi',
        content:
            'Bu test, web uygulama güvenliği konusundaki bilgilerinizi ölçecektir.',
        type: LessonType.quiz,
        durationMinutes: 15,
        quizId: 'quiz003',
      ),
      Lesson(
        id: 'les012',
        title: 'SQL Injection Tespit ve Önleme',
        content:
            'Bu simülasyonda bir web uygulamasındaki SQL Injection zafiyetini tespit edip önleyeceksiniz.',
        type: LessonType.simulation,
        durationMinutes: 30,
        simulationId: 'sim003',
      ),
    ],
  ),
];

// Örnek quizler
final List<Quiz> _dummyQuizzes = [
  Quiz(
    id: 'quiz001',
    title: 'Ağ Güvenliği Temelleri Quiz',
    description:
        'Bu quiz, ağ güvenliği temellerini ne kadar anladığınızı test edecektir.',
    timeLimit: 10, // 10 dakika
    questions: [
      Question(
        id: 'q001',
        text: 'Hangisi bir firewall\'un birincil görevidir?',
        type: QuestionType.multipleChoice,
        points: 5,
        answers: [
          Answer(
              id: 'a001', text: 'Antivirüs taraması yapmak', isCorrect: false),
          Answer(
              id: 'a002',
              text: 'Ağ trafiğini izlemek ve filtrelemek',
              isCorrect: true),
          Answer(
              id: 'a003',
              text: 'Veritabanı yedeklemesi yapmak',
              isCorrect: false),
          Answer(
              id: 'a004',
              text: 'Şifreleme algoritmaları uygulamak',
              isCorrect: false),
        ],
        explanation:
            'Firewall\'ların temel görevi, belirli kurallara göre ağ trafiğini izlemek ve filtrelemektir.',
      ),
      Question(
        id: 'q002',
        text: 'VPN teknolojisinin asıl amacı nedir?',
        type: QuestionType.multipleChoice,
        points: 5,
        answers: [
          Answer(
              id: 'a005',
              text: 'Güvenli bir özel ağ bağlantısı sağlamak',
              isCorrect: true),
          Answer(
              id: 'a006', text: 'İnternet hızını artırmak', isCorrect: false),
          Answer(
              id: 'a007',
              text: 'Kullanıcıların verilerini yedeklemek',
              isCorrect: false),
          Answer(
              id: 'a008',
              text: 'Web sitelerini daha hızlı yüklemek',
              isCorrect: false),
        ],
        explanation:
            'VPN (Virtual Private Network), güvenli ve şifrelenmiş bir tünel oluşturarak kullanıcıların internet üzerinden özel ağlara güvenli bir şekilde bağlanmasını sağlar.',
      ),
    ],
  ),

  // Diğer quizler...
];

// Örnek simülasyonlar
final List<Simulation> _dummySimulations = [
  Simulation(
    id: 'sim001',
    title: 'Temel Firewall Konfigürasyonu',
    description:
        'Bu simülasyonda, basit bir firewall yapılandırması öğreneceksiniz.',
    type: SimulationType.networkAnalysis,
    difficultyLevel: 2,
    imageUrl: 'assets/images/firewall_sim.jpg',
    steps: [
      SimulationStep(
        id: 'step001',
        title: 'Firewall Servisine Bağlanma',
        description:
            'İlk adım olarak, firewall servisine bağlanmanız gerekiyor.',
        commands: [
          'sudo systemctl status firewalld',
          'sudo systemctl start firewalld'
        ],
        expectedOutput: 'Active: active (running)',
      ),
      SimulationStep(
        id: 'step002',
        title: 'Mevcut Kuralları Görüntüleme',
        description: 'Mevcut firewall kurallarını kontrol edin.',
        commands: ['sudo firewall-cmd --list-all'],
        expectedOutput:
            'public (active)\n  target: default\n  icmp-block-inversion: no',
      ),
      // Diğer adımlar...
    ],
  ),

  // Diğer simülasyonlar...
];
