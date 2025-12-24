import 'package:flutter/cupertino.dart';

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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: menuSpacing),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground
            .resolveFrom(context),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Column(children: children),
      ),
    );
  }
}

class MenuItem extends StatelessWidget {
  final IconData icon;
  final Color? iconColor; // Optional: will default to primary blue
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool divider;
  final Widget? trailing;

  const MenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.divider = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return Column(
      children: [
        CupertinoListTile(
          padding: EdgeInsets.all(10),
          onTap: onTap,
          leading: Icon(
            icon,
            color: iconColor ?? theme.primaryColor,
            size: 22,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: CupertinoColors.label
                  .resolveFrom(context), // Adaptive black/white
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: CupertinoColors.secondaryLabel
                  .resolveFrom(context), // Adaptive grey
              fontSize: 13,
            ),
          ),
          // Default trailing is a chevron if nothing else is provided
          trailing: trailing ??
              Icon(
                CupertinoIcons.chevron_right,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                size: 18,
              ),
        ),
        if (divider)
          Padding(
            padding: const EdgeInsets.only(
                left: 54), // Align with text, skipping icon
            child: Container(
              height: 0.5, // iOS dividers are very thin
              color: CupertinoColors.separator.resolveFrom(context),
            ),
          ),
      ],
    );
  }
}

class MenuItemToggle extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool divider;

  const MenuItemToggle({
    super.key,
    required this.icon,
    this.iconColor,
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
      onTap: () => onChanged(!value),
      divider: divider,
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: CupertinoTheme.of(context).primaryColor,
      ),
    );
  }
}
