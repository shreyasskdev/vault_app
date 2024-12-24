import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:async';

class MotionDetector extends StatefulWidget {
  final Widget child;

  const MotionDetector({super.key, required this.child});

  @override
  _MotionDetectorState createState() => _MotionDetectorState();
}

class _MotionDetectorState extends State<MotionDetector> {
  late StreamSubscription<GyroscopeEvent> _gyroSubscription;
  final double _threshold = 2.0;
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    _gyroSubscription = gyroscopeEvents.listen((event) {
      double intensity = event.x.abs() + event.y.abs() + event.z.abs();

      if (intensity > (_threshold * 4)) {
        if (mounted) {
          context.pushReplacement("/");
        }
      } else if (intensity > (_threshold * 2)) {
        _authenticateWithBiometrics();
      }
    });
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      if (_isAuthenticating) return;
      _isAuthenticating = true;

      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to continue',
        options: const AuthenticationOptions(stickyAuth: true),
      );

      if (didAuthenticate) {
        _isAuthenticating = false;
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
    }
  }

  @override
  void dispose() {
    _gyroSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
