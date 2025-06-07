import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:vault/pages/password.dart';
import 'package:vault/pages/photo.dart';
import 'package:vault/pages/settings/about.dart';
import 'package:vault/pages/settings/appearance_settings.dart';
import 'package:vault/pages/settings/privacy_settings.dart';
import 'package:vault/pages/settings/settings.dart';
import 'package:vault/pages/collections.dart';
import 'package:vault/pages/setup.dart';
import 'package:vault/pages/intro.dart';
import 'package:vault/pages/album.dart';
import 'package:vault/utils/file_api_wrapper.dart' as fileapi;

class FileService with fileapi.FileApiWrapper {
  const FileService();
}

final passwordExistsProvider = FutureProvider<bool>((ref) async {
  const fileService = FileService();
  Directory appDocDir = await getApplicationDocumentsDirectory();
  String directory = '${appDocDir.path}/Collections';
  final exists = await fileService.checkPasswordExistWrapper(directory);
  return exists;
});

final isAuthenticatedProvider = StateProvider<bool>((ref) => false);

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    // initialLocation: '/',
    routes: [
      GoRoute(
        path: "/",
        builder: (context, state) => const Password(),
        routes: [
          GoRoute(
            path: "intro",
            builder: (context, state) => const IntroductionPage(),
          ),
          GoRoute(
            path: "setup",
            builder: (context, state) => const SetupPage(),
          ),
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
    redirect: (context, state) {
      final passwordExistsFuture = ref.watch(passwordExistsProvider);
      final isAuthenticated = ref.watch(isAuthenticatedProvider);
      final location = state.matchedLocation;

      if (passwordExistsFuture.isLoading || passwordExistsFuture.isRefreshing) {
        return null;
      }
      final passwordExists = passwordExistsFuture.value ?? false;

      final isAtLogin = location == '/';
      final isGoingToSetup = location == '/setup' || location == '/intro';

      // CASE 1: User is authenticated. Redirect from login/setup to collections.
      if (isAuthenticated) {
        if (isAtLogin || isGoingToSetup) {
          return '/collections';
        }
        return null;
      }

      // CASE 2: User is NOT authenticated, but password exists. Force to login.
      if (passwordExists) {
        if (isAtLogin) {
          return null;
        }
        return '/';
      }

      // CASE 3: User is NOT authenticated, and NO password exists. Force to setup.
      if (!passwordExists) {
        if (isGoingToSetup) {
          return null;
        }
        return '/intro';
      }

      return null;
    },
  );
});
