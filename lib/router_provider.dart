import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vault/pages/album.dart';
import 'package:vault/pages/collections.dart';
import 'package:vault/pages/intro.dart';
import 'package:vault/pages/password.dart';
import 'package:vault/pages/photo.dart';
import 'package:vault/pages/settings/about.dart';
import 'package:vault/pages/settings/appearance_settings.dart';
import 'package:vault/pages/settings/privacy_settings.dart';
import 'package:vault/pages/settings/settings.dart';
import 'package:vault/pages/setup.dart';
import 'package:vault/utils/file_api_wrapper.dart' as fileapi;

// A simple wrapper class for file operations
class FileService with fileapi.FileApiWrapper {
  const FileService();
}

// Provider to check if a password file exists on startup
final passwordExistsProvider = FutureProvider<bool>((ref) async {
  const fileService = FileService();
  Directory appDocDir = await getApplicationDocumentsDirectory();
  String directory = '${appDocDir.path}/Collections';
  final exists = await fileService.checkPasswordExistWrapper(directory);
  return exists;
});

// Provider to hold the current authentication state of the user
final isAuthenticatedProvider = StateProvider<bool>((ref) => false);

/// Helper class to make GoRouter listen to Riverpod's StateProvider changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// The main router provider
final routerProvider = Provider<GoRouter>((ref) {
  // GoRouter will now listen for changes to the isAuthenticatedProvider
  final refreshListenable =
      GoRouterRefreshStream(ref.watch(isAuthenticatedProvider.notifier).stream);

  return GoRouter(
    refreshListenable: refreshListenable,
    initialLocation: '/', // Start at the root
    routes: [
      // All main navigation destinations are now top-level siblings.
      // This is the key to making route replacement work correctly.

      // Path for the login screen
      GoRoute(
        path: "/",
        builder: (context, state) => const Password(),
      ),
      // Paths for the initial setup flow
      GoRoute(
        path: "/intro",
        builder: (context, state) => const IntroductionPage(),
      ),
      GoRoute(
        path: "/setup",
        builder: (context, state) => const SetupPage(),
      ),

      // --- Authenticated Routes ---

      // Path for the main collections view
      GoRoute(
        path: "/collections",
        builder: (context, state) => const CollectionsPage(),
      ),
      // Path for a specific album
      GoRoute(
        path: "/album/:name",
        builder: (context, state) => AlbumPage(
          name: state.pathParameters["name"]!,
        ),
      ),
      // Path for viewing a photo
      GoRoute(
        path: "/photo/:url/:index/:count",
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
      // Path for the settings screen and its children
      GoRoute(
          path: "/settings",
          builder: (context, state) => const SettingsPage(),
          // Children of '/settings' are nested correctly here
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
    ],
    redirect: (context, state) {
      final passwordExistsFuture = ref.watch(passwordExistsProvider);
      final isAuthenticated = ref.watch(isAuthenticatedProvider);
      final location = state.matchedLocation;

      // While checking if a password exists, don't redirect.
      // You might show a splash screen or a loading indicator at the root.
      if (passwordExistsFuture.isLoading || passwordExistsFuture.isRefreshing) {
        return null;
      }
      final passwordExists = passwordExistsFuture.value ?? false;

      // Define locations for login and setup flows
      final isAtLogin = location == '/';
      final isGoingToSetup = location == '/setup' || location == '/intro';

      // CASE 1: User is authenticated.
      // If they are on the login or setup pages, redirect them to the collections.
      // This now REPLACES the route instead of pushing it.
      if (isAuthenticated) {
        if (isAtLogin || isGoingToSetup) {
          return '/collections';
        }
        // Otherwise, they are authenticated and going to a valid page, so allow it.
        return null;
      }

      // CASE 2: User is NOT authenticated, but a password exists.
      // They must be sent to the login screen.
      if (passwordExists) {
        // If they are already at login, do nothing. Otherwise, redirect.
        return isAtLogin ? null : '/';
      }

      // CASE 3: User is NOT authenticated, and NO password exists.
      // They must go through the setup flow.
      if (!passwordExists) {
        // If they are already in the setup flow, do nothing. Otherwise, redirect.
        return isGoingToSetup ? null : '/intro';
      }

      // Fallback in case none of the conditions are met.
      return null;
    },
  );
});
