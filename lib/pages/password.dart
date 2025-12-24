import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vault/router_provider.dart';
import 'package:vault/utils/file_api_wrapper.dart' as fileapi;

class Password extends ConsumerStatefulWidget {
  const Password({super.key});

  @override
  ConsumerState<Password> createState() => _PasswordState();
}

class _PasswordState extends ConsumerState<Password>
    with fileapi.FileApiWrapper {
  final _controller = TextEditingController();
  String? errorMessage;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    // Ensures the Unlock button updates its state immediately when typing
    _controller.addListener(() => setState(() {}));
  }

  void checkPassword() async {
    if (_isChecking || _controller.text.isEmpty) return;

    setState(() {
      _isChecking = true;
      errorMessage = null;
    });

    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String directory = '${appDocDir.path}/Collections';

      final isCorrect = await setPasswordWrapper(_controller.text, directory);

      if (!mounted) return;

      if (isCorrect) {
        ref.read(isAuthenticatedProvider.notifier).state = true;
      } else {
        setState(() {
          errorMessage = "Incorrect password. Please try again.";
          _controller.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = "An error occurred: ${e.toString()}";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final theme = CupertinoTheme.of(context);
    final bgColor =
        CupertinoColors.systemGroupedBackground.resolveFrom(context);

    // --- LOADING STATE ---
    if (isAuthenticated) {
      return CupertinoPageScaffold(
        backgroundColor: bgColor,
        navigationBar: CupertinoNavigationBar(
          automaticallyImplyLeading: false,
          backgroundColor: bgColor.withOpacity(0.8),
          middle: const Text("Vault",
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoActivityIndicator(radius: 15),
              SizedBox(height: 16),
              Text("Decrypting...",
                  style: TextStyle(
                      fontSize: 16, color: CupertinoColors.secondaryLabel)),
            ],
          ),
        ),
      );
    }

    // --- UNLOCK STATE ---
    return CupertinoPageScaffold(
      backgroundColor: bgColor,
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
                      // --- HERO ICON ---
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.lock_fill,
                          size: 70,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- TITLES ---
                      const Text(
                        "Unlock Vault",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Enter your password to access\nyour encrypted gallery.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.secondaryLabel
                              .resolveFrom(context),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // --- TEXT FIELD ---
                      CupertinoTextField(
                        controller: _controller,
                        autofocus: true,
                        obscureText: true,
                        enabled: !_isChecking,
                        placeholder: "Password",
                        padding: const EdgeInsets.all(16),
                        clearButtonMode: OverlayVisibilityMode.editing,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => checkPassword(),
                        decoration: BoxDecoration(
                          color: CupertinoColors
                              .secondarySystemGroupedBackground
                              .resolveFrom(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: errorMessage != null
                                ? CupertinoColors.systemRed
                                : CupertinoColors.separator
                                    .resolveFrom(context),
                            width: 1,
                          ),
                        ),
                        onChanged: (_) {
                          if (errorMessage != null)
                            setState(() => errorMessage = null);
                        },
                      ),

                      // --- ERROR MESSAGE ---
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

                      const SizedBox(height: 24),

                      // --- UNLOCK BUTTON ---
                      SizedBox(
                        width: double.infinity,
                        child: ListenableBuilder(
                          listenable: _controller,
                          builder: (context, _) {
                            // The button only cares about these two values
                            final bool canUnlock =
                                _controller.text.isNotEmpty && !_isChecking;

                            return CupertinoButton.filled(
                              borderRadius: BorderRadius.circular(14),
                              onPressed: canUnlock ? checkPassword : null,
                              child: _isChecking
                                  ? const CupertinoActivityIndicator()
                                  : const Text(
                                      "Unlock",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                            );
                          },
                        ),
                      ),

                      // Extra space for the keyboard to breathe
                      const SizedBox(height: 40),
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
