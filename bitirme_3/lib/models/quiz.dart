class Quiz {
  final String id;
  final String title;
  final String description;
  final List<Question> questions;
  final int timeLimit; // Dakika cinsinden zaman sınırı
  final bool isCompleted;
  final int? userScore;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? moduleId;
  final String? trainingId;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
    required this.timeLimit,
    this.isCompleted = false,
    this.userScore,
    this.createdAt,
    this.updatedAt,
    this.moduleId,
    this.trainingId,
  });

  factory Quiz.fromMap(Map<String, dynamic> map, String docId) {
    List<Question> questionsList = [];
    if (map['questions'] != null) {
      questionsList = List<Question>.from(
        (map['questions'] as List).map(
          (q) => Question.fromMap(q as Map<String, dynamic>, q['id'] ?? ''),
        ),
      );
    }

    return Quiz(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      questions: questionsList,
      timeLimit: map['timeLimit'] ?? 30,
      isCompleted: map['isCompleted'] ?? false,
      userScore: map['userScore'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : null,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as dynamic).toDate()
          : null,
      moduleId: map['moduleId'],
      trainingId: map['trainingId'],
    );
  }

  Map<String, dynamic> toMap() {
    final result = {
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toMap()).toList(),
      'timeLimit': timeLimit,
      'isCompleted': isCompleted,
      'userScore': userScore,
    };

    if (moduleId != null) {
      result['moduleId'] = moduleId;
    }

    if (trainingId != null) {
      result['trainingId'] = trainingId;
    }

    return result;
  }
}

class Question {
  final String id;
  final String text;
  final List<Answer> answers;
  final QuestionType type;
  final String? explanation; // Doğru cevabın açıklaması
  final int points; // Bu sorunun değeri kaç puan

  Question({
    required this.id,
    required this.text,
    required this.answers,
    required this.type,
    this.explanation,
    required this.points,
  });

  factory Question.fromMap(Map<String, dynamic> map, String id) {
    List<Answer> answersList = [];
    if (map['answers'] != null) {
      answersList = List<Answer>.from(
        (map['answers'] as List).map(
          (answer) => Answer.fromMap(answer, ''),
        ),
      );
    }

    return Question(
      id: id.isNotEmpty ? id : (map['id'] ?? ''),
      text: map['text'] ?? '',
      answers: answersList,
      type: _getQuestionTypeFromString(map['type']),
      explanation: map['explanation'],
      points: map['points'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'answers': answers.map((answer) => answer.toMap()).toList(),
      'type': _getQuestionTypeString(type),
      'explanation': explanation,
      'points': points,
    };
  }

  static QuestionType _getQuestionTypeFromString(String? typeStr) {
    switch (typeStr) {
      case 'multipleChoice':
        return QuestionType.multipleChoice;
      case 'trueFalse':
        return QuestionType.trueFalse;
      case 'fillInBlank':
        return QuestionType.fillInBlank;
      case 'matching':
        return QuestionType.matching;
      case 'openEnded':
        return QuestionType.openEnded;
      default:
        return QuestionType.multipleChoice;
    }
  }

  static String _getQuestionTypeString(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'multipleChoice';
      case QuestionType.trueFalse:
        return 'trueFalse';
      case QuestionType.fillInBlank:
        return 'fillInBlank';
      case QuestionType.matching:
        return 'matching';
      case QuestionType.openEnded:
        return 'openEnded';
    }
  }
}

class Answer {
  final String id;
  final String text;
  final bool isCorrect;

  Answer({
    required this.id,
    required this.text,
    required this.isCorrect,
  });

  factory Answer.fromMap(Map<String, dynamic> map, String id) {
    return Answer(
      id: id.isNotEmpty ? id : (map['id'] ?? ''),
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

enum QuestionType {
  multipleChoice, // Çoktan seçmeli
  trueFalse, // Doğru/Yanlış
  fillInBlank, // Boşluk doldurma
  matching, // Eşleştirme
  openEnded // Açık uçlu
}
