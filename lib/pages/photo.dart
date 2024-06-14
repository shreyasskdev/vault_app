import 'package:flutter/material.dart';

class PhotoView extends StatelessWidget {
  final String url;
  const PhotoView({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Photo"),
      ),
      body: Center(
        child: Hero(
          tag: "photo0",
          child: Image.network(
            "https://picsum.photos/1000/1200",
            fit: BoxFit.fill,
            width: double.infinity,
          ),
        ),
      ),
    );
  }
}
