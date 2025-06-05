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
    // Pre-load the image list
    _loadImageList();
  }

  Future<void> _loadImageList() async {
    if (imageValue == null) {
      final images = await getImagesWrapper(widget.url);
      setState(() {
        imageValue = sortMapToList(images as Map<String, (String, double)>);
      });
    }
  }

  Future<Widget> chainedAsyncOperations(int index) async {
    // Ensure imageValue is loaded first
    if (imageValue == null) {
      final images = await getImagesWrapper(widget.url);
      imageValue = sortMapToList(images as Map<String, (String, double)>);
    }

    // Get the image key for the specific index
    final imageKey = imageValue?[index].keys.toList().first;
    if (imageKey == null) {
      return const Center(child: Text('Image not found'));
    }

    final results = await Future.wait([
      getFileThumbWrapper("${widget.url}/$imageKey", ref),
      getFileWrapper("${widget.url}/$imageKey", ref),
    ]);

    thumbImage = results[0] as Uint8List;
    final imageData = results[1] as Uint8List;

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
            index: index, // Use the gallery index, not widget.index
            future: chainedAsyncOperations(index), // Use the gallery index
          ),
          initialScale: PhotoViewComputedScale.contained,
          minScale: PhotoViewComputedScale.contained,
          heroAttributes: PhotoViewHeroAttributes(tag: index),
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
  void didUpdateWidget(ImageLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update future if index changes
    if (oldWidget.index != widget.index) {
      _future = widget.future;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      key: ValueKey("future-builder-${widget.index}"), // Use index-specific key
      future: _future,
      initialData: const Center(child: CircularProgressIndicator()),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        return snapshot.data!;
      },
    );
  }
}
