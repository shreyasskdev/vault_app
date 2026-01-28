import 'dart:io'; // Required for Platform check
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb

class AuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> authenticate(
      {String reason = 'Please authenticate to proceed'}) async {
    // 1. BYPASS FOR LINUX / DESKTOP / DEBUG
    // local_auth is primarily for iOS and Android.
    // We check if we are on Linux or Windows to avoid the app "hanging".
    if (!kIsWeb && (Platform.isLinux || Platform.isWindows)) {
      debugPrint("Bypassing biometrics: Not supported on this platform.");
      return true;
    }

    try {
      // 2. CHECK HARDWARE SUPPORT
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();

      // If the device physically cannot do biometrics, just let the user in
      if (!canAuthenticateWithBiometrics && !isSupported) {
        return true;
      }

      // 3. ATTEMPT AUTHENTICATION
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Fallback to PIN/Pattern if biometrics fail
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint("Auth Error: ${e.code}");
      // If the error is "NotAvailable", we bypass so the app doesn't break
      if (e.code == 'NotAvailable' || e.code == 'NotSupported') {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("General Auth Error: $e");
      return false;
    }
  }
}

final authServiceProvider = Provider((ref) => AuthService());
