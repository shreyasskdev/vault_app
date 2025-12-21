import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:progressive_blur/progressive_blur.dart';
import 'package:smooth_gradient/smooth_gradient.dart';
import 'package:vault/providers.dart';
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

  bool _showControls = true;
  Timer? _controlsTimer;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.index;
    pageController = PageController(initialPage: widget.index);

    if (widget.initialThumbnail != null) {
      _thumbnailCache[widget.index] = widget.initialThumbnail!;
    }

    _loadImageList();
    _resetControlsTimer();
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    pageController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    _controlsTimer?.cancel();
    setState(() => _showControls = !_showControls);
    if (_showControls) _resetControlsTimer();
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    if (!mounted) return;
    if (!_showControls) setState(() => _showControls = true);
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  Future<void> _loadImageList() async {
    if (imageValue != null) return;
    final images = await getImagesWrapper(widget.url);
    if (mounted) {
      setState(() => imageValue = sortMapToList(images));
      _preloadImages();
    }
  }

  void _preloadImages() {
    if (imageValue == null) return;
    final indicesToLoad = [_currentPage - 1, _currentPage, _currentPage + 1]
        .where((i) => i >= 0 && i < imageValue!.length)
        .toList();

    for (final index in indicesToLoad) {
      _loadThumbnailAtIndex(index);
      _loadFullImageAtIndex(index);
    }
  }

  Future<void> _loadFullImageAtIndex(int index) async {
    if (_fullImageCache.containsKey(index) ||
        imageValue == null ||
        index >= imageValue!.length) return;
    try {
      final imageKey = imageValue![index].keys.first;
      final fullImageData =
          await getFileWrapper("${widget.url}/$imageKey", ref);
      if (mounted && !_fullImageCache.containsKey(index)) {
        setState(
            () => _fullImageCache[index] = Uint8List.fromList(fullImageData));
      }
    } catch (e) {
      debugPrint("Error loading full image index $index: $e");
    }
  }

  Future<void> _loadThumbnailAtIndex(int index) async {
    if (_thumbnailCache.containsKey(index) ||
        imageValue == null ||
        index >= imageValue!.length) return;
    try {
      final imageKey = imageValue![index].keys.first;
      final thumbData =
          await getFileThumbWrapper("${widget.url}/$imageKey", ref);
      if (mounted && !_thumbnailCache.containsKey(index)) {
        setState(() => _thumbnailCache[index] = Uint8List.fromList(thumbData));
      }
    } catch (e) {
      debugPrint("Error loading thumbnail index $index: $e");
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _resetControlsTimer();
    final indicesToLoad = [index - 2, index + 2]
        .where((i) => i >= 0 && i < (imageValue?.length ?? 0))
        .toList();
    for (final i in indicesToLoad) {
      _loadThumbnailAtIndex(i);
      _loadFullImageAtIndex(i);
    }
  }

  // --- DELETE LOGIC ---

  Future<void> _handleDelete() async {
    if (imageValue == null || imageValue!.isEmpty) return;

    // Show iOS Style Confirmation
    final bool? confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Delete Photo?"),
        content: const Text(
            "This photo will be permanently removed from your vault."),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("Delete"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final fileName = imageValue![_currentPage].keys.first;
        final filePath = "${widget.url}/$fileName";

        // 1. Delete the physical file
        await deleteFileWrapper(filePath);

        // 2. Update Local State
        setState(() {
          imageValue!.removeAt(_currentPage);
          // Clear caches because indices have shifted
          _thumbnailCache.clear();
          _fullImageCache.clear();
        });

        // 3. Handle Navigation
        if (imageValue!.isEmpty) {
          if (mounted) Navigator.pop(context);
        } else {
          // If we deleted the last photo, move back one page
          if (_currentPage >= imageValue!.length) {
            _currentPage = imageValue!.length - 1;
          }
          // Preload the new current/surrounding images
          _preloadImages();
        }
      } catch (e) {
        debugPrint("Deletion error: $e");
      }
    }
  }

  Widget _buildImageLoader(int index) {
    final fullImageBytes = _fullImageCache[index];
    final thumbnailBytes = _thumbnailCache[index];

    if (fullImageBytes != null) {
      return FutureBuilder<Image>(
        key: ValueKey(fullImageBytes),
        future: compute(_decodeImage, fullImageBytes),
        builder: (context, snapshot) {
          if (snapshot.hasData) return snapshot.data!;
          if (thumbnailBytes != null) {
            return Image.memory(thumbnailBytes,
                fit: BoxFit.contain, gaplessPlayback: true);
          }
          return const Center(child: CircularProgressIndicator());
        },
      );
    }

    if (thumbnailBytes != null) {
      _loadFullImageAtIndex(index);
      return Image.memory(thumbnailBytes, fit: BoxFit.contain);
    }

    _loadThumbnailAtIndex(index);
    _loadFullImageAtIndex(index);
    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Platform.isFuchsia ||
        Platform.isLinux ||
        Platform.isWindows ||
        Platform.isMacOS;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final useAdvancedTextures =
        ref.watch(settingsModelProvider).advancedTextures;

    final Widget gallery = PhotoViewGallery.builder(
      scrollPhysics: const BouncingScrollPhysics(),
      gaplessPlayback: true,
      onPageChanged: _onPageChanged,
      backgroundDecoration:
          BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
      builder: (context, index) => PhotoViewGalleryPageOptions.customChild(
        child: _buildImageLoader(index),
        initialScale: PhotoViewComputedScale.contained,
        minScale: PhotoViewComputedScale.contained * 0.8,
        maxScale: PhotoViewComputedScale.contained * 3.0,
        heroAttributes: PhotoViewHeroAttributes(tag: index),
        onTapUp: (_, __, ___) => _toggleControls(),
      ),
      itemCount: imageValue?.length ?? widget.count,
      pageController: pageController,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _showControls ? 1.0 : 0.0,
          child: AppBar(
            leading: TouchableOpacity(
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 25),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text("Photo",
                style: TextStyle(fontWeight: FontWeight.w600)),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            forceMaterialTransparency: true,
          ),
        ),
      ),
      body: MouseRegion(
        onHover: (_) => _resetControlsTimer(),
        child: GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            children: [
              useAdvancedTextures
                  ? ProgressiveBlurWidget(
                      linearGradientBlur: const LinearGradientBlur(
                        values: [1, 0],
                        stops: [0, 0.25],
                        start: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      sigma: _showControls ? 24.0 : 0,
                      child: gallery,
                    )
                  : gallery,

              _buildTopFade(),

              if (isDesktop && _currentPage > 0)
                _buildSideNav(isLeft: true, icon: Icons.arrow_back_ios_new),
              if (isDesktop &&
                  _currentPage < (imageValue?.length ?? widget.count) - 1)
                _buildSideNav(isLeft: false, icon: Icons.arrow_forward_ios),

              // BOTTOM PILL ACTION BAR
              Positioned(
                bottom: bottomInset > 0 ? bottomInset : 25,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _showControls ? 1.0 : 0.0,
                    child: IgnorePointer(
                      ignoring: !_showControls,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            height: 60,
                            width: MediaQuery.of(context).size.width * 0.8,
                            constraints: const BoxConstraints(maxWidth: 400),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _pillAction(Icons.ios_share, () {}),
                                _pillAction(Icons.favorite_border, () {}),
                                _pillAction(Icons.info_outline, () {}),
                                _pillAction(Icons.delete_outline, _handleDelete,
                                    isDestructive: true),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopFade() {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _showControls ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: SmoothGradient(
              from: Theme.of(context).colorScheme.surface.withAlpha(255),
              to: Theme.of(context).colorScheme.surface.withAlpha(0),
              curve: const Cubic(.05, .26, 1, .55),
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSideNav({required bool isLeft, required IconData icon}) {
    return Positioned(
      left: isLeft ? 20 : null,
      right: !isLeft ? 20 : null,
      top: 0,
      bottom: 0,
      child: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _showControls ? 1.0 : 0.0,
          child: IgnorePointer(
            ignoring: !_showControls,
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.4),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      _resetControlsTimer();
                      isLeft
                          ? pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut)
                          : pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut);
                    },
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pillAction(IconData icon, VoidCallback onTap,
      {bool isDestructive = false}) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        _resetControlsTimer();
        onTap();
      },
      child: Icon(
        icon,
        size: 24,
        color: isDestructive ? Colors.redAccent : Colors.white.withOpacity(0.9),
      ),
    );
  }
}
