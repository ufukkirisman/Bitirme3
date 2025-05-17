import 'package:bitirme_3/models/module.dart';
import 'package:bitirme_3/models/quiz.dart';
import 'package:bitirme_3/models/simulation.dart';

class ModuleService {
  // Singleton pattern
  static final ModuleService _instance = ModuleService._internal();
  factory ModuleService() => _instance;
  ModuleService._internal();

  // Tüm modülleri getir
  Future<List<Module>> getModules() async {
    // Gerçek uygulamada bu veriler Firebase'den gelecek
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simüle edilmiş gecikme
    return _dummyModules;
  }

  // Belirli bir modülü getir
  Future<Module?> getModuleById(String moduleId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _dummyModules.firstWhere((module) => module.id == moduleId);
    } catch (e) {
      return null;
    }
  }

  // Belirli bir dersi getir
  Future<Lesson?> getLessonById(String moduleId, String lessonId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      final module = await getModuleById(moduleId);
      return module?.lessons.firstWhere((lesson) => lesson.id == lessonId);
    } catch (e) {
      return null;
    }
  }

  // Quiz'i getir
  Future<Quiz?> getQuizById(String quizId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _dummyQuizzes.firstWhere((quiz) => quiz.id == quizId);
    } catch (e) {
      return null;
    }
  }

  // Simülasyonu getir
  Future<Simulation?> getSimulationById(String simulationId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _dummySimulations.firstWhere((sim) => sim.id == simulationId);
    } catch (e) {
      return null;
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
