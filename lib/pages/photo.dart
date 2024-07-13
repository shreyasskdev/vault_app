import 'package:flutter/material.dart';
import 'package:Vault/widget/touchable.dart';
import 'dart:io';

import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class PhotoView extends StatefulWidget {
  final String url;
  final int index;
  const PhotoView({super.key, required this.url, required this.index});

  @override
  State<PhotoView> createState() => _PhotoViewState();
}

class _PhotoViewState extends State<PhotoView> {
  List<FileSystemEntity> files = [];
  PageController pageController = PageController();

  @override
  void initState() {
    super.initState();
    getImages();
    pageController = PageController(initialPage: widget.index);
  }

  void getImages() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      List<FileSystemEntity> entities = Directory(widget.url).listSync();

      setState(() {
        files = entities.whereType<File>().toList();
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: TouchableOpacity(
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 25,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title:
            const Text("Photo", style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        forceMaterialTransparency: true,
      ),
      body: Stack(children: [
        PhotoViewGallery.builder(
          scrollPhysics: (Platform.isFuchsia ||
                  Platform.isLinux ||
                  Platform.isWindows ||
                  Platform.isMacOS)
              ? const ScrollPhysics()
              : const BouncingScrollPhysics(),

          builder: (BuildContext context, int index) {
            return PhotoViewGalleryPageOptions(
              imageProvider: Image.file(
                File(files[index].path),
                fit: BoxFit.contain,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  print("Wallet_Error: $error");
                  return const Center(
                    child: Text("error"),
                  );
                },
              ).image,
              initialScale: PhotoViewComputedScale.contained,
              minScale: PhotoViewComputedScale.contained,
              heroAttributes: PhotoViewHeroAttributes(tag: files[index].path),
            );
          },
          itemCount: files.length,

          // loadingBuilder: (context, event) => Center(
          //   child: Container(
          //     width: 20.0,
          //     height: 20.0,
          //     child: CircularProgressIndicator(
          //       value: event == null
          //           ? 0
          //           : event.cumulativeBytesLoaded / event.expectedTotalBytes,
          //     ),
          //   ),
          // ),
          // backgroundDecoration: widget.backgroundDecoration,
          pageController: pageController,
          // onPageChanged: onPageChanged,
        ),
        if (Platform.isFuchsia ||
            Platform.isLinux ||
            Platform.isWindows ||
            Platform.isMacOS)
          Positioned(
            left: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () => pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                ),
                child: const Icon(Icons.arrow_back_ios),
              ),
            ),
          ),
        if (Platform.isFuchsia ||
            Platform.isLinux ||
            Platform.isWindows ||
            Platform.isMacOS)
          Positioned(
            right: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () => pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                ),
                child: const Icon(Icons.arrow_forward_ios),
              ),
            ),
          ),
      ]),
    );
  }
}
