import 'package:cloud_firestore/cloud_firestore.dart';

class Simulation {
  final String id;
  final String title;
  final String description;
  final SimulationType type;
  final int difficultyLevel; // 1-5 arası zorluk seviyesi
  final bool isCompleted;
  final String imageUrl;
  final List<SimulationStep> steps;
  final Map<String, dynamic>? parameters; // Simülasyon parametreleri
  final String? moduleId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Simulation({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficultyLevel,
    this.isCompleted = false,
    required this.imageUrl,
    required this.steps,
    this.parameters,
    this.moduleId,
    this.createdAt,
    this.updatedAt,
  });

  factory Simulation.fromMap(Map<String, dynamic> map, String docId) {
    List<SimulationStep> stepsList = [];
    if (map['steps'] != null) {
      stepsList = List<SimulationStep>.from(
        (map['steps'] as List).map(
          (step) => SimulationStep.fromMap(step),
        ),
      );
    }

    SimulationType simulationType;
    switch (map['type']) {
      case 'penetrationTesting':
        simulationType = SimulationType.penetrationTesting;
        break;
      case 'forensicAnalysis':
        simulationType = SimulationType.forensicAnalysis;
        break;
      case 'malwareAnalysis':
        simulationType = SimulationType.malwareAnalysis;
        break;
      case 'cryptography':
        simulationType = SimulationType.cryptography;
        break;
      case 'socialEngineering':
        simulationType = SimulationType.socialEngineering;
        break;
      case 'networkAnalysis':
      default:
        simulationType = SimulationType.networkAnalysis;
        break;
    }

    return Simulation(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: simulationType,
      difficultyLevel: map['difficultyLevel'] ?? 1,
      isCompleted: map['isCompleted'] ?? false,
      imageUrl: map['imageUrl'] ?? '',
      steps: stepsList,
      parameters: map['parameters'],
      moduleId: map['moduleId'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    final result = {
      'title': title,
      'description': description,
      'type': _getTypeString(type),
      'difficultyLevel': difficultyLevel,
      'isCompleted': isCompleted,
      'imageUrl': imageUrl,
      'steps': steps.map((step) => step.toMap()).toList(),
    };

    if (parameters != null) {
      result['parameters'] = parameters as Map<String, dynamic>;
    }

    if (moduleId != null) {
      result['moduleId'] = moduleId as String;
    }

    return result;
  }

  String _getTypeString(SimulationType type) {
    switch (type) {
      case SimulationType.penetrationTesting:
        return 'penetrationTesting';
      case SimulationType.forensicAnalysis:
        return 'forensicAnalysis';
      case SimulationType.malwareAnalysis:
        return 'malwareAnalysis';
      case SimulationType.cryptography:
        return 'cryptography';
      case SimulationType.socialEngineering:
        return 'socialEngineering';
      case SimulationType.networkAnalysis:
        return 'networkAnalysis';
    }
  }
}

class SimulationStep {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final List<String> commands;
  final String expectedOutput;
  final String? expectedCommand;
  final String? hint;
  final bool isCompleted;
  final List<SimulationOption>?
      options; // Çoktan seçmeli yanıtlar için seçenekler
  final bool
      hasMultipleChoiceOptions; // Adımın çoktan seçmeli bir soru içerip içermediği

  SimulationStep({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.commands,
    required this.expectedOutput,
    this.expectedCommand,
    this.hint,
    this.isCompleted = false,
    this.options,
    this.hasMultipleChoiceOptions = false,
  });

  factory SimulationStep.fromMap(Map<String, dynamic> map) {
    List<String> commandsList = [];
    if (map['commands'] != null) {
      commandsList = List<String>.from(map['commands']);
    }

    List<SimulationOption>? optionsList;
    if (map['options'] != null) {
      optionsList = List<SimulationOption>.from(
        (map['options'] as List).map(
          (option) => SimulationOption.fromMap(option),
        ),
      );
    }

    return SimulationStep(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      commands: commandsList,
      expectedOutput: map['expectedOutput'] ?? '',
      expectedCommand: map['expectedCommand'],
      hint: map['hint'],
      isCompleted: map['isCompleted'] ?? false,
      options: optionsList,
      hasMultipleChoiceOptions: map['hasMultipleChoiceOptions'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    final result = {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'commands': commands,
      'expectedOutput': expectedOutput,
      'isCompleted': isCompleted,
      'hasMultipleChoiceOptions': hasMultipleChoiceOptions,
    };

    if (expectedCommand != null) {
      result['expectedCommand'] = expectedCommand;
    }

    if (hint != null) {
      result['hint'] = hint;
    }

    if (options != null) {
      result['options'] = options!.map((option) => option.toMap()).toList();
    }

    return result;
  }
}

class SimulationOption {
  final String id;
  final String text;
  final bool isCorrect;

  SimulationOption({
    required this.id,
    required this.text,
    required this.isCorrect,
  });

  factory SimulationOption.fromMap(Map<String, dynamic> map) {
    return SimulationOption(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      isCorrect: map['isCorrect'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isCorrect': isCorrect,
    };
  }
}

enum SimulationType {
  networkAnalysis, // Ağ analizi
  penetrationTesting, // Sızma testi
  forensicAnalysis, // Adli analiz
  malwareAnalysis, // Zararlı yazılım analizi
  cryptography, // Kriptografi uygulamaları
  socialEngineering // Sosyal mühendislik senaryoları
}
