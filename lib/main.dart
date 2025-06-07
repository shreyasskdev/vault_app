import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vault/providers.dart';
import 'package:vault/router_provider.dart';
import 'themes/dark_theme.dart';
import 'themes/light_theme.dart';

import 'package:vault/src/rust/frb_generated.dart';

import 'package:flutter_displaymode/flutter_displaymode.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
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
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = ref.watch(passwordExistsProvider);
    final settings = ref.watch(SettingsModelProvider);

    return authStatus.when(
      loading: () => const SplashScreen(),
      error: (err, stack) => ErrorScreen(error: err.toString()),
      data: (_) {
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
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;
  const ErrorScreen({super.key, required this.error});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }
}

// final GoRouter _router = GoRouter(
//   initialLocation: '/',
//   routes: [
//     GoRoute(
//       path: "/",
//       builder: (context, state) => const Password(),
//       routes: [
//         GoRoute(
//           path: "intro",
//           builder: (context, state) => const IntroductionPage(),
//         ),
//         GoRoute(
//           path: "setup",
//           builder: (context, state) => const SetupPage(),
//         ),
//         GoRoute(
//             path: "settings",
//             builder: (context, state) => const SettingsPage(),
//             routes: [
//               GoRoute(
//                 path: "privacy",
//                 builder: (context, state) => const PrivacySettings(),
//               ),
//               GoRoute(
//                 path: "appearance",
//                 builder: (context, state) => const AppearanceSettings(),
//               ),
//               GoRoute(
//                 path: "about",
//                 builder: (context, state) => const AboutPage(),
//               ),
//             ]),
//         GoRoute(
//           path: "collections",
//           builder: (context, state) => const CollectionsPage(),
//         ),
//         GoRoute(
//           path: "album/:name",
//           builder: (context, state) => AlbumPage(
//             name: state.pathParameters["name"]!,
//           ),
//         ),
//         GoRoute(
//           path: "photo/:url/:index/:count",
//           pageBuilder: (context, state) {
//             return CustomTransitionPage(
//               child: PhotoView(
//                 url: state.pathParameters["url"]!,
//                 index: int.parse(state.pathParameters["index"]!),
//                 count: int.parse(state.pathParameters["count"]!),
//               ),
//               transitionsBuilder:
//                   (context, animation, secondaryAnimation, child) {
//                 return FadeTransition(
//                     opacity: CurveTween(curve: Curves.fastEaseInToSlowEaseOut)
//                         .animate(animation),
//                     child: child);
//               },
//             );
//           },
//         ),
//       ],
//     ),
//   ],
// );
