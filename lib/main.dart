import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progressive_blur/progressive_blur.dart';
import 'package:vault/providers.dart';
import 'package:vault/router_provider.dart';
import 'themes/dark_theme.dart';
import 'themes/light_theme.dart';

import 'package:vault/src/rust/frb_generated.dart';

import 'package:flutter_displaymode/flutter_displaymode.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  await ProgressiveBlurWidget.precache();
  runApp(
    const ProviderScope(
      child: MyApp(),
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

  @override
  Widget build(BuildContext context) {
    final authStatus = ref.watch(passwordExistsProvider);
    final settings = ref.watch(settingsModelProvider);

    return authStatus.when(
      loading: () {
        // FIX: Provide a themed MaterialApp for the loading state.
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: settings.darkmode ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
        );
      },
      error: (err, stack) {
        // FIX: Provide a themed MaterialApp for the error state.
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: settings.darkmode ? ThemeMode.dark : ThemeMode.light,
          home: ErrorScreen(error: err.toString()),
        );
      },
      data: (_) {
        // This is the main app state, which uses the router.
        final router = ref.watch(routerProvider);
        return MaterialApp.router(
          title: "Vault",
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: settings.darkmode ? ThemeMode.dark : ThemeMode.light,
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
    // FIX: This widget should NOT build its own MaterialApp.
    // It should only return the content (the Scaffold).
    // The theme will be inherited from the parent MaterialApp.
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;
  const ErrorScreen({super.key, required this.error});
  @override
  Widget build(BuildContext context) {
    // FIX: This widget also should NOT build its own MaterialApp.
    // It returns the Scaffold, and the theme is inherited.
    return Scaffold(
      body: Center(child: Text('Error: $error')),
    );
  }
}
