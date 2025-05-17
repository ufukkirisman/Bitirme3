class Training {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final List<TrainingContent> contents;
  final int progress; // 0-100 arası tamamlanma yüzdesi
  final String instructor;
  final int durationHours;
  final TrainingLevel level;
  final List<String> skills;

  Training({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.contents,
    this.progress = 0,
    required this.instructor,
    required this.durationHours,
    required this.level,
    required this.skills,
  });
}

class TrainingContent {
  final String id;
  final String title;
  final String description;
  final TrainingContentType type;
  final int durationMinutes;
  final bool isCompleted;
  final String? resourceUrl;

  TrainingContent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.durationMinutes,
    this.isCompleted = false,
    this.resourceUrl,
  });
}

enum TrainingContentType {
  video,
  document,
  presentation,
  codeLab,
  exercise,
  certification,
}

enum TrainingLevel {
  beginner,
  intermediate,
  advanced,
  expert,
}
