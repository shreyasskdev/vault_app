import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vault/router_provider.dart';
import 'package:vault/utils/file_api_wrapper.dart' as fileapi;

class SetupPage extends ConsumerStatefulWidget {
  const SetupPage({super.key});

  @override
  ConsumerState<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends ConsumerState<SetupPage>
    with fileapi.FileApiWrapper {
  final _controller = TextEditingController();
  String? errorMessage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {});
    });
  }

  void savePassword() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
      errorMessage = null;
    });

    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String directory = '${appDocDir.path}/Collections';

      await savePasswordWrapper(_controller.text, directory);

      if (!mounted) return;

      ref.invalidate(passwordExistsProvider);
      await ref.read(passwordExistsProvider.future);

      ref.read(isAuthenticatedProvider.notifier).state = true;
    } catch (e) {
      if (mounted) {
        ref.read(isAuthenticatedProvider.notifier).state = false;
        setState(() {
          errorMessage = "Failed to save password: ${e.toString()}";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final bgColor =
        CupertinoColors.systemGroupedBackground.resolveFrom(context);

    return CupertinoPageScaffold(
      backgroundColor: bgColor,
      // We use a transparent Nav Bar for a "Hero" landing page look
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: CupertinoColors.transparent,
        border: null,
        enableBackgroundFilterBlur: false,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // --- ICON HEADER ---
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.lock_shield_fill,
                          size: 80,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- TITLE ---
                      const Text(
                        "Secure Your Vault",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Set a password to encrypt your photos.\nThis cannot be recovered if lost.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.secondaryLabel
                              .resolveFrom(context),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // --- INPUT FIELD ---
                      CupertinoTextField(
                        controller: _controller,
                        obscureText: true,
                        autofocus: true,
                        enabled: !_isSaving,
                        placeholder: "Enter new password",
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: CupertinoColors
                              .secondarySystemGroupedBackground
                              .resolveFrom(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                CupertinoColors.separator.resolveFrom(context),
                          ),
                        ),
                        onSubmitted: (value) {
                          if (_controller.text.isNotEmpty) savePassword();
                        },
                      ),

                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: CupertinoColors.destructiveRed,
                              fontSize: 13,
                            ),
                          ),
                        ),

                      const SizedBox(height: 32),

                      // --- ACTION BUTTON ---
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton.filled(
                          borderRadius: BorderRadius.circular(14),
                          onPressed: _isSaving || _controller.text.isEmpty
                              ? null
                              : savePassword,
                          child: _isSaving
                              ? const CupertinoActivityIndicator()
                              : const Text(
                                  "Create Password",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                      const SizedBox(height: 40), // Bottom padding for keyboard
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
