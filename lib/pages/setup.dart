import 'dart:io';
import 'package:flutter/material.dart';
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

      ref.read(isAuthenticatedProvider.notifier).state = true;
      ref.invalidate(passwordExistsProvider);
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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Set up your vault password",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  autofocus: true,
                  controller: _controller,
                  enabled: !_isSaving,
                  onSubmitted: (String value) {
                    if (value.isNotEmpty) {
                      savePassword();
                    }
                  },
                  decoration: const InputDecoration(
                    hintText: "New password",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving || _controller.text.isEmpty
                        ? null
                        : savePassword,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Save Password"),
                  ),
                ),
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
