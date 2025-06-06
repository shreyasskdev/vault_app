import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vault/utils/file_api_wrapper.dart' as fileapi;

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> with fileapi.FileApiWrapper {
  final _controller = TextEditingController();
  String? errorMessage;

  void setPassword() async {
    await setPasswordWrapper(_controller.text).then((value) => {
          if (value)
            {
              if (mounted) {context.pushReplacement("/collections")}
            }
          else
            {
              setState(() {
                errorMessage = "Failed to set password";
              })
            }
        });
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
                const SizedBox(
                  height: 16,
                ),
                TextField(
                  autofocus: true,
                  controller: _controller,
                  onSubmitted: (String value) {
                    setPassword();
                  },
                  decoration: const InputDecoration(
                    hintText: "New password",
                    border: OutlineInputBorder(),
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
}
