class Roadmap {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final List<RoadmapStep> steps;
  final String category;
  final int estimatedDurationWeeks;
  final CareerPath careerPath;
  final int progress; // 0-100 arası tamamlanma yüzdesi
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Roadmap({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.steps,
    required this.category,
    required this.estimatedDurationWeeks,
    required this.careerPath,
    this.progress = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Roadmap.fromMap(Map<String, dynamic> map, String id) {
    List<RoadmapStep> stepsList = [];
    if (map['steps'] != null) {
      stepsList = List<RoadmapStep>.from(
        (map['steps'] as List).map(
          (step) => RoadmapStep.fromMap(step, ''),
        ),
      );
    }

    return Roadmap(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      steps: stepsList,
      category: map['category'] ?? '',
      estimatedDurationWeeks: map['estimatedDurationWeeks'] ?? 0,
      careerPath: _getCareerPathFromString(map['careerPath']),
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
      'steps': steps.map((step) => step.toMap()).toList(),
      'category': category,
      'estimatedDurationWeeks': estimatedDurationWeeks,
      'careerPath': _getCareerPathString(careerPath),
      'progress': progress,
      // createdAt ve updatedAt Firestore tarafında oluşturulacak
    };
  }

  static CareerPath _getCareerPathFromString(String? pathStr) {
    switch (pathStr) {
      case 'networkSecurity':
        return CareerPath.networkSecurity;
      case 'applicationSecurity':
        return CareerPath.applicationSecurity;
      case 'cloudSecurity':
        return CareerPath.cloudSecurity;
      case 'penetrationTesting':
        return CareerPath.penetrationTesting;
      case 'securityAnalyst':
        return CareerPath.securityAnalyst;
      case 'incidentResponse':
        return CareerPath.incidentResponse;
      case 'cryptography':
        return CareerPath.cryptography;
      default:
        return CareerPath.networkSecurity;
    }
  }

  static String _getCareerPathString(CareerPath path) {
    switch (path) {
      case CareerPath.networkSecurity:
        return 'networkSecurity';
      case CareerPath.applicationSecurity:
        return 'applicationSecurity';
      case CareerPath.cloudSecurity:
        return 'cloudSecurity';
      case CareerPath.penetrationTesting:
        return 'penetrationTesting';
      case CareerPath.securityAnalyst:
        return 'securityAnalyst';
      case CareerPath.incidentResponse:
        return 'incidentResponse';
      case CareerPath.cryptography:
        return 'cryptography';
    }
  }
}

class RoadmapStep {
  final String id;
  final String title;
  final String description;
  final int order;
  final bool isCompleted;
  final List<RoadmapResource> resources;
  final List<String>? requiredSkills;
  final List<String>? relatedModuleIds;

  RoadmapStep({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    this.isCompleted = false,
    required this.resources,
    this.requiredSkills,
    this.relatedModuleIds,
  });

  factory RoadmapStep.fromMap(Map<String, dynamic> map, String id) {
    List<RoadmapResource> resourcesList = [];
    if (map['resources'] != null) {
      resourcesList = List<RoadmapResource>.from(
        (map['resources'] as List).map(
          (resource) => RoadmapResource.fromMap(resource, ''),
        ),
      );
    }

    List<String>? requiredSkillsList;
    if (map['requiredSkills'] != null) {
      requiredSkillsList = List<String>.from(map['requiredSkills']);
    }

    List<String>? relatedModuleIdsList;
    if (map['relatedModuleIds'] != null) {
      relatedModuleIdsList = List<String>.from(map['relatedModuleIds']);
    }

    return RoadmapStep(
      id: id.isNotEmpty ? id : (map['id'] ?? ''),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      order: map['order'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
      resources: resourcesList,
      requiredSkills: requiredSkillsList,
      relatedModuleIds: relatedModuleIdsList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'order': order,
      'isCompleted': isCompleted,
      'resources': resources.map((resource) => resource.toMap()).toList(),
      'requiredSkills': requiredSkills,
      'relatedModuleIds': relatedModuleIds,
    };
  }
}

class RoadmapResource {
  final String id;
  final String title;
  final ResourceType type;
  final String url;
  final bool isCompleted;
  final bool isRequired;

  RoadmapResource({
    required this.id,
    required this.title,
    required this.type,
    required this.url,
    this.isCompleted = false,
    this.isRequired = true,
  });

  factory RoadmapResource.fromMap(Map<String, dynamic> map, String id) {
    return RoadmapResource(
      id: id.isNotEmpty ? id : (map['id'] ?? ''),
      title: map['title'] ?? '',
      type: _getResourceTypeFromString(map['type']),
      url: map['url'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      isRequired: map['isRequired'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': _getResourceTypeString(type),
      'url': url,
      'isCompleted': isCompleted,
      'isRequired': isRequired,
    };
  }

  static ResourceType _getResourceTypeFromString(String? typeStr) {
    switch (typeStr) {
      case 'article':
        return ResourceType.article;
      case 'video':
        return ResourceType.video;
      case 'course':
        return ResourceType.course;
      case 'tutorial':
        return ResourceType.tutorial;
      case 'book':
        return ResourceType.book;
      case 'tool':
        return ResourceType.tool;
      case 'certification':
        return ResourceType.certification;
      default:
        return ResourceType.article;
    }
  }

  static String _getResourceTypeString(ResourceType type) {
    switch (type) {
      case ResourceType.article:
        return 'article';
      case ResourceType.video:
        return 'video';
      case ResourceType.course:
        return 'course';
      case ResourceType.tutorial:
        return 'tutorial';
      case ResourceType.book:
        return 'book';
      case ResourceType.tool:
        return 'tool';
      case ResourceType.certification:
        return 'certification';
    }
  }
}

enum ResourceType {
  article,
  video,
  course,
  tutorial,
  book,
  tool,
  certification,
}

enum CareerPath {
  networkSecurity,
  applicationSecurity,
  cloudSecurity,
  penetrationTesting,
  securityAnalyst,
  incidentResponse,
  cryptography,
}
