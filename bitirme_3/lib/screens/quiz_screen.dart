import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:bitirme_3/services/database_service.dart';

class QuizScreen extends StatefulWidget {
  final String quizId;

  const QuizScreen({
    Key? key,
    required this.quizId,
  }) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _quizData;
  String _errorMessage = '';
  final DatabaseService _databaseService = DatabaseService();

  // Quiz durumu
  int _currentQuestionIndex = 0;
  List<Map<String, dynamic>> _questions = [];
  Map<int, int> _userAnswers = {}; // questionIndex -> answerIndex
  bool _quizCompleted = false;
  int _score = 0;
  int _totalPoints = 0;

  // Süre sayacı
  int _timeRemaining = 0; // saniye cinsinden
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchQuizDetails();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchQuizDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Quiz verilerini DatabaseService üzerinden al
      final quizDoc = await _databaseService.getQuizById(widget.quizId);

      if (quizDoc == null || !quizDoc.exists) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Quiz bulunamadı';
        });
        return;
      }

      final data = quizDoc.data() as Map<String, dynamic>;
      final questionsData = data['questions'] as List<dynamic>;

      // Soruları dönüştür
      _questions = questionsData.map((q) => q as Map<String, dynamic>).toList();

      // Toplam puanı hesapla
      _totalPoints = _questions.fold(
          0, (sum, question) => sum + (question['points'] as int? ?? 1));

      // Süre sayacını başlat
      _timeRemaining =
          (data['timeLimit'] as int? ?? 10) * 60; // dakikayı saniyeye çevir
      _startTimer();

      setState(() {
        _quizData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Quiz detayları yüklenirken hata oluştu: $e';
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        _submitQuiz();
      }
    });
  }

  void _submitQuiz() {
    _timer?.cancel();

    // Puanı hesapla
    int correctAnswers = 0;
    _score = 0;

    _userAnswers.forEach((questionIndex, answerIndex) {
      final question = _questions[questionIndex];
      final answers = question['answers'] as List<dynamic>;

      if (answerIndex < answers.length) {
        final selectedAnswer = answers[answerIndex] as Map<String, dynamic>;
        if (selectedAnswer['isCorrect'] == true) {
          correctAnswers++;
          _score += question['points'] as int? ?? 1;
        }
      }
    });

    setState(() {
      _quizCompleted = true;
    });

    // Quiz sonucunu Firestore'a kaydet
    _saveQuizResult();
  }

  Future<void> _saveQuizResult() async {
    try {
      String? moduleId;
      if (_quizData != null && _quizData!.containsKey('moduleId')) {
        moduleId = _quizData!['moduleId'];
      }

      if (moduleId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Modül bilgisi bulunamadı'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Quiz sonucunu DatabaseService üzerinden kaydet
      await _databaseService.saveQuizResult(
        widget.quizId,
        moduleId,
        _score,
        _totalPoints,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quiz sonucu kaydedilirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _selectAnswer(int answerIndex) {
    setState(() {
      _userAnswers[_currentQuestionIndex] = answerIndex;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _submitQuiz();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Quiz tamamlanmadıysa onay iste
        if (!_quizCompleted && _questions.isNotEmpty) {
          return await _showExitConfirmationDialog() ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _quizData?['title'] ?? 'Quiz',
          ),
          actions: [
            if (!_quizCompleted && _timeRemaining > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: Text(
                    _formatTime(_timeRemaining),
                    style: TextStyle(
                      color: _timeRemaining < 60 ? Colors.red : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? _buildErrorView()
                : _quizCompleted
                    ? _buildResultView()
                    : _questions.isEmpty
                        ? const Center(
                            child: Text('Bu quizde soru bulunmamaktadır'))
                        : _buildQuizView(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _errorMessage,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchQuizDetails,
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizView() {
    final currentQuestion = _questions[_currentQuestionIndex];
    final questionText = currentQuestion['text'] ?? 'Soru metni bulunamadı';
    final answers = currentQuestion['answers'] as List<dynamic>;
    final selectedAnswerIndex = _userAnswers[_currentQuestionIndex];

    return Column(
      children: [
        // İlerleme göstergesi
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            children: [
              Flexible(
                flex: _currentQuestionIndex + 1,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00AACC), Color(0xFF00FF8F)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FF8F).withOpacity(0.5),
                        blurRadius: 6,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
              Flexible(
                flex: _questions.length - (_currentQuestionIndex + 1),
                child: Container(),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Soru numarası ve toplam soru sayısı
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF101823),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF00AACC), width: 1),
                      ),
                      child: Text(
                        'Soru ${_currentQuestionIndex + 1}/${_questions.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00CCFF),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF101823),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF00FF8F), width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Color(0xFF00FF8F),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${currentQuestion['points'] ?? 1} Puan',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00FF8F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Soru metni
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF101823), Color(0xFF162435)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: const Color(0xFF1C2D40), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.help_outline,
                        color: Color(0xFF00CCFF),
                        size: 28,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        questionText,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          height: 1.4,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Cevap seçenekleri
                ...List.generate(answers.length, (index) {
                  final answer = answers[index] as Map<String, dynamic>;
                  final isSelected = selectedAnswerIndex == index;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GestureDetector(
                      onTap: () => _selectAnswer(index),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF00AACC),
                                    Color(0xFF008899)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF101823),
                                    Color(0xFF101823)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF00CCFF)
                                : const Color(0xFF1C2D40),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF00CCFF)
                                        .withOpacity(0.2),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 0),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? const Color(0xFF00CCFF)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF00CCFF)
                                      : const Color(0xFF1C2D40),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 18,
                                      color: Colors.white,
                                    )
                                  : Center(
                                      child: Text(
                                        String.fromCharCode(
                                            65 + index), // A, B, C, D...
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF00CCFF),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                answer['text'] ?? 'Cevap metni bulunamadı',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white70,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // Navigasyon butonları
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1923),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Geri butonu
              if (_currentQuestionIndex > 0)
                OutlinedButton.icon(
                  onPressed: _previousQuestion,
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Önceki'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00CCFF),
                    side:
                        const BorderSide(color: Color(0xFF00AACC), width: 1.5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              else
                const SizedBox(width: 115), // Boşluk

              // İleri veya Bitir butonu
              ElevatedButton.icon(
                onPressed: selectedAnswerIndex != null
                    ? _currentQuestionIndex < _questions.length - 1
                        ? _nextQuestion
                        : _submitQuiz
                    : null,
                icon: Icon(
                  _currentQuestionIndex < _questions.length - 1
                      ? Icons.arrow_forward
                      : Icons.check_circle,
                  size: 16,
                ),
                label: Text(
                  _currentQuestionIndex < _questions.length - 1
                      ? 'Sonraki'
                      : 'Tamamla',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AACC),
                  disabledBackgroundColor: Colors.grey.shade700,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  elevation: 4,
                  shadowColor: const Color(0xFF008899),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    final percentage = (_score / _totalPoints) * 100;
    final isPassed = percentage >= 70;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Animasyonlu başarı veya başarısızlık ikonu
          Icon(
            isPassed ? Icons.check_circle : Icons.cancel,
            size: 120,
            color: isPassed ? Colors.green : Colors.red,
          ),

          const SizedBox(height: 24),

          // Quiz sonuç başlığı
          Text(
            isPassed ? 'Tebrikler!' : 'Üzgünüm!',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isPassed ? Colors.green : Colors.red,
            ),
          ),

          const SizedBox(height: 12),

          // Sonuç açıklaması
          Text(
            isPassed
                ? 'Quiz\'i başarıyla tamamladınız!'
                : 'Quiz\'i geçebilmek için yeterli puan alamadınız.',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 36),

          // Skor göstergesi
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPassed
                    ? Colors.green.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: isPassed ? Colors.green : Colors.red,
                  ),
                ),
                Text(
                  'Puanınız: $_score / $_totalPoints',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // Puan kartı
          Card(
            color: Colors.grey.shade800,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildResultRow(
                    'Toplam Soru',
                    '${_questions.length}',
                    Icons.help_outline,
                  ),
                  const Divider(color: Colors.grey),
                  _buildResultRow(
                    'Doğru Cevaplar',
                    '$_score',
                    Icons.check_circle_outline,
                    valueColor: Colors.green,
                  ),
                  const Divider(color: Colors.grey),
                  _buildResultRow(
                    'Yanlış Cevaplar',
                    '${_questions.length - _score}',
                    Icons.cancel_outlined,
                    valueColor: Colors.red,
                  ),
                  const Divider(color: Colors.grey),
                  _buildResultRow(
                    'Geçiş Durumu',
                    isPassed ? 'Başarılı' : 'Başarısız',
                    isPassed ? Icons.verified : Icons.cancel,
                    valueColor: isPassed ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Butonlar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Modüle Dön'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(width: 16),
              if (!isPassed)
                ElevatedButton.icon(
                  onPressed: () {
                    // Quiz'i baştan başlat
                    setState(() {
                      _currentQuestionIndex = 0;
                      _userAnswers.clear();
                      _quizCompleted = false;
                      _timeRemaining =
                          (_quizData?['timeLimit'] as int? ?? 10) * 60;
                    });
                    _startTimer();
                  },
                  icon: const Icon(Icons.replay),
                  label: const Text('Tekrar Dene'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, IconData icon,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00AACC).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF00CCFF), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: (valueColor ?? const Color(0xFF00CCFF)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (valueColor ?? const Color(0xFF00CCFF)).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: valueColor ?? const Color(0xFF00CCFF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showExitConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Quiz\'den Çıkmak İstiyor musunuz?'),
        content: const Text(
          'Eğer şimdi çıkarsanız, ilerlemeniz kaydedilmeyecek ve quiz\'i baştan almanız gerekecek.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal', style: TextStyle(color: Colors.cyan)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Çık'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
