import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vault/widget/touchable.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: TouchableOpacity(
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 25,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "About Vault",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App Icon or Illustration
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                CupertinoIcons.lock_circle,
                size: 80,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),

            // App Title
            Text(
              "Vault",
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // App Tagline
            Text(
              "Your encrypted photo gallery.\nPrivacy at its best.",
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Features Section
            _buildFeatureItem(
              context,
              icon: CupertinoIcons.shield_fill,
              title: "End-to-End Encryption",
              subtitle:
                  "Your photos are encrypted locally, ensuring complete privacy.",
            ),
            const SizedBox(height: 20),
            _buildFeatureItem(
              context,
              icon: CupertinoIcons.lock_shield_fill,
              title: "Theft Protection",
              subtitle:
                  "Advanced theft protection with gyroscope-based alerts.",
            ),
            const SizedBox(height: 20),
            _buildFeatureItem(
              context,
              icon: CupertinoIcons.paintbrush,
              title: "Customizable Appearance",
              subtitle: "Personalize the app to suit your style.",
            ),

            const Spacer(),

            // Footer
            Text(
              "Version 0.0.1",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "© 2025 Vault Inc. All rights reserved.",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 28, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
