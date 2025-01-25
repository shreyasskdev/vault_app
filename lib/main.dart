import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:vault/moiton_detector.dart';
import 'package:vault/pages/password.dart';
import 'package:vault/pages/photo.dart';
import 'package:vault/pages/settings/about.dart';
import 'package:vault/pages/settings/appearance_settings.dart';
import 'package:vault/pages/settings/privacy_settings.dart';
import 'package:vault/pages/settings/settings.dart';
import 'package:vault/settings_model.dart';
import 'pages/collections.dart';
import 'pages/album.dart';
import 'package:go_router/go_router.dart';
import 'themes/dark_theme.dart';
import 'themes/light_theme.dart';

import 'package:vault/src/rust/frb_generated.dart';

import 'package:flutter_displaymode/flutter_displaymode.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(
    ChangeNotifierProvider(
      create: (context) => SettingsModel(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context);

    return MaterialApp.router(
      title: "Vault",
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: settings.darkmode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: _router,
    );
  }

  @override
  void initState() {
    setOptimalDisplayMode();
    super.initState();
  }

  Future<void> setOptimalDisplayMode() async {
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

    /// This setting is per session.
    /// Please ensure this was placed with `initState` of your root widget.
    await FlutterDisplayMode.setPreferredMode(mostOptimalMode);
  }
}

final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: "/",
      builder: (context, state) => const Password(),
      routes: [
        GoRoute(
            path: "settings",
            builder: (context, state) => const SettingsPage(),
            routes: [
              GoRoute(
                path: "privacy",
                builder: (context, state) => const PrivacySettings(),
              ),
              GoRoute(
                path: "appearance",
                builder: (context, state) => const AppearanceSettings(),
              ),
              GoRoute(
                path: "about",
                builder: (context, state) => const AboutPage(),
              ),
            ]),
        GoRoute(
          path: "collections",
          builder: (context, state) => const CollectionsPage(),
        ),
        GoRoute(
          path: "album/:name",
          builder: (context, state) => AlbumPage(
            name: state.pathParameters["name"]!,
          ),
        ),
        GoRoute(
          path: "photo/:url/:index/:count",
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              child: PhotoView(
                url: state.pathParameters["url"]!,
                index: int.parse(state.pathParameters["index"]!),
                count: int.parse(state.pathParameters["count"]!),
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                    opacity: CurveTween(curve: Curves.fastEaseInToSlowEaseOut)
                        .animate(animation),
                    child: child);
              },
            );
          },
        ),
      ],
    ),
  ],
);
