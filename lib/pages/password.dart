import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:go_router/go_router.dart';
// import 'package:vault/src/rust/api/file.dart' as api;
import 'package:vault/utils/file_api_wrapper.dart' as fileapi;

class Password extends StatefulWidget {
  const Password({super.key});

  @override
  State<Password> createState() => _PasswordState();
}

class _PasswordState extends State<Password> with fileapi.FileApiWrapper {
  final _controller = TextEditingController();

  void setPassword() async {
    await setPasswordWrapper(_controller.text);
    if (mounted) {
      context.pushReplacement("/collections");
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
                  "Enter the password",
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
                    hintText: "Password",
                    border: OutlineInputBorder(),
                  ),
                ),
                // const SizedBox(
                //     height: 16), // Adds spacing between TextField and Button
                // ElevatedButton(
                //   onPressed: setPassword,
                //   child: const Text("Submit"),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
