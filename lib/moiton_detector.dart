import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:async';

import 'package:vault/settings_model.dart';

class MotionDetector extends ConsumerStatefulWidget {
  final Widget child;

  const MotionDetector({super.key, required this.child});

  @override
  _MotionDetectorState createState() => _MotionDetectorState();
}

class _MotionDetectorState extends ConsumerState<MotionDetector> {
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  final double _threshold = 2.0;
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isAuthenticating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = ref.watch(SettingsModelProvider);

    // Remove previous listener to avoid duplicates
    settings.removeListener(_onSettingsChanged);
    settings.addListener(_onSettingsChanged);

    if (settings.TheftProtection) {
      _startListening();
    }
  }

  void _onSettingsChanged() {
    final settings = ref.read(SettingsModelProvider);
    ;

    if (settings.TheftProtection) {
      _startListening();
    } else {
      _stopListening();
    }
  }

  void _startListening() {
    if (_gyroSubscription != null) return;

    _gyroSubscription = gyroscopeEvents.listen((event) {
      double intensity = event.x.abs() + event.y.abs() + event.z.abs();

      if (intensity > (_threshold * 4)) {
        if (mounted) {
          _stopListening();
          context.pushReplacement("/");
        }
      } else if (intensity > (_threshold * 2)) {
        _authenticateWithBiometrics();
      }
    });
  }

  void _stopListening() {
    _gyroSubscription?.cancel();
    _gyroSubscription = null;
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isAuthenticating) return;

    _isAuthenticating = true;

    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to continue',
        options: const AuthenticationOptions(stickyAuth: true),
      );

      if (didAuthenticate) {
        // Authentication succeeded
      } else {
        if (mounted) {
          context.pushReplacement("/");
        }
      }
    } catch (e) {
      debugPrint("Authentication error: $e");
      if (mounted) {
        context.pushReplacement("/");
      }
    } finally {
      _isAuthenticating = false;
    }
  }

  @override
  void dispose() {
    final settings = ref.read(SettingsModelProvider);
    settings.removeListener(_onSettingsChanged);
    _stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
