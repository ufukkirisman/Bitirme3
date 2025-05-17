import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcı oturum durumu değişikliklerini izleme
  Stream<User?> get user => _auth.authStateChanges();

  // Mevcut kullanıcı bilgisi
  User? get currentUser => _auth.currentUser;

  // Firebase Auth yapılandırma kontrolleri
  Future<void> checkAuthConfig() async {
    try {
      // Firebase Auth'un doğru yapılandırıldığını kontrol et
      await _auth.setLanguageCode("tr");
      print("Firebase Auth yapılandırması başarılı");
    } catch (e) {
      print("Firebase Auth yapılandırma hatası: $e");
    }
  }

  // E-posta ve şifre ile kayıt
  Future<User?> registerWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      // Önce auth yapılandırmasını kontrol edelim
      await checkAuthConfig();

      // reCAPTCHA doğrulamasından kaynaklanan sorunları çözmek için
      // web sürümünden farklı bir doğrulama yöntemi kullanın
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      // Kullanıcı adını güncelleme
      await result.user?.updateDisplayName(name);
      await result.user?.reload(); // Kullanıcı bilgilerini yenileyin

      return result.user;
    } on FirebaseAuthException catch (e) {
      print("Firebase Kayıt Hatası: ${e.code} - ${e.message}");
      _showErrorMessage(e.code);
      return null;
    } catch (e) {
      print("Beklenmeyen kayıt hatası: $e");
      _showErrorMessage('unknown-error');
      return null;
    }
  }

  // E-posta ve şifre ile giriş
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      // Önce auth yapılandırmasını kontrol edelim
      await checkAuthConfig();

      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
      print("Firebase Giriş Hatası: ${e.code} - ${e.message}");
      _showErrorMessage(e.code);
      return null;
    } catch (e) {
      print("Beklenmeyen giriş hatası: $e");
      _showErrorMessage('unknown-error');
      return null;
    }
  }

  // Çıkış yapma
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Çıkış hatası: $e");
      _showErrorMessage('sign-out-failed');
    }
  }

  // Şifre sıfırlama e-postası gönderme
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Fluttertoast.showToast(
        msg: "Şifre sıfırlama e-postası gönderildi!",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    } on FirebaseAuthException catch (e) {
      print("Şifre sıfırlama hatası: ${e.code} - ${e.message}");
      _showErrorMessage(e.code);
    } catch (e) {
      print("Beklenmeyen şifre sıfırlama hatası: $e");
      _showErrorMessage('unknown-error');
    }
  }

  // Hata mesajlarını gösterme
  void _showErrorMessage(String errorCode) {
    String message;

    switch (errorCode) {
      case 'email-already-in-use':
        message = 'Bu e-posta adresi zaten kullanılıyor.';
        break;
      case 'invalid-email':
        message = 'Geçersiz e-posta adresi.';
        break;
      case 'weak-password':
        message = 'Şifre çok zayıf.';
        break;
      case 'user-not-found':
        message = 'Bu e-posta adresiyle kayıtlı kullanıcı bulunamadı.';
        break;
      case 'wrong-password':
        message = 'Yanlış şifre.';
        break;
      case 'user-disabled':
        message = 'Bu kullanıcı hesabı devre dışı bırakılmış.';
        break;
      case 'operation-not-allowed':
        message = 'Bu işlem şu anda devre dışı.';
        break;
      case 'too-many-requests':
        message = 'Çok fazla istek yaptınız. Lütfen daha sonra tekrar deneyin.';
        break;
      case 'network-request-failed':
        message = 'Ağ hatası oluştu. İnternet bağlantınızı kontrol edin.';
        break;
      case 'sign-out-failed':
        message = 'Çıkış yaparken bir hata oluştu.';
        break;
      case 'unknown-error':
        message =
            'Bilinmeyen bir hata oluştu. Lütfen daha sonra tekrar deneyin.';
        break;
      default:
        message = 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
    );
  }
}
