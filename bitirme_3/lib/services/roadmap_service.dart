import 'package:bitirme_3/models/roadmap.dart';

class RoadmapService {
  // Singleton pattern
  static final RoadmapService _instance = RoadmapService._internal();
  factory RoadmapService() => _instance;
  RoadmapService._internal();

  // Tüm yol haritalarını getir
  Future<List<Roadmap>> getRoadmaps() async {
    // Gerçek uygulamada bu veriler Firebase'den gelecek
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simüle edilmiş gecikme
    return _dummyRoadmaps;
  }

  // Belirli bir yol haritasını getir
  Future<Roadmap?> getRoadmapById(String roadmapId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _dummyRoadmaps.firstWhere((roadmap) => roadmap.id == roadmapId);
    } catch (e) {
      return null;
    }
  }

  // Yol haritası adımını tamamlandı olarak işaretle
  Future<void> markStepAsCompleted(String roadmapId, String stepId) async {
    // Gerçek uygulamada Firebase'de güncelleme yapılacak
    await Future.delayed(const Duration(milliseconds: 200));
    // Simüle edilmiş güncelleme işlemi
    print('Yol haritası adımı tamamlandı: $stepId (Roadmap: $roadmapId)');
  }
}

// Örnek veri
final List<Roadmap> _dummyRoadmaps = [
  Roadmap(
    id: 'rm001',
    title: 'Siber Güvenlik Uzmanı Yol Haritası',
    description:
        'Sıfırdan başlayarak siber güvenlik uzmanı olmak için takip edilmesi gereken adımlar.',
    imageUrl: 'assets/images/security_specialist.jpg',
    category: 'Kariyer Gelişimi',
    estimatedDurationWeeks: 52,
    careerPath: CareerPath.securityAnalyst,
    progress: 35,
    steps: [
      RoadmapStep(
        id: 'rs001',
        title: 'Temel Bilgi Teknolojileri',
        description:
            'Ağ yapısı, işletim sistemleri ve temel programlama bilgisi edinme.',
        order: 1,
        isCompleted: true,
        resources: [
          RoadmapResource(
            id: 'rr001',
            title: 'Ağ Temelleri Eğitimi',
            type: ResourceType.course,
            url: 'https://example.com/courses/networking-basics',
          ),
          RoadmapResource(
            id: 'rr002',
            title: 'Linux Fundamentals',
            type: ResourceType.tutorial,
            url: 'https://example.com/tutorials/linux-fundamentals',
          ),
          RoadmapResource(
            id: 'rr003',
            title: 'Python Programlama Başlangıç',
            type: ResourceType.course,
            url: 'https://example.com/courses/python-beginners',
          ),
        ],
        requiredSkills: [
          'Temel Ağ Bilgisi',
          'Linux Temelleri',
          'Python Temelleri'
        ],
        relatedModuleIds: ['mod001'],
      ),
      RoadmapStep(
        id: 'rs002',
        title: 'Siber Güvenlik Temelleri',
        description:
            'Siber güvenlik kavramları, tehditler ve temel savunma mekanizmaları.',
        order: 2,
        isCompleted: true,
        resources: [
          RoadmapResource(
            id: 'rr004',
            title: 'Siber Güvenlik Temelleri Eğitimi',
            type: ResourceType.course,
            url: 'https://example.com/courses/cybersecurity-basics',
            isRequired: true,
          ),
          RoadmapResource(
            id: 'rr005',
            title: 'Tehdit Modelleme',
            type: ResourceType.article,
            url: 'https://example.com/articles/threat-modeling',
          ),
        ],
        requiredSkills: ['Güvenlik Temelleri', 'Tehdit Analizi'],
        relatedModuleIds: ['mod001', 'mod002'],
      ),
      RoadmapStep(
        id: 'rs003',
        title: 'Güvenlik Araçları ve Teknikleri',
        description:
            'Güvenlik taraması, zafiyet tespiti ve sızma testi araçları hakkında bilgi edinme.',
        order: 3,
        isCompleted: true,
        resources: [
          RoadmapResource(
            id: 'rr006',
            title: 'Kali Linux Araçları Eğitimi',
            type: ResourceType.course,
            url: 'https://example.com/courses/kali-linux-tools',
          ),
          RoadmapResource(
            id: 'rr007',
            title: 'Wireshark ile Ağ Analizi',
            type: ResourceType.tutorial,
            url: 'https://example.com/tutorials/wireshark-analysis',
          ),
          RoadmapResource(
            id: 'rr008',
            title: 'Metasploit Framework Rehberi',
            type: ResourceType.book,
            url: 'https://example.com/books/metasploit-guide',
          ),
        ],
        requiredSkills: ['Güvenlik Tarama', 'Zafiyet Tespiti'],
        relatedModuleIds: ['mod003'],
      ),
      RoadmapStep(
        id: 'rs004',
        title: 'Savunma ve İzleme',
        description:
            'Güvenlik duvarları, IDS/IPS, SIEM ve log analizi konularında uzmanlık.',
        order: 4,
        isCompleted: false,
        resources: [
          RoadmapResource(
            id: 'rr009',
            title: 'Güvenlik Duvarı Yapılandırma',
            type: ResourceType.tutorial,
            url: 'https://example.com/tutorials/firewall-configuration',
          ),
          RoadmapResource(
            id: 'rr010',
            title: 'SIEM Sistemleri ve Log Analizi',
            type: ResourceType.course,
            url: 'https://example.com/courses/siem-log-analysis',
          ),
        ],
        requiredSkills: ['Güvenlik Duvarı Yönetimi', 'Log Analizi', 'SIEM'],
        relatedModuleIds: ['mod001'],
      ),
      RoadmapStep(
        id: 'rs005',
        title: 'İleri Seviye Güvenlik ve Sertifikalar',
        description:
            'Uzmanlaşmak istediğiniz alan için ileri seviye eğitimler ve endüstri sertifikaları.',
        order: 5,
        isCompleted: false,
        resources: [
          RoadmapResource(
            id: 'rr011',
            title: 'CompTIA Security+ Hazırlık',
            type: ResourceType.course,
            url: 'https://example.com/courses/comptia-security-plus',
          ),
          RoadmapResource(
            id: 'rr012',
            title: 'Certified Ethical Hacker (CEH) Eğitimi',
            type: ResourceType.course,
            url: 'https://example.com/courses/ceh-preparation',
          ),
          RoadmapResource(
            id: 'rr013',
            title: 'Offensive Security Certified Professional (OSCP)',
            type: ResourceType.certification,
            url: 'https://example.com/certification/oscp',
          ),
        ],
        requiredSkills: ['İleri Güvenlik Bilgisi'],
        relatedModuleIds: [],
      ),
    ],
  ),
  Roadmap(
    id: 'rm002',
    title: 'Ağ Güvenliği Uzmanı Yol Haritası',
    description:
        'Kurumsal ağ güvenliği alanında uzmanlaşmak için izlenmesi gereken adımlar.',
    imageUrl: 'assets/images/network_security_expert.jpg',
    category: 'Uzmanlık Geliştirme',
    estimatedDurationWeeks: 40,
    careerPath: CareerPath.networkSecurity,
    progress: 10,
    steps: [
      RoadmapStep(
        id: 'rs006',
        title: 'Temel Ağ Bilgisi',
        description:
            'OSI modeli, TCP/IP protokolleri ve ağ cihazları hakkında temel bilgiler.',
        order: 1,
        isCompleted: true,
        resources: [
          RoadmapResource(
            id: 'rr014',
            title: 'Ağ Temelleri Kursu',
            type: ResourceType.course,
            url: 'https://example.com/courses/network-essentials',
          ),
          RoadmapResource(
            id: 'rr015',
            title: 'TCP/IP Protokolleri Rehberi',
            type: ResourceType.book,
            url: 'https://example.com/books/tcp-ip-guide',
          ),
        ],
        requiredSkills: ['Ağ Protokolleri', 'OSI Modeli'],
        relatedModuleIds: ['mod001'],
      ),
      RoadmapStep(
        id: 'rs007',
        title: 'Ağ Güvenliği Tehditleri',
        description:
            'Yaygın ağ saldırıları, güvenlik açıkları ve bunlara karşı savunma yöntemleri.',
        order: 2,
        isCompleted: false,
        resources: [
          RoadmapResource(
            id: 'rr016',
            title: 'Ağ Saldırıları ve Savunma Stratejileri',
            type: ResourceType.course,
            url: 'https://example.com/courses/network-attacks-defense',
          ),
          RoadmapResource(
            id: 'rr017',
            title: 'DDoS Saldırıları ve Korunma Yöntemleri',
            type: ResourceType.article,
            url: 'https://example.com/articles/ddos-protection',
          ),
        ],
        requiredSkills: ['Saldırı Vektörleri', 'Tehdit Analizi'],
        relatedModuleIds: ['mod001', 'mod003'],
      ),
    ],
  ),
  Roadmap(
    id: 'rm003',
    title: 'Bulut Güvenliği Uzmanı Yol Haritası',
    description:
        'AWS, Azure ve Google Cloud gibi bulut platformlarında güvenlik uzmanı olma yolculuğu.',
    imageUrl: 'assets/images/cloud_security.jpg',
    category: 'Bulut Teknolojileri',
    estimatedDurationWeeks: 36,
    careerPath: CareerPath.cloudSecurity,
    progress: 0,
    steps: [
      RoadmapStep(
        id: 'rs008',
        title: 'Bulut Temel Kavramları',
        description:
            'Bulut mimarisi, servis modelleri ve dağıtım modelleri hakkında temel bilgiler.',
        order: 1,
        isCompleted: false,
        resources: [
          RoadmapResource(
            id: 'rr018',
            title: 'Bulut Bilişim Temelleri',
            type: ResourceType.course,
            url: 'https://example.com/courses/cloud-computing-basics',
          ),
          RoadmapResource(
            id: 'rr019',
            title: 'IaaS, PaaS ve SaaS Karşılaştırması',
            type: ResourceType.article,
            url: 'https://example.com/articles/cloud-service-models',
          ),
        ],
        requiredSkills: ['Bulut Bilişim', 'Servis Modelleri'],
        relatedModuleIds: [],
      ),
      RoadmapStep(
        id: 'rs009',
        title: 'AWS Güvenliği',
        description:
            'Amazon Web Services güvenlik hizmetleri ve en iyi uygulamalar.',
        order: 2,
        isCompleted: false,
        resources: [
          RoadmapResource(
            id: 'rr020',
            title: 'AWS Security Fundamentals',
            type: ResourceType.course,
            url: 'https://example.com/courses/aws-security-fundamentals',
          ),
          RoadmapResource(
            id: 'rr021',
            title: 'AWS Security Best Practices',
            type: ResourceType.article,
            url: 'https://example.com/articles/aws-security-best-practices',
          ),
        ],
        requiredSkills: ['AWS', 'Cloud Security'],
        relatedModuleIds: [],
      ),
    ],
  ),
];
