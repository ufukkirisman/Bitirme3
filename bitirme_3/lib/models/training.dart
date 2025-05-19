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
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    this.createdAt,
    this.updatedAt,
  });

  factory Training.fromMap(Map<String, dynamic> map, String id) {
    List<TrainingContent> contentsList = [];
    if (map['contents'] != null) {
      contentsList = List<TrainingContent>.from(
        (map['contents'] as List).map(
          (content) => TrainingContent.fromMap(content, ''),
        ),
      );
    }

    List<String> skillsList = [];
    if (map['skills'] != null) {
      skillsList = List<String>.from(map['skills']);
    }

    return Training(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      contents: contentsList,
      progress: map['progress'] ?? 0,
      instructor: map['instructor'] ?? '',
      durationHours: map['durationHours'] ?? 0,
      level: _getTrainingLevelFromString(map['level']),
      skills: skillsList,
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
      'contents': contents.map((content) => content.toMap()).toList(),
      'progress': progress,
      'instructor': instructor,
      'durationHours': durationHours,
      'level': _getTrainingLevelString(level),
      'skills': skills,
      // createdAt ve updatedAt Firestore tarafında oluşturulacak
    };
  }

  static TrainingLevel _getTrainingLevelFromString(String? levelStr) {
    switch (levelStr) {
      case 'beginner':
        return TrainingLevel.beginner;
      case 'intermediate':
        return TrainingLevel.intermediate;
      case 'advanced':
        return TrainingLevel.advanced;
      case 'expert':
        return TrainingLevel.expert;
      default:
        return TrainingLevel.beginner;
    }
  }

  static String _getTrainingLevelString(TrainingLevel level) {
    switch (level) {
      case TrainingLevel.beginner:
        return 'beginner';
      case TrainingLevel.intermediate:
        return 'intermediate';
      case TrainingLevel.advanced:
        return 'advanced';
      case TrainingLevel.expert:
        return 'expert';
    }
  }
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

  factory TrainingContent.fromMap(Map<String, dynamic> map, String id) {
    return TrainingContent(
      id: id.isNotEmpty ? id : (map['id'] ?? ''),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: _getContentTypeFromString(map['type']),
      durationMinutes: map['durationMinutes'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
      resourceUrl: map['resourceUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': _getContentTypeString(type),
      'durationMinutes': durationMinutes,
      'isCompleted': isCompleted,
      'resourceUrl': resourceUrl,
    };
  }

  static TrainingContentType _getContentTypeFromString(String? typeStr) {
    switch (typeStr) {
      case 'video':
        return TrainingContentType.video;
      case 'document':
        return TrainingContentType.document;
      case 'presentation':
        return TrainingContentType.presentation;
      case 'codeLab':
        return TrainingContentType.codeLab;
      case 'exercise':
        return TrainingContentType.exercise;
      case 'certification':
        return TrainingContentType.certification;
      default:
        return TrainingContentType.video;
    }
  }

  static String _getContentTypeString(TrainingContentType type) {
    switch (type) {
      case TrainingContentType.video:
        return 'video';
      case TrainingContentType.document:
        return 'document';
      case TrainingContentType.presentation:
        return 'presentation';
      case TrainingContentType.codeLab:
        return 'codeLab';
      case TrainingContentType.exercise:
        return 'exercise';
      case TrainingContentType.certification:
        return 'certification';
    }
  }
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
