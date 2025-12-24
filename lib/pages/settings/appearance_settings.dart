import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vault/providers.dart';
import 'package:vault/widget/menu_item.dart';

class AppearanceSettings extends ConsumerStatefulWidget {
  const AppearanceSettings({super.key});

  @override
  ConsumerState<AppearanceSettings> createState() => _AppearanceSettingsState();
}

class _AppearanceSettingsState extends ConsumerState<AppearanceSettings> {
  static const double _menuSpacing = 16.0;
  static const double _borderRadius = 20.0;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final backgroundColor =
        CupertinoColors.systemGroupedBackground.resolveFrom(context);
    final primaryColor = theme.primaryColor;

    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: backgroundColor.withOpacity(0.9),
        border: null, // Cleaner, modern look
        // leading: TouchableOpacity(
        //   child: const Icon(CupertinoIcons.back, size: 25),
        //   onPressed: () => Navigator.of(context).pop(),
        // ),
        middle: const Text(
          "Appearance",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 32),

                    // --- HERO HEADER ---
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              CupertinoIcons.paintbrush_fill,
                              size: 60,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Customization",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              "Personalize your vault's visual interface and effects.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // --- MAIN SETTINGS SECTION ---
                    MenuSection(
                      borderRadius: _borderRadius,
                      menuSpacing: 16.0,
                      children: [
                        MenuItemToggle(
                          icon: CupertinoIcons.moon_fill,
                          iconColor: CupertinoColors.systemIndigo,
                          title: "Dark Mode",
                          subtitle: "Switch between light and dark themes",
                          value: ref.watch(settingsModelProvider).darkmode,
                          onChanged: (value) {
                            ref.read(settingsModelProvider).toggleDarkMode();
                          },
                          divider: true,
                        ),
                        MenuItemToggle(
                          icon: CupertinoIcons.wand_stars,
                          iconColor: CupertinoColors.systemPink,
                          title: "Advanced Textures",
                          subtitle: "Enable blur and glassmorphism",
                          value:
                              ref.watch(settingsModelProvider).advancedTextures,
                          onChanged: (value) {
                            ref
                                .read(settingsModelProvider)
                                .toggleAdvancedTextures();
                          },
                          divider: false,
                        ),
                      ],
                    ),

                    // --- EXPLANATORY FOOTER ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 12, 32, 0),
                      child: Text(
                        "Advanced Textures include background blurs and high-fidelity gradients. Turning this off can improve battery life on older devices.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.tertiaryLabel
                              .resolveFrom(context),
                          height: 1.3,
                        ),
                      ),
                    ),

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
