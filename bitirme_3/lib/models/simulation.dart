class Simulation {
  final String id;
  final String title;
  final String description;
  final SimulationType type;
  final int difficultyLevel; // 1-5 arası zorluk seviyesi
  final bool isCompleted;
  final String? imageUrl;
  final List<SimulationStep> steps;
  final Map<String, dynamic>? parameters; // Simülasyon parametreleri

  Simulation({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficultyLevel,
    this.isCompleted = false,
    this.imageUrl,
    required this.steps,
    this.parameters,
  });
}

class SimulationStep {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final List<String>? commands; // Kullanılabilecek komutlar
  final String? expectedOutput; // Beklenen çıktı
  final bool isCompleted;

  SimulationStep({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.commands,
    this.expectedOutput,
    this.isCompleted = false,
  });
}

enum SimulationType {
  networkAnalysis, // Ağ analizi
  penetrationTesting, // Sızma testi
  forensicAnalysis, // Adli analiz
  malwareAnalysis, // Zararlı yazılım analizi
  cryptography, // Kriptografi uygulamaları
  socialEngineering // Sosyal mühendislik senaryoları
}
