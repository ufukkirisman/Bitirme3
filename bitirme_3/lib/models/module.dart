class Module {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final List<Lesson> lessons;
  final int progress; // 0-100 arası tamamlanma yüzdesi

  Module({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.lessons,
    this.progress = 0,
  });
}

class Lesson {
  final String id;
  final String title;
  final String content;
  final LessonType type;
  final bool isCompleted;
  final int durationMinutes;

  // Quiz veya simülasyon gibi içerik bağlantıları
  final String? quizId;
  final String? simulationId;

  Lesson({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.isCompleted = false,
    required this.durationMinutes,
    this.quizId,
    this.simulationId,
  });
}

enum LessonType {
  theory, // Teorik bilgi
  quiz, // Test
  simulation, // Pratik uygulama/simülasyon
  video, // Video ders
  assignment // Ödev
}
