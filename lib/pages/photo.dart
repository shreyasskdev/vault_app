import 'package:flutter/material.dart';
import 'package:wallet/widget/touchable.dart';
import 'dart:io';

class PhotoView extends StatelessWidget {
  final String url;
  const PhotoView({super.key, required this.url});

  @override
  @override
  Widget build(BuildContext context) {
    print(url);
    return Scaffold(
      appBar: AppBar(
        leading: TouchableOpacity(
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 25,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text("Photo"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        forceMaterialTransparency: true,
      ),
      body: InteractiveViewer(
        child: Center(
          child: Hero(
            tag: url,
            child: Image.file(
              File(url),
              fit: BoxFit.contain,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                print("Wallet_Error: $error");
                return const Center(
                  child: Text("error"),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
