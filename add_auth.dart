import 'dart:io';

void main() {
  var file = File('lib/services/auth_service.dart');
  file.writeAsStringSync('''
import 'package:local_auth/local_auth.dart';

class AuthService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> verifyBiometrics(String reason) async {
    try {
      final can = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      if (!can || !supported) return true; // If no biometrics, just allow it
      
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      return ok;
    } catch (_) {
      return true; // Fallback to allowing if auth fails to init
    }
  }
}
''');
}
