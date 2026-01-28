import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:async';

import 'package:vault/router_provider.dart';
import 'package:vault/providers.dart';

class MotionDetector extends ConsumerStatefulWidget {
  final Widget child;

  const MotionDetector({super.key, required this.child});

  @override
  // ignore: library_private_types_in_public_api
  _MotionDetectorState createState() => _MotionDetectorState();
}

class _MotionDetectorState extends ConsumerState<MotionDetector> {
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  final double _threshold = 2.0;
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isAuthenticating = false;
  bool _isLoggingOut = false;
  bool _needsReauthOnResume = false; // Flag to track focus changes

  // 1. Declare the Listener
  late final AppLifecycleListener _lifecycleListener;
  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      // 1. When app goes to background
      onHide: () => _handleFocusLoss(),
      onPause: () => _handleFocusLoss(),

      // 2. When app comes back to foreground
      onResume: () => _handleFocusGain(),
    );
  }

  void _handleFocusLoss() {
    if (_isAuthenticating || _isLoggingOut) return;

    debugPrint("App went to background. Locking sensors...");
    _stopListening();
    _needsReauthOnResume =
        true; // Mark that we need a check when the user returns
  }

  void _handleFocusGain() {
    if (_needsReauthOnResume && !_isLoggingOut) {
      debugPrint("App resumed. Prompting for biometrics...");
      _authenticateWithBiometrics();
      _needsReauthOnResume = false; // Reset flag
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = ref.watch(settingsModelProvider);

    // Remove previous listener to avoid duplicates
    settings.removeListener(_onSettingsChanged);
    settings.addListener(_onSettingsChanged);

    if (settings.theftProtection) {
      _startListening();
    }
  }

  void _onSettingsChanged() {
    final settings = ref.read(settingsModelProvider);

    if (settings.theftProtection) {
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
          // _stopListening();
          // context.pushReplacement("/");
          _triggerLogout();
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

  // void _triggerLogout() {
  //   _stopListening();
  //   ref.read(isAuthenticatedProvider.notifier).state = false;
  // }
  void _triggerLogout() {
    _stopListening();
    // Wrap in microtask to avoid "DiagnosticsProperty" / build-phase errors
    Future.microtask(() {
      if (mounted) {
        ref.read(isAuthenticatedProvider.notifier).state = false;
      }
    });
  }

  Future<void> _authenticateWithBiometrics() async {
    // Prevent multiple simultaneous prompts
    if (_isAuthenticating) return;

    _stopListening(); // Stop sensors so they don't interfere with the dialog

    setState(() {
      _isAuthenticating = true;
    });

    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to continue',
        options: const AuthenticationOptions(
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (didAuthenticate) {
        debugPrint("Authentication Successful");
        setState(() => _isAuthenticating = false);
        _startListening(); // Resume sensors
      } else {
        debugPrint("Authentication Failed/Cancelled");
        _triggerLogout();
      }
    } catch (e) {
      debugPrint("Authentication error: $e");
      _triggerLogout();
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    final settings = ref.read(settingsModelProvider);
    settings.removeListener(_onSettingsChanged);
    _stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
