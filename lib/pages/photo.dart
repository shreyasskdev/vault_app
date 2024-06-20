import 'package:flutter/material.dart';
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
        title: const Text("Photo"),
      ),
      body: Center(
        child: Hero(
          tag: url,
          child: Image.file(
            File(url),
            fit: BoxFit.fill,
            width: double.infinity,
          ),
        ),
      ),
    );
  }
}
