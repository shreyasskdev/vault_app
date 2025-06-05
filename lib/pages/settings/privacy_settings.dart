import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vault/providers.dart';
import 'package:vault/widget/menu_item.dart';
import 'package:vault/widget/touchable.dart';
import 'package:path_provider/path_provider.dart';

import 'package:vault/utils/file_api_wrapper.dart' as fileapi;

class PrivacySettings extends ConsumerStatefulWidget {
  const PrivacySettings({super.key});

  @override
  ConsumerState<PrivacySettings> createState() => _PrivacySettingsState();
}

class _PrivacySettingsState extends ConsumerState<PrivacySettings>
    with fileapi.FileApiWrapper {
  static const double _menuSpacing = 10.0;
  static const double _borderRadius = 20.0;

  Future backupAll() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Backup type"),
          content: const Text("Do you want to encrypt the backup?"),
          actions: [
            TextButton(
              child: const Text("No"),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text("Yes"),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (result == null) return; // cancelled

    WidgetsFlutterBinding.ensureInitialized();

    Directory appDocDir = await getApplicationDocumentsDirectory();
    Directory? appDownloadDir = await getDownloadsDirectory();
    String rootDirectory = '${appDocDir.path}/Collections';
    String downloadPath = '${appDownloadDir?.path}/vault_backup.zip';

    await zipBackupWrapper(rootDirectory, downloadPath, result);

    final snackBar = SnackBar(
      content: Text(
          'Backup ${result ? "with encryption" : "without encryption"} saved to $downloadPath'),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

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
                    title: "Teft protection",
                    subtitle: "Theft protection with gyrosope",
                    value: ref.watch(SettingsModelProvider).TheftProtection,
                    onChanged: (value) => {
                      ref.read(SettingsModelProvider).toggleTheftProtection()
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
                    icon: CupertinoIcons.cloud_upload,
                    // icon: Icons.info,
                    iconColor: theme.colorScheme.primary,
                    title: "Backup",
                    subtitle: "Backup all the contents encrypted or not",
                    onTap: backupAll,
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
