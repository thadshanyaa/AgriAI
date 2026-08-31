import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_backend.dart';

class BiometricLoginResult {
  const BiometricLoginResult._(this.success, this.message);

  const BiometricLoginResult.success() : this._(true, '');
  const BiometricLoginResult.failure(String message) : this._(false, message);

  final bool success;
  final String message;
}

abstract final class BiometricAuthService {
  static const _enabledKey = 'biometric_login_enabled';
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<void> setEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, enabled);
  }

  static Future<bool> get isEnabled async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_enabledKey) ?? false;
  }

  static Future<List<BiometricType>> availableBiometrics() async {
    try {
      if (!await _auth.isDeviceSupported()) return const [];
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return const [];
    }
  }

  static Future<BiometricLoginResult> authenticate({
    required String methodName,
  }) async {
    if (FirebaseBackend.currentUser == null) {
      return const BiometricLoginResult.failure(
        'Login once with your email/phone and password to enable biometric login.',
      );
    }
    if (!await isEnabled) {
      return const BiometricLoginResult.failure(
        'Login with “Remember me” enabled before using fingerprint or face login.',
      );
    }

    try {
      final supported = await _auth.isDeviceSupported();
      final enrolled = await _auth.getAvailableBiometrics();
      if (!supported || enrolled.isEmpty) {
        return const BiometricLoginResult.failure(
          'No fingerprint or face biometric is enrolled. Add one in Phone Settings first.',
        );
      }
      final authenticated = await _auth.authenticate(
        localizedReason: 'Use $methodName to unlock AgriAI',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      return authenticated
          ? const BiometricLoginResult.success()
          : const BiometricLoginResult.failure(
              'Biometric authentication was cancelled or not recognized.',
            );
    } catch (error) {
      return BiometricLoginResult.failure(
        'Biometric login is unavailable: $error',
      );
    }
  }
}
