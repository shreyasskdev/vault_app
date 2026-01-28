import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:vault/widget/menu_item.dart';

import 'package:vault/utils/auth_serrvices.dart'; // Added
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Added

// --- SETTINGS PAGE ---

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  static const double _menuSpacing = 16.0;
  static const double _borderRadius = 20.0;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    // Resolve the background color to ensure it responds to Dark Mode
    final backgroundColor =
        CupertinoColors.systemGroupedBackground.resolveFrom(context);

    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: backgroundColor.withOpacity(0.8),
        middle: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      // LayoutBuilder gives us the constraints (height) of the screen
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: ConstrainedBox(
              // FIX: This forces the Column to be AT LEAST the height of the screen
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: _menuSpacing),

                    // Section 1: Privacy & Appearance
                    MenuSection(
                      borderRadius: _borderRadius,
                      menuSpacing: _menuSpacing,
                      children: [
                        MenuItem(
                          icon: CupertinoIcons.lock_fill,
                          iconColor: theme.primaryColor,
                          title: "Privacy",
                          subtitle: "Privacy and security settings",
                          onTap: () async {
                            // context.push("/settings/privacy");

                            // 1. TRIGGER BIOMETRICS BEFORE NAVIGATION
                            final success = await ref
                                .read(authServiceProvider)
                                .authenticate(
                                  reason:
                                      'Confirm identity to access privacy settings',
                                );

                            // 2. ONLY NAVIGATE IF SUCCESSFUL
                            if (success && context.mounted) {
                              context.push("/settings/privacy");
                            }
                          },
                        ),
                        MenuItem(
                          icon: CupertinoIcons.paintbrush_fill,
                          iconColor: theme.primaryColor,
                          title: "Appearance",
                          subtitle: "Customize app appearance",
                          onTap: () => context.push("/settings/appearance"),
                          divider: false,
                        ),
                      ],
                    ),

                    const SizedBox(height: _menuSpacing),

                    // Section 2: Info
                    MenuSection(
                      borderRadius: _borderRadius,
                      menuSpacing: _menuSpacing,
                      children: [
                        MenuItem(
                          icon: CupertinoIcons.info_circle_fill,
                          iconColor: theme.primaryColor,
                          title: "About",
                          subtitle: "Learn more about this app",
                          onTap: () => context.push("/settings/about"),
                          divider: false,
                        ),
                      ],
                    ),

                    // Extra spacing at bottom to ensure scrolling feels nice
                    const SizedBox(height: _menuSpacing),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
