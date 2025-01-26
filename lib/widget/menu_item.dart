import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Widget _buildMenuSection(BuildContext context, List<Widget> children) {
//   return Container(
//     margin: const EdgeInsets.symmetric(horizontal: _menuSpacing),
//     decoration: BoxDecoration(
//       color: Theme.of(context).colorScheme.surfaceContainerLow,
//       borderRadius: BorderRadius.circular(_borderRadius),
//       // border: Border.all(
//       //   color: Theme.of(context).dividerColor.withOpacity(0.1),
//       // ),
//     ),
//     child: Column(children: children),
//   );
// }

class MenuSection extends StatelessWidget {
  final double menuSpacing;
  final double borderRadius;
  final List<Widget> children;

  const MenuSection({
    super.key,
    required this.menuSpacing,
    required this.borderRadius,
    required this.children,
  });
  // const MenuSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: menuSpacing),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(borderRadius),
        // border: Border.all(
        //   color: Theme.of(context).dividerColor.withOpacity(0.1),
        // ),
      ),
      child: Column(children: children),
    );
  }
}

class MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool divider;
  final Widget? trailing; // New parameter for trailing widget

  const MenuItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.divider = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: Material(
            color: theme.colorScheme.surfaceContainerLow,
            child: InkWell(
              onTap: onTap,
              splashColor: theme.colorScheme.primary.withAlpha(25),
              highlightColor: Colors.transparent,
              child: ListTile(
                leading: Icon(icon, color: iconColor),
                title: Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color!.withAlpha(160),
                  ),
                ),
                trailing: trailing, // Use the trailing widget if provided
              ),
            ),
          ),
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

class MenuItemToggle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool divider;

  const MenuItemToggle({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.divider = true,
  });

  @override
  Widget build(BuildContext context) {
    return MenuItem(
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      onTap: () => onChanged(!value), // Toggles value when tapped
      divider: divider,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
