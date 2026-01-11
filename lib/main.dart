import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:progressive_blur/progressive_blur.dart';
import 'package:vault/providers.dart';
import 'package:vault/router_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

import 'package:vault/src/rust/frb_generated.dart';

import 'package:flutter_displaymode/flutter_displaymode.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await RustLib.init();
  // await ProgressiveBlurWidget.precache();
  await Future.wait([
    RustLib.init(),
    ProgressiveBlurWidget.precache(),
  ]);
  MediaKit.ensureInitialized();
  // ProgressiveBlurWidget.precache();

  // PRE-WARM THE ISOLATE POOL
  final container = ProviderContainer();
  container.read(isolatePoolProvider);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    setOptimalDisplayMode();
  }

  Future<void> setOptimalDisplayMode() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final List<DisplayMode> supported = await FlutterDisplayMode.supported;
        final DisplayMode active = await FlutterDisplayMode.active;

        final List<DisplayMode> sameResolution = supported
            .where((DisplayMode m) =>
                m.width == active.width && m.height == active.height)
            .toList()
          ..sort((DisplayMode a, DisplayMode b) =>
              b.refreshRate.compareTo(a.refreshRate));

        final DisplayMode mostOptimalMode =
            sameResolution.isNotEmpty ? sameResolution.first : active;

        await FlutterDisplayMode.setPreferredMode(mostOptimalMode);
      } catch (e) {
        debugPrint("Error setting display mode: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = ref.watch(passwordExistsProvider);
    final settings = ref.watch(settingsModelProvider);

    return authStatus.when(
      loading: () {
        return CupertinoApp(
          debugShowCheckedModeBanner: false,
          theme: CupertinoThemeData(
            brightness: settings.darkmode ? Brightness.dark : Brightness.light,
            // primaryColor: CupertinoColors.activeBlue,
          ),
          home: const SplashScreen(),
        );
      },
      error: (err, stack) {
        return CupertinoApp(
          debugShowCheckedModeBanner: false,
          theme: CupertinoThemeData(
            brightness: settings.darkmode ? Brightness.dark : Brightness.light,
            // primaryColor: CupertinoColors.activeBlue,
          ),
          home: ErrorScreen(error: err.toString()),
        );
      },
      data: (_) {
        final router = ref.watch(routerProvider);
        return CupertinoApp.router(
          title: "Vault",
          debugShowCheckedModeBanner: false,
          theme: CupertinoThemeData(
            brightness: settings.darkmode ? Brightness.dark : Brightness.light,
            // primaryColor: CupertinoColors.activeBlue,
          ),
          routerConfig: router,
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      child: Center(child: CupertinoActivityIndicator()),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;
  const ErrorScreen({super.key, required this.error});
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Center(child: Text('Error: $error')),
    );
  }
}
