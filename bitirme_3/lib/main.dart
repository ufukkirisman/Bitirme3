import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bitirme_3/screens/login_screen.dart';
import 'package:bitirme_3/screens/register_screen.dart';
import 'package:bitirme_3/screens/home_screen.dart';
import 'package:bitirme_3/screens/modules_screen.dart';
import 'package:bitirme_3/screens/module_detail_screen.dart';
import 'package:bitirme_3/screens/lesson_screen.dart';
import 'package:bitirme_3/screens/quiz_screen.dart';
import 'package:bitirme_3/screens/simulation_screen.dart';
import 'package:bitirme_3/screens/training_screen.dart';
import 'package:bitirme_3/screens/roadmap_screen.dart';
import 'package:bitirme_3/screens/admin/admin_login_screen.dart';
import 'package:bitirme_3/services/auth_service.dart';
import 'package:bitirme_3/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Firebase daha önce başlatılmış mı kontrol et
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase başarıyla başlatıldı');
    } else {
      print('Firebase zaten başlatılmış');
      Firebase.app(); // Mevcut örnekleri kullan
    }
  } catch (e) {
    print('Firebase başlatma hatası: $e');
    // Firebase başlatılamazsa bile uygulamanın çökmesini engellemek için
    // hata yönetimi eklenebilir.
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CyberSec Academy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00FF8F),
          secondary: const Color(0xFF00CCFF),
          background: const Color(0xFF080C15),
          surface: const Color(0xFF101823),
          onSurface: Colors.white,
          error: Colors.red.shade700,
        ),
        scaffoldBackgroundColor: const Color(0xFF080C15),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F1923),
          foregroundColor: Color(0xFF00FF8F),
          elevation: 4,
          shadowColor: Color(0xFF000F23),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF101823),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: Colors.black.withOpacity(0.4),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFCCDDFF)),
          bodyLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Color(0xFF00CCFF)),
          titleLarge: TextStyle(color: Color(0xFF00FF8F)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00AACC),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 6,
            shadowColor: const Color(0xFF005566),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF00CCFF),
            side: const BorderSide(color: Color(0xFF00AACC), width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          fillColor: const Color(0xFF121C28),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1C2D40)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1C2D40)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF00AACC), width: 2),
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xFF00FF8F),
          linearTrackColor: Color(0xFF1C2D40),
        ),
        dividerTheme: DividerThemeData(
          color: const Color(0xFF1C2D40),
          thickness: 1,
          space: 24,
        ),
        useMaterial3: true,
      ),
      initialRoute:
          FirebaseAuth.instance.currentUser != null ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/modules': (context) => const ModulesScreen(),
        '/module_detail': (context) => const ModuleDetailScreen(moduleId: ''),
        '/training': (context) => const TrainingScreen(),
        '/roadmap': (context) => const RoadmapScreen(),
        '/admin/login': (context) => const AdminLoginScreen(),
      },
      onGenerateRoute: (settings) {
        // Dinamik rotalar için
        if (settings.name?.startsWith('/module/') ?? false) {
          final moduleId = settings.name?.split('/').last;
          return MaterialPageRoute(
            builder: (context) => ModuleDetailScreen(moduleId: moduleId ?? ''),
          );
        } else if (settings.name?.startsWith('/lesson/') ?? false) {
          final lessonId = settings.name?.split('/').last;
          final arguments = settings.arguments;
          return MaterialPageRoute(
            builder: (context) => LessonScreen(
              lessonId: lessonId ?? '',
              arguments: arguments,
            ),
          );
        } else if (settings.name?.startsWith('/quiz/') ?? false) {
          final quizId = settings.name?.split('/').last;
          return MaterialPageRoute(
            builder: (context) => QuizScreen(quizId: quizId ?? ''),
          );
        } else if (settings.name?.startsWith('/simulation/') ?? false) {
          final simulationId = settings.name?.split('/').last;
          return MaterialPageRoute(
            builder: (context) =>
                SimulationScreen(simulationId: simulationId ?? ''),
          );
        } else if (settings.name?.startsWith('/training/') ?? false) {
          final trainingId = settings.name?.split('/').last ?? '';
          return MaterialPageRoute(
            builder: (context) => TrainingDetailScreen(trainingId: trainingId),
          );
        } else if (settings.name?.startsWith('/roadmap/') ?? false) {
          final roadmapId = settings.name?.split('/').last ?? '';
          return MaterialPageRoute(
            builder: (context) => RoadmapDetailScreen(roadmapId: roadmapId),
          );
        }
        return null;
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _authService.user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            return const LoginScreen();
          }
          return const HomeScreen();
        }

        // Yükleniyor durumu
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
