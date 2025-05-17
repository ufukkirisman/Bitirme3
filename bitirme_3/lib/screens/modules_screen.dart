import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bitirme_3/models/module.dart';
import 'package:bitirme_3/services/module_service.dart';

class ModulesScreen extends StatefulWidget {
  const ModulesScreen({Key? key}) : super(key: key);

  @override
  _ModulesScreenState createState() => _ModulesScreenState();
}

class _ModulesScreenState extends State<ModulesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<DocumentSnapshot> _modules = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchModules();
  }

  Future<void> _fetchModules() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final modulesSnapshot = await FirebaseFirestore.instance
          .collection('modules')
          .orderBy('order', descending: false)
          .get();

      setState(() {
        _modules = modulesSnapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Modüller yüklenirken hata oluştu: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modüller'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
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
              onPressed: _fetchModules,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_modules.isEmpty) {
      return const Center(
        child: Text('Henüz hiç modül bulunmamaktadır'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _modules.length,
      itemBuilder: (context, index) {
        final module = _modules[index].data() as Map<String, dynamic>;
        final moduleId = _modules[index].id;
        final progress = module['progress'] ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              // Modül detay sayfasına git
              Navigator.pushNamed(
                context,
                '/module/$moduleId',
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modül resmi
                if (module['imageUrl'] != null)
                  Image.network(
                    module['imageUrl'],
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        color: Colors.blue.shade100,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Modül başlığı
                      Text(
                        module['title'] ?? 'İsimsiz Modül',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Modül açıklaması
                      if (module['description'] != null)
                        Text(
                          module['description'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 16),

                      // İlerleme durumu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'İlerleme: %$progress',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: progress > 0
                                  ? Colors.green
                                  : Colors.grey.shade600,
                            ),
                          ),
                          if (progress == 100)
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress > 0 ? Colors.green : Colors.blue.shade300,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        minHeight: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
