import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vault/providers.dart';
import 'package:vault/widget/menu_item.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:vault/utils/file_api_wrapper.dart' as fileapi;

class PrivacySettings extends ConsumerStatefulWidget {
  const PrivacySettings({super.key});

  @override
  ConsumerState<PrivacySettings> createState() => _PrivacySettingsState();
}

class _PrivacySettingsState extends ConsumerState<PrivacySettings>
    with fileapi.FileApiWrapper {
  static const double _menuSpacing = 16.0;
  static const double _borderRadius = 20.0;

  void _showCupertinoNotify(String message, {String title = "Security"}) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Done"),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  Future<void> backupAll() async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text("Backup Encryption"),
          content: const Text(
              "Encrypting your backup adds an extra layer of security. You will need a password to restore it later."),
          actions: [
            CupertinoDialogAction(
              child: const Text("No, Plain Zip"),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text("Yes, Encrypt"),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String rootDirectory = '${appDocDir.path}/Collections';
    String downloadPath;

    if (Platform.isAndroid) {
      downloadPath = '/storage/emulated/0/Download/vault_backup.zip';
    } else {
      Directory? appDownloadDir = await getDownloadsDirectory();
      downloadPath = '${appDownloadDir?.path}/vault_backup.zip';
    }

    await zipBackupWrapper(rootDirectory, downloadPath, result);

    if (mounted) {
      _showCupertinoNotify(
        'Backup created successfully. \n\nLocation: $downloadPath',
        title: "Backup Complete",
      );
    }
  }

  Future<void> restoreBackup() async {
    final currentContext = context;
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result != null && result.files.single.path != null) {
        String zipPath = result.files.single.path!;
        String? password;

        if (await checkZipEncryptedWrapper(zipPath)) {
          password = await showPasswordDialog(currentContext, zipPath);
          if (password == null) return;
        }

        showCupertinoDialog(
          context: currentContext,
          barrierDismissible: false,
          builder: (_) =>
              const Center(child: CupertinoActivityIndicator(radius: 15)),
        );

        Directory appDocDir = await getApplicationDocumentsDirectory();
        String rootDirectory = '${appDocDir.path}/Collections';

        await restoreBackupWrapper(rootDirectory, zipPath, password);

        if (currentContext.mounted) Navigator.of(currentContext).pop();
        if (currentContext.mounted) {
          _showCupertinoNotify(
              'Your vault contents have been restored successfully.',
              title: "Restore Success");
        }
      }
    } catch (e) {
      if (currentContext.mounted) Navigator.of(currentContext).pop();
      if (currentContext.mounted) {
        _showCupertinoNotify(
            'Restore failed: ${e.toString().replaceFirst("Exception: ", "")}',
            title: "Error");
      }
    }
  }

  Future<String?> showPasswordDialog(
      BuildContext context, String zipPath) async {
    final TextEditingController passwordController = TextEditingController();
    bool isChecking = false;
    String? error;

    return showCupertinoDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return CupertinoAlertDialog(
              title: const Text("Vault Password"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      "This backup is encrypted. Please enter the decryption key:"),
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: passwordController,
                    obscureText: true,
                    autofocus: true,
                    placeholder: "Password",
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.tertiarySystemFill
                          .resolveFrom(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(error!,
                          style: const TextStyle(
                              color: CupertinoColors.destructiveRed,
                              fontSize: 13)),
                    ),
                  if (isChecking)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: CupertinoActivityIndicator(),
                    ),
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.of(context).pop(null),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: isChecking
                      ? null
                      : () async {
                          if (passwordController.text.isEmpty) return;
                          setState(() {
                            isChecking = true;
                            error = null;
                          });
                          try {
                            final isCorrect = await checkZipPasswordWrapper(
                                zipPath, passwordController.text);
                            if (isCorrect) {
                              if (context.mounted) {
                                Navigator.of(context)
                                    .pop(passwordController.text);
                              }
                            } else {
                              setState(() {
                                isChecking = false;
                                error = "Incorrect password";
                              });
                            }
                          } catch (e) {
                            setState(() {
                              isChecking = false;
                              error = "Verification error";
                            });
                          }
                        },
                  child: const Text("Verify"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final bgColor =
        CupertinoColors.systemGroupedBackground.resolveFrom(context);

    return CupertinoPageScaffold(
      backgroundColor: bgColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: bgColor.withOpacity(0.9),
        border: null,
        // leading: TouchableOpacity(
        //   child: const Icon(CupertinoIcons.back, size: 25),
        //   onPressed: () => Navigator.of(context).pop(),
        // ),
        middle: const Text("Privacy & Security",
            style: TextStyle(fontWeight: FontWeight.w600)),
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
                  children: [
                    const SizedBox(height: 32),

                    // --- HERO HEADER ---
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              CupertinoIcons.shield_lefthalf_fill,
                              size: 60,
                              color: theme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Security Hub",
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -1),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              "Manage your theft protection settings and encrypted backups.",
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

                    // --- PROTECTION SECTION ---
                    MenuSection(
                      borderRadius: _borderRadius,
                      menuSpacing: 16.0,
                      children: [
                        MenuItemToggle(
                          // CHANGED: bell_circle_fill or waveform_path_ecg represents motion/alarm better
                          icon: CupertinoIcons.bell_circle_fill,
                          iconColor:
                              CupertinoColors.systemRed, // Red for Alarms/Theft
                          title: "Theft Protection",
                          subtitle: "Alerts based on device gyroscope",
                          value:
                              ref.watch(settingsModelProvider).theftProtection,
                          onChanged: (value) => ref
                              .read(settingsModelProvider)
                              .toggleTheftProtection(),
                          divider: true,
                        ),
                        MenuItemToggle(
                          // CHANGED: eye_slash_fill is the gold standard for Privacy
                          icon: CupertinoIcons.eye_slash_fill,
                          iconColor: CupertinoColors
                              .systemBlue, // Blue for Privacy/System
                          title: "Privacy Screen",
                          subtitle:
                              "Prevents screenshots, screen recording, and recent-apps previews",
                          value: ref.watch(settingsModelProvider).secureContent,
                          onChanged: (value) => ref
                              .read(settingsModelProvider)
                              .toggleSecureContent(),
                          divider: false,
                        ),
                      ],
                    ),

                    const SizedBox(height: _menuSpacing),

                    // --- DATA SECTION ---
                    MenuSection(
                      borderRadius: _borderRadius,
                      menuSpacing: 16.0,
                      children: [
                        MenuItem(
                          icon: CupertinoIcons.cloud_upload,
                          iconColor: theme.primaryColor,
                          title: "Local Backup",
                          subtitle: "Export all data to a secure ZIP",
                          onTap: backupAll,
                          divider: true,
                        ),
                        MenuItem(
                          icon: CupertinoIcons.cloud_download,
                          iconColor: CupertinoColors.systemGreen,
                          title: "Restore Backup",
                          subtitle: "Import contents from a previous backup",
                          onTap: restoreBackup,
                          divider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
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
