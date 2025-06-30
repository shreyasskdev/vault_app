import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vault/providers.dart';
import 'package:vault/widget/menu_item.dart';
import 'package:vault/widget/touchable.dart';
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
  static const double _menuSpacing = 10.0;
  static const double _borderRadius = 20.0;

  Future<void> backupAll() async {
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
    String rootDirectory = '${appDocDir.path}/Collections';
    String downloadPath;

    if (Platform.isAndroid) {
      downloadPath = '/storage/emulated/0/Download/vault_backup.zip';
    } else {
      Directory? appDownloadDir = await getDownloadsDirectory();
      downloadPath = '${appDownloadDir?.path}/vault_backup.zip';
    }

    await zipBackupWrapper(rootDirectory, downloadPath, result);

    final snackBar = SnackBar(
      content: Text(
          'Backup ${result ? "with encryption" : "without encryption"} saved to $downloadPath'),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
        String? password; // Password will be null if not encrypted

        if (await checkZipEncryptedWrapper(zipPath)) {
          // The dialog now handles verification and only returns a
          // password if it's correct.
          password = await showPasswordDialog(currentContext, zipPath);

          // If the password is null, it means the user cancelled the dialog.
          if (password == null) return;
        }

        // If we get here, we're ready to restore.
        showDialog(
            context: currentContext,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()));

        Directory appDocDir = await getApplicationDocumentsDirectory();
        String rootDirectory = '${appDocDir.path}/Collections';

        await restoreBackupWrapper(rootDirectory, zipPath, password);

        if (currentContext.mounted) Navigator.of(currentContext).pop();

        if (currentContext.mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            const SnackBar(
              content: Text('Restore successful!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (currentContext.mounted) Navigator.of(currentContext).pop();
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text(
                'Restore failed: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> showPasswordDialog(
      BuildContext context, String zipPath) async {
    // This function now takes the zipPath to perform the check internally
    final TextEditingController passwordController = TextEditingController();
    // A key to manage the form state, especially for validation
    final formKey = GlobalKey<FormState>();
    String? errorMessage;
    bool isChecking = false;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Use a StatefulWidget to manage error messages and loading state
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Enter Password"),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                        "This archive is encrypted. Please enter the password:"),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        // Display the error message from our state
                        errorText: errorMessage,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password cannot be empty';
                        }
                        return null;
                      },
                    ),
                    if (isChecking) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.of(context).pop(null),
                ),
                TextButton(
                  // Disable the button while checking
                  onPressed: isChecking
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              isChecking = true;
                              errorMessage = null;
                            });

                            try {
                              final isPasswordCorrect =
                                  await checkZipPasswordWrapper(
                                zipPath,
                                passwordController.text,
                              );

                              if (isPasswordCorrect) {
                                // If correct, close the dialog and return the password
                                if (context.mounted)
                                  Navigator.of(context)
                                      .pop(passwordController.text);
                              } else {
                                // If wrong, update the state to show an error message
                                setState(() {
                                  errorMessage =
                                      'Incorrect password. Please try again.';
                                  isChecking = false;
                                });
                              }
                            } catch (e) {
                              setState(() {
                                errorMessage =
                                    'An error occurred. Please try again.';
                                isChecking = false;
                              });
                            }
                          }
                        },
                  child: const Text("OK"),
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
        title: const Text("Privacy",
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
                    title: "Theft protection",
                    subtitle: "Theft protection with gyrosope",
                    value: ref.watch(SettingsModelProvider).TheftProtection,
                    onChanged: (value) => {
                      ref.read(SettingsModelProvider).toggleTheftProtection()
                    },
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
                    title: "Local Backup",
                    subtitle: "Backup all the contents encrypted or not",
                    onTap: backupAll,
                    divider: true,
                  ),
                  MenuItem(
                    icon: CupertinoIcons.cloud_download,
                    // icon: Icons.info,
                    iconColor: theme.colorScheme.primary,
                    title: "Restore Backup",
                    subtitle: "Restore all the contents encrypted or not",
                    onTap: restoreBackup,
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
