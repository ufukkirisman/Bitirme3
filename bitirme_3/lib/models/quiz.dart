class Quiz {
  final String id;
  final String title;
  final String description;
  final List<Question> questions;
  final int timeLimit; // Dakika cinsinden zaman sınırı
  final bool isCompleted;
  final int? userScore;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
    required this.timeLimit,
    this.isCompleted = false,
    this.userScore,
  });
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
}

enum QuestionType {
  multipleChoice, // Çoktan seçmeli
  trueFalse, // Doğru/Yanlış
  fillInBlank, // Boşluk doldurma
  matching, // Eşleştirme
  openEnded // Açık uçlu
}
