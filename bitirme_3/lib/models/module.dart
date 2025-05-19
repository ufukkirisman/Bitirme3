class Module {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final List<Lesson> lessons;
  final int progress; // 0-100 arası tamamlanma yüzdesi
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Module({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.lessons,
    this.progress = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Module.fromMap(Map<String, dynamic> map, String id) {
    List<Lesson> lessonsList = [];
    if (map['lessons'] != null) {
      lessonsList = List<Lesson>.from(
        (map['lessons'] as List).map(
          (lesson) => Lesson.fromMap(lesson, ''),
        ),
      );
    }

    return Module(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      lessons: lessonsList,
      progress: map['progress'] ?? 0,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : null,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as dynamic).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'progress': progress,
      'lessons': lessons.map((lesson) => lesson.toMap()).toList(),
      // createdAt ve updatedAt Firestore tarafında oluşturulacak
    };
  }
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

  factory Lesson.fromMap(Map<String, dynamic> map, String id) {
    return Lesson(
      id: id.isNotEmpty ? id : (map['id'] ?? ''),
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      type: _getLessonTypeFromString(map['type']),
      isCompleted: map['isCompleted'] ?? false,
      durationMinutes: map['durationMinutes'] ?? 0,
      quizId: map['quizId'],
      simulationId: map['simulationId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': _getLessonTypeString(type),
      'isCompleted': isCompleted,
      'durationMinutes': durationMinutes,
      'quizId': quizId,
      'simulationId': simulationId,
    };
  }

  static LessonType _getLessonTypeFromString(String? typeStr) {
    switch (typeStr) {
      case 'theory':
        return LessonType.theory;
      case 'quiz':
        return LessonType.quiz;
      case 'simulation':
        return LessonType.simulation;
      case 'video':
        return LessonType.video;
      case 'assignment':
        return LessonType.assignment;
      default:
        return LessonType.theory;
    }
  }

  static String _getLessonTypeString(LessonType type) {
    switch (type) {
      case LessonType.theory:
        return 'theory';
      case LessonType.quiz:
        return 'quiz';
      case LessonType.simulation:
        return 'simulation';
      case LessonType.video:
        return 'video';
      case LessonType.assignment:
        return 'assignment';
    }
  }
}

enum LessonType {
  theory, // Teorik bilgi
  quiz, // Test
  simulation, // Pratik uygulama/simülasyon
  video, // Video ders
  assignment // Ödev
}
