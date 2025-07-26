import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart'; // NEW: Import for the 'compute' function
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:vault/utils/file_api_wrapper.dart' as fileapi;
import 'package:vault/widget/touchable.dart';

Future<Image> _decodeImage(Uint8List imageBytes) async {
  return Image.memory(
    imageBytes,
    fit: BoxFit.contain,
    gaplessPlayback: true,
  );
}

class PhotoView extends ConsumerStatefulWidget {
  final String url;
  final int index;
  final int count;
  final Uint8List? initialThumbnail;

  const PhotoView({
    super.key,
    required this.url,
    required this.index,
    required this.count,
    this.initialThumbnail,
  });

  @override
  ConsumerState<PhotoView> createState() => _PhotoViewState();
}

class _PhotoViewState extends ConsumerState<PhotoView>
    with fileapi.FileApiWrapper {
  late final PageController pageController;
  List<Map<String, (String, double)>>? imageValue;

  final Map<int, Uint8List> _thumbnailCache = {};
  final Map<int, Uint8List> _fullImageCache = {};

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: widget.index);

    if (widget.initialThumbnail != null) {
      _thumbnailCache[widget.index] = widget.initialThumbnail!;
    }

    _loadImageList();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Future<void> _loadImageList() async {
    if (imageValue != null) return;

    final images = await getImagesWrapper(widget.url);
    if (mounted) {
      setState(() {
        imageValue = sortMapToList(images);
      });
      _preloadImages();
    }
  }

  void _preloadImages() {
    if (imageValue == null) return;

    final indicesToLoad = [
      widget.index - 1,
      widget.index,
      widget.index + 1,
    ].where((i) => i >= 0 && i < widget.count).toList();

    for (final index in indicesToLoad) {
      // No need to await these, let them run in the background
      _loadThumbnailAtIndex(index);
      _loadFullImageAtIndex(index);
    }
  }

  Future<void> _loadFullImageAtIndex(int index) async {
    if (_fullImageCache.containsKey(index) || imageValue == null) return;

    try {
      final imageKey = imageValue![index].keys.first;
      final fullImageData =
          await getFileWrapper("${widget.url}/$imageKey", ref);

      if (mounted && !_fullImageCache.containsKey(index)) {
        setState(() {
          _fullImageCache[index] = Uint8List.fromList(fullImageData);
        });
      }
    } catch (e) {
      debugPrint("Error loading full image at index $index: $e");
    }
  }

  Future<void> _loadThumbnailAtIndex(int index) async {
    if (_thumbnailCache.containsKey(index) || imageValue == null) return;

    try {
      final imageKey = imageValue![index].keys.first;
      final thumbData =
          await getFileThumbWrapper("${widget.url}/$imageKey", ref);

      if (mounted && !_thumbnailCache.containsKey(index)) {
        setState(() {
          _thumbnailCache[index] = Uint8List.fromList(thumbData);
        });
      }
    } catch (e) {
      debugPrint("Error loading thumbnail at index $index: $e");
    }
  }

  void _onPageChanged(int index) {
    // Pre-load images further away as the user swipes
    final indicesToLoad = [
      index - 2, // Pre-load two behind
      index + 2, // Pre-load two ahead
    ].where((i) => i >= 0 && i < widget.count).toList();

    for (final i in indicesToLoad) {
      _loadThumbnailAtIndex(i);
      _loadFullImageAtIndex(i);
    }
  }

  Widget _buildImageLoader(int index) {
    final fullImageBytes = _fullImageCache[index];
    final thumbnailBytes = _thumbnailCache[index];

    if (fullImageBytes != null) {
      return FutureBuilder<Image>(
        key: ValueKey(fullImageBytes),
        future: compute(_decodeImage, fullImageBytes), // Decode in background
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return snapshot.data!;
          } else {
            if (thumbnailBytes != null) {
              return Image.memory(
                thumbnailBytes,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              );
            }
            // Fallback if the thumbnail isn't ready either
            return const Center(child: CircularProgressIndicator());
          }
        },
      );
    }

    if (thumbnailBytes != null) {
      _loadFullImageAtIndex(index);
      return Image.memory(
        thumbnailBytes,
        fit: BoxFit.contain,
      );
    }

    _loadThumbnailAtIndex(index);
    _loadFullImageAtIndex(index);

    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  Widget _buildImagePage() {
    return PhotoViewGallery.builder(
      scrollPhysics: const BouncingScrollPhysics(),
      gaplessPlayback: true,
      onPageChanged: _onPageChanged,
      builder: (BuildContext context, int index) {
        return PhotoViewGalleryPageOptions.customChild(
          child: _buildImageLoader(index),
          initialScale: PhotoViewComputedScale.contained,
          minScale: PhotoViewComputedScale.contained * 0.8,
          maxScale: PhotoViewComputedScale.contained * 3.0,
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
