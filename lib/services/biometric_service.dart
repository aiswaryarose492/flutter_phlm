import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final BiometricService instance = BiometricService._internal();
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  static const _enabledKey = 'biometric_login_enabled';

  Future<bool> canCheckBiometrics() => _auth.canCheckBiometrics;

  Future<bool> isBiometricLoginEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<void> setBiometricLoginEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  Future<bool> authenticate() async {
    final canCheck = await _auth.canCheckBiometrics;
    if (!canCheck) return false;
    return await _auth.authenticate(
      localizedReason: 'Authenticate to open PHLM',
      options: const AuthenticationOptions(
        stickyAuth: true,
        biometricOnly: true,
      ),
    );
  }
}
