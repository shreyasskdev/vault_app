import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

  void setPassword() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String directory = '${appDocDir.path}/Collections';

    await setPasswordWrapper(_controller.text, directory).then((value) {
      if (value) {
        if (mounted) {
          ref.read(isAuthenticatedProvider.notifier).state = true;
        }
      } else {
        setState(() {
          errorMessage = "Wrong password";
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    // If authenticated, show loading instead of password form
    if (isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("Vault",
              style: TextStyle(fontWeight: FontWeight.w600)),
          centerTitle: true,
          actions: const <Widget>[
            Padding(
              padding:
                  EdgeInsets.only(right: 15, left: 10, top: 10, bottom: 10),
              child: Icon(Icons.add_circle_outline_rounded, size: 25),
            ),
          ],
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoActivityIndicator(),
              SizedBox(height: 8),
              Text("Loading...", style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

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
                  onChanged: (_) => {
                    setState(() {
                      errorMessage = "";
                    })
                  },
                  decoration: const InputDecoration(
                    hintText: "Password",
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
