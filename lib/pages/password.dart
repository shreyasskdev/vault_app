import 'package:flutter/material.dart';
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
          child: Column(
            children: [
              TextField(
                autofocus: true,
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: "Passwords",
                ),
              ),
              ElevatedButton(
                onPressed: setPassword,
                child: const Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
