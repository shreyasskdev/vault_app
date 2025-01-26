import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vault/settings_model.dart';
import 'package:vault/widget/menu_item.dart';
import 'package:vault/widget/touchable.dart';

class AppearanceSettings extends StatefulWidget {
  const AppearanceSettings({super.key});

  @override
  State<AppearanceSettings> createState() => _AppearanceSettingsState();
}

class _AppearanceSettingsState extends State<AppearanceSettings> {
  static const double _menuSpacing = 10.0;
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
              MenuSection(
                borderRadius: _borderRadius,
                menuSpacing: _menuSpacing,
                children: [
                  MenuItemToggle(
                    // context: context,
                    icon: CupertinoIcons.brightness,
                    // icon: Icons.sunny,
                    iconColor: theme.colorScheme.primary,
                    title: "Dark Mode",
                    subtitle: "Toggle Dark mode",
                    value: Provider.of<SettingsModel>(context).darkmode,
                    onChanged: (value) => {
                      Provider.of<SettingsModel>(context, listen: false)
                          .toggleDarkmode()
                    },
                  ),
                  MenuItem(
                    icon: CupertinoIcons.paintbrush,
                    // icon: Icons.palette,
                    iconColor: theme.colorScheme.primary,
                    title: "Appearance",
                    subtitle: "Customize app appearance",
                    onTap: () => {},
                    divider: false,
                  ),
                ],
              ),
              const SizedBox(height: _menuSpacing),
              MenuSection(
                borderRadius: _borderRadius,
                menuSpacing: _menuSpacing,
                children: [
                  MenuItem(
                    icon: CupertinoIcons.info,
                    // icon: Icons.info,
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
}
