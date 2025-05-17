import 'package:bitirme_3/models/training.dart';

class TrainingService {
  // Singleton pattern
  static final TrainingService _instance = TrainingService._internal();
  factory TrainingService() => _instance;
  TrainingService._internal();

  // Tüm eğitimleri getir
  Future<List<Training>> getTrainings() async {
    // Gerçek uygulamada bu veriler Firebase'den gelecek
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simüle edilmiş gecikme
    return _dummyTrainings;
  }

  // Belirli bir eğitimi getir
  Future<Training?> getTrainingById(String trainingId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _dummyTrainings
          .firstWhere((training) => training.id == trainingId);
    } catch (e) {
      return null;
    }
  }

  // Eğitim içeriğini getir
  Future<TrainingContent?> getTrainingContentById(
      String trainingId, String contentId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      final training = await getTrainingById(trainingId);
      return training?.contents
          .firstWhere((content) => content.id == contentId);
    } catch (e) {
      return null;
    }
  }

  // Eğitim içeriğini tamamlandı olarak işaretle
  Future<void> markContentAsCompleted(
      String trainingId, String contentId) async {
    // Gerçek uygulamada Firebase'de güncelleme yapılacak
    await Future.delayed(const Duration(milliseconds: 200));
    // Simüle edilmiş güncelleme işlemi
    print('Eğitim içeriği tamamlandı: $contentId (Eğitim: $trainingId)');
  }
}

// Örnek veri
final List<Training> _dummyTrainings = [
  Training(
    id: 'tr001',
    title: 'Siber Güvenliğe Giriş',
    description:
        'Temel siber güvenlik kavramları, tehditler ve korunma yöntemleri hakkında kapsamlı eğitim.',
    imageUrl: 'assets/images/intro_cybersec.jpg',
    instructor: 'Dr. Ahmet Yılmaz',
    durationHours: 8,
    level: TrainingLevel.beginner,
    skills: ['Güvenlik Temelleri', 'Tehdit Analizi', 'Temel Koruma Teknikleri'],
    progress: 40,
    contents: [
      TrainingContent(
        id: 'trc001',
        title: 'Siber Güvenlik Nedir?',
        description: 'Siber güvenliğin tanımı ve önemi hakkında giriş videosu.',
        type: TrainingContentType.video,
        durationMinutes: 30,
        resourceUrl: 'https://example.com/videos/cybersec-intro',
      ),
      TrainingContent(
        id: 'trc002',
        title: 'Yaygın Siber Tehditler',
        description:
            'En yaygın siber tehditler ve saldırı vektörleri hakkında sunum.',
        type: TrainingContentType.presentation,
        durationMinutes: 45,
        resourceUrl: 'https://example.com/presentations/common-threats',
      ),
      TrainingContent(
        id: 'trc003',
        title: 'Temel Güvenlik Önlemleri',
        description: 'Ev ve iş yerinde alınabilecek temel güvenlik önlemleri.',
        type: TrainingContentType.document,
        durationMinutes: 60,
        resourceUrl: 'https://example.com/docs/basic-security-measures',
      ),
      TrainingContent(
        id: 'trc004',
        title: 'Şifre Güvenliği Alıştırması',
        description: 'Güçlü şifre oluşturma ve yönetme pratiği.',
        type: TrainingContentType.exercise,
        durationMinutes: 25,
        resourceUrl: 'https://example.com/exercises/password-security',
      ),
      TrainingContent(
        id: 'trc005',
        title: 'Siber Güvenlik Temel Sertifikası',
        description: 'Kurs sonu temel bilgi sertifikası sınavı.',
        type: TrainingContentType.certification,
        durationMinutes: 60,
        resourceUrl: 'https://example.com/cert/cybersec-basics',
      ),
    ],
  ),
  Training(
    id: 'tr002',
    title: 'Etik Hacker Teknikleri',
    description:
        'Sistemlerdeki güvenlik açıklarını tespit etme ve raporlama teknikleri hakkında uygulamalı eğitim.',
    imageUrl: 'assets/images/ethical_hacking.jpg',
    instructor: 'Zeynep Kaya',
    durationHours: 12,
    level: TrainingLevel.intermediate,
    skills: [
      'Penetrasyon Testi',
      'Güvenlik Açığı Tespiti',
      'Güvenlik Raporlama'
    ],
    progress: 20,
    contents: [
      TrainingContent(
        id: 'trc006',
        title: 'Etik Hacker Nedir?',
        description: 'Etik hacking kavramı ve yasal çerçevesi hakkında giriş.',
        type: TrainingContentType.video,
        durationMinutes: 40,
        resourceUrl: 'https://example.com/videos/ethical-hacking-intro',
      ),
      TrainingContent(
        id: 'trc007',
        title: 'Bilgi Toplama Teknikleri',
        description: 'Pasif ve aktif bilgi toplama yöntemleri.',
        type: TrainingContentType.document,
        durationMinutes: 60,
        resourceUrl: 'https://example.com/docs/info-gathering',
      ),
      TrainingContent(
        id: 'trc008',
        title: 'Ağ Keşfi ve Tarama',
        description: 'Ağ keşfi ve port tarama uygulaması.',
        type: TrainingContentType.codeLab,
        durationMinutes: 90,
        resourceUrl: 'https://example.com/labs/network-scanning',
      ),
      TrainingContent(
        id: 'trc009',
        title: 'Güvenlik Açığı Analizi',
        description:
            'Tespit edilen güvenlik açıklarını analiz etme ve değerlendirme.',
        type: TrainingContentType.exercise,
        durationMinutes: 120,
        resourceUrl: 'https://example.com/exercises/vulnerability-analysis',
      ),
    ],
  ),
  Training(
    id: 'tr003',
    title: 'Savunma Odaklı Güvenlik',
    description:
        'Proaktif siber savunma stratejileri ve araçları hakkında kapsamlı eğitim.',
    imageUrl: 'assets/images/defensive_security.jpg',
    instructor: 'Prof. Mehmet Demir',
    durationHours: 10,
    level: TrainingLevel.advanced,
    skills: ['SIEM Sistemleri', 'Güvenlik Duvarı Yönetimi', 'Anomali Tespiti'],
    progress: 0,
    contents: [
      TrainingContent(
        id: 'trc010',
        title: 'Savunma Derinliği Konsepti',
        description: 'Çok katmanlı savunma stratejileri ve uygulanması.',
        type: TrainingContentType.presentation,
        durationMinutes: 50,
        resourceUrl: 'https://example.com/presentations/defense-in-depth',
      ),
      TrainingContent(
        id: 'trc011',
        title: 'SIEM Sistemleri Kurulumu',
        description:
            'Güvenlik Bilgileri ve Olay Yönetimi sistemleri uygulaması.',
        type: TrainingContentType.codeLab,
        durationMinutes: 120,
        resourceUrl: 'https://example.com/labs/siem-setup',
      ),
      TrainingContent(
        id: 'trc012',
        title: 'Gelişmiş Güvenlik Duvarı Yapılandırma',
        description:
            'Kurumsal seviyede güvenlik duvarı kuralları ve yapılandırması.',
        type: TrainingContentType.exercise,
        durationMinutes: 90,
        resourceUrl: 'https://example.com/exercises/advanced-firewall',
      ),
      TrainingContent(
        id: 'trc013',
        title: 'Savunma Odaklı Sertifika Sınavı',
        description: 'Savunma odaklı güvenlik uzmanlığı sertifikası.',
        type: TrainingContentType.certification,
        durationMinutes: 120,
        resourceUrl: 'https://example.com/cert/defensive-security',
      ),
    ],
  ),
];
