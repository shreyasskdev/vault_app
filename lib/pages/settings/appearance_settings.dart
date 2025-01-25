import 'package:flutter/material.dart';
import 'package:vault/widget/touchable.dart';

class AppearanceSettings extends StatefulWidget {
  const AppearanceSettings({super.key});

  @override
  State<AppearanceSettings> createState() => _AppearanceSettingsState();
}

class _AppearanceSettingsState extends State<AppearanceSettings> {
  static const double _menuSpacing = 15.0;
  static const double _borderRadius = 20.0;

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
        title: const Text("Appearance",
            style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SizedBox.expand(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          child: Column(
            children: [
              const SizedBox(height: _menuSpacing),
              _buildMenuSection(
                context,
                [
                  _buildMenuItem(
                    context: context,
                    icon: Icons.lock,
                    iconColor: theme.colorScheme.primary,
                    title: "Privacy",
                    subtitle: "Privacy and security settings",
                    onTap: () => {},
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.palette,
                    iconColor: theme.colorScheme.primary,
                    title: "Appearance",
                    subtitle: "Customize app appearance",
                    onTap: () => {},
                    divider: false,
                  ),
                ],
              ),
              const SizedBox(height: _menuSpacing),
              _buildMenuSection(
                context,
                [
                  _buildMenuItem(
                    context: context,
                    icon: Icons.info,
                    iconColor: theme.colorScheme.primary,
                    title: "About",
                    subtitle: "Learn more about this app",
                    onTap: () => {},
                    divider: false,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: _menuSpacing),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(_borderRadius),
        // border: Border.all(
        //   color: Theme.of(context).dividerColor.withOpacity(0.1),
        // ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool divider = true,
  }) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: iconColor),
          title: Text(
            title,
            // style: textTheme.titleMedium?.copyWith(
            //   fontWeight: FontWeight.w500,
            // ),
            style: textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color!.withAlpha(160),
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: theme.dividerColor,
            size: 20,
          ),
          onTap: onTap,
        ),
        if (divider)
          Divider(
            height: 1,
            indent: 20,
            endIndent: 20,
            color: theme.dividerColor.withAlpha(25),
          ),
      ],
    );
  }
}
