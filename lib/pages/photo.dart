import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_io.dart';
import 'package:vault/widget/touchable.dart';
import 'dart:io';

import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
// import 'package:vault/src/rust/api/file.dart' as api;

import 'package:vault/utils/file_api_wrapper.dart' as fileapi;

class PhotoView extends StatefulWidget {
  final String url;
  final int index;
  final int count;
  const PhotoView(
      {super.key, required this.url, required this.index, required this.count});

  @override
  State<PhotoView> createState() => _PhotoViewState();
}

class _PhotoViewState extends State<PhotoView> with fileapi.FileApiWrapper {
  late final PageController pageController;

  @override
  void initState() {
    super.initState();
    // getImages();
    pageController = PageController(initialPage: widget.index);
  }

  // void getImages() async {
  //   await getImagesWrapper(widget.url).then((value) => setState(() {
  //         files = value;
  //       }));
  // }

  Future<Widget> chainedAsyncOperations(index) async {
    final images = await getImagesWrapper(widget.url);
    Uint8List imageData =
        await getFileWrapper("${widget.url}/${images[index]}");

    return Image.memory(
      Uint8List.fromList(imageData),
      fit: BoxFit.contain,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        debugPrint("Vault error: INFO: $error");
        return const Center(
          child: Text("error"),
        );
      },
    );
  }

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
            return PhotoViewGalleryPageOptions.customChild(
              child: FutureBuilder<Widget>(
                future: chainedAsyncOperations(index),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return snapshot.data!;
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
              // child: FutureBuilder<Uint8List>(
              //   future: getFileWrapper("${widget.url}/${files[index]}"),
              //   builder: (context, snapshot) {
              //     if (snapshot.hasData) {
              //       return Image.memory(
              //         Uint8List.fromList(snapshot.data!),
              //         fit: BoxFit.contain,
              //         width: double.infinity,
              //         errorBuilder: (context, error, stackTrace) {
              //           debugPrint("Vault error: INFO: $error");
              //           return const Center(
              //             child: Text("error"),
              //           );
              //         },
              //       );
              //     } else {
              //       return const Center(child: CircularProgressIndicator());
              //     }
              //   },
              // ),
              initialScale: PhotoViewComputedScale.contained,
              minScale: PhotoViewComputedScale.contained,
              heroAttributes: PhotoViewHeroAttributes(tag: index),
            );
          },
          itemCount: widget.count,

          loadingBuilder: (context, event) => Center(
            child: Container(
              width: 20.0,
              height: 20.0,
              color: const Color.fromARGB(255, 14, 14, 14),
              child: const CircularProgressIndicator(),
            ),
          ),
          // backgroundDecoration: widget.backgroundDecoration,
          pageController: pageController,
          // pageController: PageController(initialPage: 5),
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
