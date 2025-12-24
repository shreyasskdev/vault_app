import 'package:flutter/cupertino.dart';
import 'package:vault/widget/menu_item.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final bgColor =
        CupertinoColors.systemGroupedBackground.resolveFrom(context);
    final primaryColor = theme.primaryColor;

    return CupertinoPageScaffold(
      backgroundColor: bgColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: bgColor.withOpacity(0.9),
        border: null,
        middle: const Text(
          "About Vault",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 40),

                    // --- HERO SECTION ---
                    Center(
                      child: Column(
                        children: [
                          // Native iOS App Icon Shape (Superellipse feel)
                          Container(
                            height: 110,
                            width: 110,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  primaryColor.withOpacity(0.8),
                                  primaryColor,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(
                                  26), // Smooth iOS radius
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.25),
                                  blurRadius: 25,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              CupertinoIcons.lock_shield_fill,
                              size: 55,
                              color: CupertinoColors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "Vault",
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800, // Heavier weight
                              letterSpacing: -1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Privacy at its best.",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: CupertinoColors.secondaryLabel
                                  .resolveFrom(context),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 44),

                    // --- FEATURES SECTION ---
                    MenuSection(
                      borderRadius: 20,
                      menuSpacing: 16,
                      children: [
                        _buildFeatureRow(
                          context,
                          icon: CupertinoIcons.shield_fill,
                          iconColor: CupertinoColors.systemGreen,
                          title: "End-to-End Encryption",
                          subtitle:
                              "Your photos are encrypted locally on your device.",
                        ),
                        _buildFeatureRow(
                          context,
                          icon: CupertinoIcons.device_phone_portrait,
                          iconColor: CupertinoColors.systemOrange,
                          title: "Theft Protection",
                          subtitle:
                              "Gyroscope-based alerts keep your phone safe.",
                        ),
                        _buildFeatureRow(
                          context,
                          icon: CupertinoIcons.paintbrush_fill,
                          iconColor: CupertinoColors.systemPurple,
                          title: "Customizable Design",
                          subtitle: "A beautiful experience tailored for iOS.",
                          isLast: true,
                        ),
                      ],
                    ),

                    // Push footer to bottom
                    const SizedBox(height: 60),

                    // --- FOOTER ---
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "Version 0.0.1 (Stable)",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: CupertinoColors.tertiaryLabel
                                  .resolveFrom(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "© 2025 Vault Inc. Built with Flutter.",
                            style: TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.tertiaryLabel
                                  .resolveFrom(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                if (!isLast)
                  Container(
                    height: 0.5,
                    color: CupertinoColors.separator.resolveFrom(context),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
