import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_io.dart';
import 'package:vault/widget/touchable.dart';
import 'dart:io';

import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import 'package:vault/utils/file_api_wrapper.dart' as fileapi;

class PhotoView extends ConsumerStatefulWidget {
  final String url;
  final int index;
  final int count;
  const PhotoView(
      {super.key, required this.url, required this.index, required this.count});

  @override
  ConsumerState<PhotoView> createState() => _PhotoViewState();
}

class _PhotoViewState extends ConsumerState<PhotoView>
    with fileapi.FileApiWrapper {
  late final PageController pageController;
  List<Map<String, (String, double)>>? imageValue;
  Uint8List? finalImage;
  Uint8List? thumbImage;

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: widget.index);
  }

  Future<Widget> chainedAsyncOperations(index) async {
    final results = await Future.wait([
      getFileThumbWrapper(
          "${widget.url}/${imageValue?[index].keys.toList().first}", ref),
      getImagesWrapper(widget.url)
    ]);

    thumbImage = results[0] as Uint8List;
    imageValue ??= sortMapToList(results[1] as Map<String, (String, double)>);

    Uint8List imageData = await getFileWrapper(
        "${widget.url}/${imageValue?[index].keys.toList().first}", ref);

    return Image.memory(
      Uint8List.fromList(imageData),
      fit: BoxFit.contain,
      width: double.infinity,
    );
  }

  Widget _buildImagePage() {
    return PhotoViewGallery.builder(
      scrollPhysics: (Platform.isFuchsia ||
              Platform.isLinux ||
              Platform.isWindows ||
              Platform.isMacOS)
          ? const ScrollPhysics()
          : const BouncingScrollPhysics(),
      gaplessPlayback: true,
      builder: (BuildContext context, int index) {
        return PhotoViewGalleryPageOptions.customChild(
          child: ImageLoader(
            index: widget.index,
            future: chainedAsyncOperations(widget.index),
          ),
          initialScale: PhotoViewComputedScale.contained,
          minScale: PhotoViewComputedScale.contained,
          // heroAttributes: PhotoViewHeroAttributes(tag: index),
        );
      },
      itemCount: widget.count,
      pageController: pageController,
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
        _buildImagePage(),
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

class ImageLoader extends StatefulWidget {
  final int index;
  final Future<Widget> future;

  const ImageLoader({required this.index, required this.future, super.key});

  @override
  _ImageLoaderState createState() => _ImageLoaderState();
}

class _ImageLoaderState extends State<ImageLoader> {
  late Future<Widget> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      key: const ValueKey("stable-future-builder"),
      future: _future,
      initialData: const Center(child: CircularProgressIndicator()),
      builder: (context, snapshot) {
        return snapshot.data!;
      },
    );
  }
}
