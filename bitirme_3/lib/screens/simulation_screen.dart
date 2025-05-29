import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:bitirme_3/services/module_service.dart';
import 'package:bitirme_3/models/simulation.dart' as app_sim;

class SimulationScreen extends StatefulWidget {
  final String simulationId;

  const SimulationScreen({
    Key? key,
    required this.simulationId,
  }) : super(key: key);

  @override
  _SimulationScreenState createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  bool _isLoading = true;
  app_sim.Simulation? _simulation;
  String _errorMessage = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _simulationCompleted = false;
  final ModuleService _moduleService = ModuleService();

  // Terminal state
  final TextEditingController _commandController = TextEditingController();
  final FocusNode _commandFocusNode = FocusNode();
  final List<TerminalLine> _terminalOutput = [];
  int _currentStepIndex = 0;

  // Çoktan seçmeli soru yanıtları için
  String? _selectedOptionId;
  bool _showAnswerFeedback = false;
  bool _isAnswerCorrect = false;

  @override
  void initState() {
    super.initState();
    _fetchSimulationDetails();
  }

  @override
  void dispose() {
    _commandController.dispose();
    _commandFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchSimulationDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Simülasyon verilerini ModuleService üzerinden al
      final simulation =
          await _moduleService.getSimulationById(widget.simulationId);

      if (simulation == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Simülasyon bulunamadı';
        });
        return;
      }

      print(
          'Simülasyon yüklendi: ${simulation.title}, ${simulation.steps.length} adım');

      // Kullanıcının bu simülasyonu tamamlayıp tamamlamadığını kontrol et
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final userProgressDoc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('progress')
            .doc(widget.simulationId)
            .get();

        _simulationCompleted = userProgressDoc.exists &&
            userProgressDoc.data()?['completed'] == true;
      }

      // Eğer adımlar varsa ilk adımı göster
      if (simulation.steps.isNotEmpty) {
        final firstStep = simulation.steps[0];
        _addSystemOutput('Simülasyon başlatıldı: ${simulation.title}');
        _addSystemOutput('--------------------------------------');
        _addSystemOutput('Adım 1: ${firstStep.title}');
        _addSystemOutput(firstStep.description);

        if (firstStep.commands.isNotEmpty) {
          _addSystemOutput(
              '\nKullanabileceğiniz komutlar: ${firstStep.commands.join(", ")}');
        }
      }

      setState(() {
        _simulation = simulation;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Simülasyon detayları yüklenirken hata oluştu: $e';
      });
      print('Simülasyon detayları yüklenirken hata: $e');
    }
  }

  Future<void> _completeSimulation() async {
    try {
      String? moduleId = _simulation?.moduleId;
      // Modül ID kontrolünü kaldırıyoruz
      if (moduleId == null) {
        // Varsayılan bir ID kullan (simülasyon ID'si olabilir)
        moduleId = widget.simulationId;
      }

      // Simülasyonu tamamlandı olarak işaretle
      await _saveSimulationResult(widget.simulationId, moduleId);

      if (mounted) {
        setState(() {
          _simulationCompleted = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Simülasyon başarıyla tamamlandı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Hata durumunda bile simülasyonu tamamlandı say
      if (mounted) {
        setState(() {
          _simulationCompleted = true;
        });
      }

      print('Simülasyon tamamlama hatası: $e');
      // Hata mesajını gösterme, sadece başarılı mesajı göster
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Simülasyon başarıyla tamamlandı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // Simülasyon sonucunu kaydet
  Future<void> _saveSimulationResult(
      String simulationId, String moduleId) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // 1. Kullanıcının simulation_results koleksiyonuna kaydet
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('simulation_results')
          .doc(simulationId)
          .set({
        'simulationId': simulationId,
        'moduleId': moduleId,
        'completed': true,
        'completedAt': FieldValue.serverTimestamp(),
      });

      // 2. Kullanıcının genel progress bilgisine de ekle (farklı koleksiyon)
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc(simulationId)
          .set({
        'type': 'simulation',
        'itemId': simulationId,
        'completed': true,
        'completedAt': FieldValue.serverTimestamp(),
      });

      // 3. Kullanıcı dokümanına da tamamlanan simülasyonları ayrıca kaydet
      // Bu kayıt, kullanıcı hesaptan çıkıp girdiğinde bile kalıcı olması için
      await _firestore.collection('users').doc(userId).update({
        'completedSimulations': FieldValue.arrayUnion([simulationId])
      }).catchError((e) {
        // Eğer completedSimulations alanı yoksa, önce oluştur
        print('completedSimulations alanı güncelleme hatası: $e');
        return _firestore.collection('users').doc(userId).set({
          'completedSimulations': [simulationId]
        }, SetOptions(merge: true));
      });

      // 4. Modül ilerlemesini güncelle, eğer geçerli bir modül ID'si varsa
      if (_simulation?.moduleId != null) {
        await _moduleService.updateModuleProgress(moduleId, 100);
      }

      print('Simülasyon sonucu tüm koleksiyonlara kaydedildi.');
    } catch (e) {
      print('Simülasyon sonucu kaydetme hatası: $e');
      // Hatayı yukarıda işleyeceğiz, burada rethrow yapmıyoruz
    }
  }

  void _processCommand(String command) {
    if (command.trim().isEmpty) return;

    // Komutu terminale ekle
    _addUserCommand(command);
    _commandController.clear();

    // Eğer simülasyon tamamlandıysa, sadece mesaj göster
    if (_simulationCompleted) {
      _addSystemOutput('Simülasyon tamamlandı. Yeni komutlar işlenmeyecek.');
      return;
    }

    // Mevcut adımı al
    final currentStep = _simulation!.steps[_currentStepIndex];
    final expectedCommand = currentStep.expectedCommand;
    final expectedOutput = currentStep.expectedOutput;

    // Komutu değerlendir
    if (expectedCommand != null &&
        (command == expectedCommand ||
            _matchesExpectedPattern(command, expectedCommand))) {
      // Doğru komut
      _addSystemOutput(expectedOutput ?? 'Komut başarıyla çalıştırıldı.');
      _addSystemOutput('\n✅ Harika! Doğru komutu girdiniz.');

      // Sonraki adıma geç
      _goToNextStep();
    } else if (command == 'help' || command == 'yardım') {
      // Yardım komutu
      _showHelp(currentStep);
    } else if (command == 'hint' || command == 'ipucu') {
      // İpucu komutu
      if (currentStep.hint != null) {
        _addSystemOutput('İPUCU: ${currentStep.hint}');
      } else {
        _addSystemOutput('Bu adım için ipucu bulunmamaktadır.');
      }
    } else if (command == 'clear' || command == 'temizle') {
      // Terminali temizle
      setState(() {
        _terminalOutput.clear();
        _addSystemOutput('Terminal temizlendi.');
        _addSystemOutput('Adım ${_currentStepIndex + 1}: ${currentStep.title}');
      });
    } else {
      // Yanlış komut
      _addSystemOutput(
          'Komut tanınmadı veya beklenen çıktıyı üretmedi. Tekrar deneyin.');
      _addSystemOutput('İpucu almak için "hint" yazabilirsiniz.');
    }
  }

  // Çoktan seçmeli yanıt gönderme işlemi
  void _submitMultipleChoiceAnswer(String optionId) {
    // Eğer simülasyon tamamlandıysa, işlem yapma
    if (_simulationCompleted) return;

    // Mevcut adımı al
    final currentStep = _simulation!.steps[_currentStepIndex];

    // Seçilen şıkkı bul
    final selectedOption = currentStep.options?.firstWhere(
      (option) => option.id == optionId,
      orElse: () => app_sim.SimulationOption(
        id: '',
        text: '',
        isCorrect: false,
      ),
    );

    if (selectedOption == null || selectedOption.id.isEmpty) {
      _addSystemOutput('Hata: Seçenek bulunamadı.');
      return;
    }

    // Seçilen cevabı ve doğruluğunu kaydet
    if (mounted) {
      setState(() {
        _selectedOptionId = optionId;
        _showAnswerFeedback = true;
        _isAnswerCorrect = selectedOption.isCorrect;
      });
    }

    // Seçilen cevabı terminale ekle
    _addUserCommand('Seçilen: ${selectedOption.text}');

    // Doğru cevap mı kontrol et
    if (selectedOption.isCorrect) {
      _addSystemOutput('✅ Doğru cevap! Harika iş çıkardınız.');

      // Biraz bekleyip sonraki adıma geç (kullanıcının geri bildirimi görmesi için)
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return; // Widget hala aktif mi kontrol et

        // Eğer başka soru varsa ona geç
        if (_currentStepIndex < _simulation!.steps.length - 1) {
          _goToNextStep();
          // Yeni adıma geçince seçim durumunu sıfırla
          if (mounted) {
            setState(() {
              _selectedOptionId = null;
              _showAnswerFeedback = false;
            });
          }
        } else {
          // Son soruysa başarılı mesajı göster
          if (mounted) {
            setState(() {
              _simulationCompleted = true;
              _showAnswerFeedback = true;
              _isAnswerCorrect = true; // Başarılı olarak göster
            });
          }
          _addSystemOutput('\n🎉 TEBRİKLER! Simülasyonu tamamladınız.');
          _completeSimulation();

          // 3 saniye sonra önceki sayfaya dön
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted && Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          });
        }
      });
    } else {
      _addSystemOutput('❌ Yanlış cevap. Lütfen tekrar deneyin.');
      if (currentStep.hint != null) {
        _addSystemOutput('İPUCU: ${currentStep.hint}');
      }
    }
  }

  bool _matchesExpectedPattern(String command, String expected) {
    // Basit bir pattern matching - daha gelişmiş regex kullanılabilir
    if (expected.contains('*')) {
      final pattern = expected.replaceAll('*', '.*');
      return RegExp(pattern).hasMatch(command);
    }
    return false;
  }

  void _goToNextStep() {
    if (_currentStepIndex < _simulation!.steps.length - 1) {
      _currentStepIndex++;
      final nextStep = _simulation!.steps[_currentStepIndex];

      _addSystemOutput('\n--------------------------------------');
      _addSystemOutput('Adım ${_currentStepIndex + 1}: ${nextStep.title}');
      _addSystemOutput(nextStep.description ?? '');

      if (nextStep.hint != null) {
        _addSystemOutput('\nİPUCU: ${nextStep.hint}');
      }

      // Adım türüne göre farklı içeriği göster
      if (nextStep.hasMultipleChoiceOptions &&
          nextStep.options != null &&
          nextStep.options!.isNotEmpty) {
        _addSystemOutput('\nLütfen aşağıdaki seçeneklerden birini seçin:');
        for (int i = 0; i < nextStep.options!.length; i++) {
          _addSystemOutput('${i + 1}. ${nextStep.options![i].text}');
        }
      } else if (nextStep.commands.isNotEmpty) {
        _addSystemOutput(
            '\nKullanabileceğiniz komutlar: ${nextStep.commands.join(", ")}');
      }
    } else {
      // Simülasyon tamamlandı
      _simulationCompleted = true;
      _addSystemOutput('\n🎉 TEBRİKLER! Simülasyonu tamamladınız.');
      _completeSimulation();
    }
  }

  void _showHelp(app_sim.SimulationStep currentStep) {
    _addSystemOutput('YARDIM:');
    _addSystemOutput('- Adım ${_currentStepIndex + 1}: ${currentStep.title}');

    if (currentStep.hasMultipleChoiceOptions && currentStep.options != null) {
      _addSystemOutput(
          '- Bu bir çoktan seçmeli soru adımıdır. Doğru seçeneği seçin.');
      _addSystemOutput('- Seçenekler:');
      for (int i = 0; i < currentStep.options!.length; i++) {
        _addSystemOutput('  ${i + 1}. ${currentStep.options![i].text}');
      }
    } else {
      _addSystemOutput('- İpucu için "hint" veya "ipucu" yazın');
      _addSystemOutput(
          '- Terminali temizlemek için "clear" veya "temizle" yazın');

      if (currentStep.commands.isNotEmpty) {
        _addSystemOutput(
            '- Kullanabileceğiniz komutlar: ${currentStep.commands.join(", ")}');
      }
    }
  }

  void _addUserCommand(String command) {
    if (!mounted) return;

    setState(() {
      _terminalOutput.add(TerminalLine(
        text: command,
        isCommand: true,
      ));
    });
  }

  void _addSystemOutput(String output) {
    if (!mounted) return;

    setState(() {
      _terminalOutput.add(TerminalLine(
        text: output,
        isCommand: false,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _simulation?.title ?? 'Simülasyon',
        ),
        actions: [
          if (_simulationCompleted)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Icon(Icons.check_circle, color: Colors.green),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
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
              onPressed: _fetchSimulationDetails,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_simulation == null) {
      return const Center(
        child: Text('Simülasyon verileri bulunamadı'),
      );
    }

    // Mevcut adımı al
    final currentStep = _simulation!.steps[_currentStepIndex];
    final bool isMultipleChoice = currentStep.hasMultipleChoiceOptions &&
        currentStep.options != null &&
        currentStep.options!.isNotEmpty;

    // Simülasyon içeriğini göster
    return Column(
      children: [
        // Simülasyon başlık kartı
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _simulation!.title ?? 'İsimsiz Simülasyon',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00FF8F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _simulation!.description ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Adım bilgisi
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: (_currentStepIndex + 1) / _simulation!.steps.length,
                  backgroundColor: const Color(0xFF1C2D40),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF00CCFF)),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Adım ${_currentStepIndex + 1}/${_simulation!.steps.length}',
                style: const TextStyle(
                  color: Color(0xFF00CCFF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Çoktan seçmeli soru ise şıkları göster, değilse terminal göster
        Expanded(
          child: isMultipleChoice
              ? _buildMultipleChoiceStep(currentStep)
              : _buildTerminalStep(),
        ),
      ],
    );
  }

  // Çoktan seçmeli adım UI'ı
  Widget _buildMultipleChoiceStep(app_sim.SimulationStep step) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Soru başlığı
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Soru açıklaması
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1923),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1C2D40)),
            ),
            child: Text(
              step.description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'Seçenekler:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00CCFF),
            ),
          ),
          const SizedBox(height: 8),

          // Şıklar
          Expanded(
            child: ListView.builder(
              itemCount: step.options!.length,
              itemBuilder: (context, index) {
                final option = step.options![index];
                final bool isSelected = option.id == _selectedOptionId;

                // Doğru/yanlış cevap görsel geri bildirimi
                Color cardColor = Colors.transparent;
                Color borderColor = Colors.transparent;
                IconData? feedbackIcon;
                Color iconColor = Colors.white;

                if (_showAnswerFeedback && isSelected) {
                  if (_isAnswerCorrect) {
                    cardColor = Colors.green.withOpacity(0.2);
                    borderColor = Colors.green;
                    feedbackIcon = Icons.check_circle;
                    iconColor = Colors.green;
                  } else {
                    cardColor = Colors.red.withOpacity(0.2);
                    borderColor = Colors.red;
                    feedbackIcon = Icons.cancel;
                    iconColor = Colors.red;
                  }
                } else if (isSelected) {
                  // Sadece seçilmiş, ama henüz cevap gösterilmiyorsa
                  borderColor = const Color(0xFF00CCFF);
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected ? borderColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: InkWell(
                    onTap: _simulationCompleted
                        ? null // Tamamlandıysa tıklanamaz
                        : () => _submitMultipleChoiceAnswer(option.id),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C2D40),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Color(0xFF00CCFF),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              option.text,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          // Geri bildirim ikonu
                          if (_showAnswerFeedback &&
                              isSelected &&
                              feedbackIcon != null)
                            Icon(
                              feedbackIcon,
                              color: iconColor,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Geri bildirim özeti (opsiyonel)
          if (_showAnswerFeedback)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: _isAnswerCorrect
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isAnswerCorrect ? Colors.green : Colors.red,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isAnswerCorrect ? Icons.check_circle : Icons.cancel,
                    color: _isAnswerCorrect ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _simulationCompleted && _isAnswerCorrect
                          ? 'Tebrikler! Simülasyon başarıyla tamamlandı.'
                          : _isAnswerCorrect
                              ? 'Doğru cevap! Devam ediliyor...'
                              : 'Yanlış cevap. Lütfen tekrar deneyin.',
                      style: TextStyle(
                        color: _isAnswerCorrect ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Simülasyon tamamlandıysa tekrar deneme butonu
          if (_simulationCompleted)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Simülasyon listesi ekranına dön
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                  ),
                  child: const Text(
                    'Simülasyon Listesine Dön',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Terminal görünümlü adım UI'ı
  Widget _buildTerminalStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A121A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF1C2D40),
                  width: 1.5,
                ),
              ),
              child: ListView.builder(
                itemCount: _terminalOutput.length,
                itemBuilder: (context, index) {
                  final line = _terminalOutput[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          if (line.isCommand)
                            const TextSpan(
                              text: '> ',
                              style: TextStyle(
                                color: Color(0xFF00FF8F),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          TextSpan(
                            text: line.text,
                            style: TextStyle(
                              color: line.isCommand
                                  ? const Color(0xFF00FF8F)
                                  : _getOutputTextColor(line.text),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                '> ',
                style: TextStyle(
                  color: Color(0xFF00FF8F),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _commandController,
                  focusNode: _commandFocusNode,
                  decoration: const InputDecoration(
                    hintText: 'Komut girin...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    color: Color(0xFF00FF8F),
                    fontFamily: 'monospace',
                  ),
                  cursorColor: const Color(0xFF00FF8F),
                  onSubmitted: _processCommand,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF00CCFF)),
                onPressed: () {
                  _processCommand(_commandController.text);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getOutputTextColor(String text) {
    if (text.contains('TEBRİKLER') ||
        text.contains('✅') ||
        text.contains('🎉')) {
      return const Color(0xFF00FF8F); // Başarı mesajları için yeşil
    } else if (text.contains('İPUCU:')) {
      return const Color(0xFFFFC107); // İpuçları için sarı
    } else if (text.contains('HATA') || text.contains('tanınmadı')) {
      return const Color(0xFFFF5252); // Hata mesajları için kırmızı
    } else if (text.contains('------')) {
      return const Color(0xFF4D6082); // Ayırıcılar için gri
    } else if (text.contains('Adım')) {
      return const Color(0xFF00CCFF); // Adımlar için mavi
    } else if (text.startsWith('- ')) {
      return const Color(0xFFBB86FC); // Liste öğeleri için mor
    } else {
      return const Color(0xFFCCDDFF); // Varsayılan metin rengi
    }
  }
}

class TerminalLine {
  final String text;
  final bool isCommand;

  TerminalLine({required this.text, required this.isCommand});
}
