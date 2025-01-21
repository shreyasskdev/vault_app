import 'package:flutter/material.dart';
import 'package:vault/widget/touchable.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const double _menuSpacing = 8.0;

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
        title: const Text("Settings",
            style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildMenuSection(
                context,
                [
                  _buildMenuItem(
                    context: context,
                    icon: Icons.person,
                    iconColor: theme.colorScheme.primary,
                    title: "Account",
                    subtitle: "Manage your account settings",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const NotificationsPage()),
                    ),
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.notifications,
                    iconColor: theme.colorScheme.error,
                    title: "Notifications",
                    subtitle: "Manage notification preferences",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const NotificationsPage()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: _menuSpacing),
              _buildMenuSection(
                context,
                [
                  _buildMenuItem(
                    context: context,
                    icon: Icons.lock,
                    iconColor: theme.colorScheme.secondary,
                    title: "Privacy",
                    subtitle: "Privacy and security settings",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PrivacyPage()),
                    ),
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.palette,
                    iconColor: theme.colorScheme.tertiary,
                    title: "Appearance",
                    subtitle: "Customize app appearance",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PrivacyPage()),
                    ),
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
                    iconColor: theme.colorScheme.outline,
                    title: "About",
                    subtitle: "Learn more about this app",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PrivacyPage()),
                    ),
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
        borderRadius: BorderRadius.circular(_menuSpacing),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
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
  }) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: iconColor),
          title: Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: theme.dividerColor,
            size: 20,
          ),
          onTap: onTap,
        ),
        Divider(
          height: 1,
          indent: 56,
          endIndent: 0,
          color: theme.dividerColor.withOpacity(0.1),
        ),
      ],
    );
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notification Settings")),
      body: const Center(child: Text("Notification settings page")),
    );
  }
}

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Privacy Settings")),
      body: const Center(child: Text("Privacy settings page")),
    );
  }
}
