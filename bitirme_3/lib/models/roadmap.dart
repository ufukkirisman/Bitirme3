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
  });
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
