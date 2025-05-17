import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:bitirme_3/services/database_service.dart';

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
  Map<String, dynamic>? _simulationData;
  String _errorMessage = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _simulationCompleted = false;
  final DatabaseService _databaseService = DatabaseService();

  // Terminal state
  final TextEditingController _commandController = TextEditingController();
  final FocusNode _commandFocusNode = FocusNode();
  final List<TerminalLine> _terminalOutput = [];
  int _currentStepIndex = 0;
  List<Map<String, dynamic>> _steps = [];

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

      // Simülasyon verilerini DatabaseService üzerinden al
      final simulationDoc =
          await _databaseService.getSimulationById(widget.simulationId);

      if (simulationDoc == null || !simulationDoc.exists) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Simülasyon bulunamadı';
        });
        return;
      }

      // Kullanıcının bu simülasyonu tamamlayıp tamamlamadığını kontrol et
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final userProgressDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('progress')
            .doc(widget.simulationId)
            .get();

        _simulationCompleted = userProgressDoc.exists &&
            userProgressDoc.data()?['completed'] == true;
      }

      setState(() {
        _simulationData = simulationDoc.data() as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Simülasyon detayları yüklenirken hata oluştu: $e';
      });
    }
  }

  Future<void> _completeSimulation() async {
    try {
      String? moduleId;
      if (_simulationData != null && _simulationData!.containsKey('moduleId')) {
        moduleId = _simulationData!['moduleId'];
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

      // DatabaseService kullanarak simülasyonu tamamlandı olarak işaretle
      await _databaseService.saveSimulationResult(
          widget.simulationId, moduleId);

      setState(() {
        _simulationCompleted = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Simülasyon tamamlandı olarak işaretlendi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
    final currentStep = _steps[_currentStepIndex];
    final expectedCommand = currentStep['expectedCommand'];
    final expectedOutput = currentStep['expectedOutput'];

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
      if (currentStep['hint'] != null) {
        _addSystemOutput('İPUCU: ${currentStep['hint']}');
      } else {
        _addSystemOutput('Bu adım için ipucu bulunmamaktadır.');
      }
    } else if (command == 'clear' || command == 'temizle') {
      // Terminali temizle
      setState(() {
        _terminalOutput.clear();
        _addSystemOutput('Terminal temizlendi.');
        _addSystemOutput(
            'Adım ${_currentStepIndex + 1}: ${currentStep['title']}');
      });
    } else {
      // Yanlış komut
      _addSystemOutput(
          'Komut tanınmadı veya beklenen çıktıyı üretmedi. Tekrar deneyin.');
      _addSystemOutput('İpucu almak için "hint" yazabilirsiniz.');
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
    if (_currentStepIndex < _steps.length - 1) {
      _currentStepIndex++;
      final nextStep = _steps[_currentStepIndex];

      _addSystemOutput('\n--------------------------------------');
      _addSystemOutput('Adım ${_currentStepIndex + 1}: ${nextStep['title']}');
      _addSystemOutput(nextStep['description'] ?? '');

      if (nextStep['hint'] != null) {
        _addSystemOutput('\nİPUCU: ${nextStep['hint']}');
      }

      if (nextStep['commands'] != null) {
        final commands = nextStep['commands'] as List<dynamic>;
        if (commands.isNotEmpty) {
          _addSystemOutput(
              '\nKullanabileceğiniz komutlar: ${commands.join(", ")}');
        }
      }
    } else {
      // Simülasyon tamamlandı
      _simulationCompleted = true;
      _addSystemOutput('\n🎉 TEBRİKLER! Simülasyonu tamamladınız.');
      _completeSimulation();
    }
  }

  void _showHelp(Map<String, dynamic> currentStep) {
    _addSystemOutput('YARDIM:');
    _addSystemOutput(
        '- Adım ${_currentStepIndex + 1}: ${currentStep['title']}');
    _addSystemOutput('- İpucu için "hint" veya "ipucu" yazın');
    _addSystemOutput(
        '- Terminali temizlemek için "clear" veya "temizle" yazın');

    if (currentStep['commands'] != null) {
      final commands = currentStep['commands'] as List<dynamic>;
      if (commands.isNotEmpty) {
        _addSystemOutput(
            '- Kullanabileceğiniz komutlar: ${commands.join(", ")}');
      }
    }
  }

  void _addUserCommand(String command) {
    setState(() {
      _terminalOutput.add(TerminalLine(
        text: command,
        isCommand: true,
      ));
    });
  }

  void _addSystemOutput(String output) {
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
          _simulationData?['title'] ?? 'Simülasyon',
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
      bottomNavigationBar:
          !_isLoading && _simulationData != null && !_simulationCompleted
              ? BottomAppBar(
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: ElevatedButton(
                      onPressed: _completeSimulation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'SİMÜLASYONU TAMAMLA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                )
              : null,
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

    if (_simulationData == null) {
      return const Center(
        child: Text('Simülasyon verileri bulunamadı'),
      );
    }

    // Simülasyon içeriğini göster
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simülasyon başlık kartı
          Card(
            margin: const EdgeInsets.only(bottom: 20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _simulationData!['title'] ?? 'İsimsiz Simülasyon',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00FF8F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _simulationData!['description'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Simülasyon içeriği (Bu kısım uygulamanın gerçek simülasyon mantığına göre değişecektir)
          const Text(
            'Simülasyon İçeriği',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00CCFF),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              color: const Color(0xFF0F1923),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1C2D40)),
            ),
            child: const Center(
              child: Text(
                'Simülasyon içeriği burada görüntülenecek',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Simülasyon tamamlama butonu
          if (!_simulationCompleted)
            Center(
              child: ElevatedButton(
                onPressed: _completeSimulation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AACC),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('SİMÜLASYONU TAMAMLA'),
              ),
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
