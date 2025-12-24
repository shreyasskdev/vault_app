import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // Required for SystemChrome
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:progressive_blur/progressive_blur.dart';
import 'package:smooth_gradient/smooth_gradient.dart';
import 'package:vault/providers.dart';
import 'package:vault/utils/file_api_wrapper.dart' as fileapi;

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

    // Set status bar to light/transparent for the photo viewer
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
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

  Future<void> _handleDelete() async {
    if (imageValue == null || imageValue!.isEmpty) return;

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
        await deleteFileWrapper(filePath);
        setState(() {
          imageValue!.removeAt(_currentPage);
          _thumbnailCache.clear();
          _fullImageCache.clear();
        });

        if (imageValue!.isEmpty) {
          if (mounted) Navigator.pop(context);
        } else {
          if (_currentPage >= imageValue!.length) {
            _currentPage = imageValue!.length - 1;
          }
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
          return const Center(child: CupertinoActivityIndicator());
        },
      );
    }

    if (thumbnailBytes != null) {
      _loadFullImageAtIndex(index);
      return Image.memory(thumbnailBytes, fit: BoxFit.contain);
    }

    _loadThumbnailAtIndex(index);
    _loadFullImageAtIndex(index);
    return Center(
      child: CupertinoActivityIndicator(
        color: CupertinoColors.label.resolveFrom(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Platform.isFuchsia ||
        Platform.isLinux ||
        Platform.isWindows ||
        Platform.isMacOS;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final useAdvancedTextures =
        ref.watch(settingsModelProvider).advancedTextures;

    final Widget gallery = PhotoViewGallery.builder(
      scrollPhysics: const BouncingScrollPhysics(),
      gaplessPlayback: true,
      onPageChanged: _onPageChanged,
      // 1. Force the gallery background to be black
      backgroundDecoration: BoxDecoration(
        color: CupertinoTheme.of(context).scaffoldBackgroundColor,
      ),
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

    return CupertinoPageScaffold(
      backgroundColor:
          CupertinoTheme.of(context).scaffoldBackgroundColor.withAlpha(0),
      resizeToAvoidBottomInset: false, // Prevent keyboard or system shifts
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: MouseRegion(
          onHover: (_) => _resetControlsTimer(),
          child: GestureDetector(
            onTap: _toggleControls,
            child: SizedBox.expand(
              // 2. Force the stack to fill every available pixel
              child: Stack(
                children: [
                  // --- LAYER 1: THE IMAGE GALLERY ---
                  Positioned.fill(
                    child: MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      removeBottom: true,
                      removeLeft: true,
                      removeRight: true,
                      child: useAdvancedTextures
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
                    ),
                  ),

                  // --- LAYER 2: TOP OVERLAYS ---
                  _buildTopFade(),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _showControls ? 1.0 : 0.0,
                      child: IgnorePointer(
                        ignoring: !_showControls,
                        child: Container(
                          padding: EdgeInsets.only(top: topPadding),
                          child: CupertinoNavigationBar(
                            backgroundColor: CupertinoTheme.of(context)
                                .scaffoldBackgroundColor
                                .withAlpha(0),
                            border: null,
                            enableBackgroundFilterBlur: false,
                            middle: Text(
                              "Photo",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color:
                                    CupertinoColors.label.resolveFrom(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // --- LAYER 3: DESKTOP NAVIGATION ---
                  if (isDesktop && _currentPage > 0)
                    _buildSideNav(isLeft: true, icon: CupertinoIcons.back),
                  if (isDesktop &&
                      _currentPage < (imageValue?.length ?? widget.count) - 1)
                    _buildSideNav(isLeft: false, icon: CupertinoIcons.forward),

                  // --- LAYER 4: BOTTOM PILL ACTION BAR ---
                  Positioned(
                    bottom: bottomInset > 0
                        ? bottomInset
                        : 30, // Adjust bottom spacing
                    left: 0,
                    right: 0,
                    child: Center(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _showControls ? 1.0 : 0.0,
                        curve: Curves.easeOutCubic,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 400),
                          scale: _showControls ? 1.0 : 0.7,
                          curve: Curves.easeOutBack,
                          child: AnimatedSlide(
                            duration: const Duration(milliseconds: 400),
                            offset: _showControls
                                ? Offset.zero
                                : const Offset(0, 0.5),
                            curve: Curves.easeOutBack,
                            child: _buildBottomPill(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
              from: CupertinoTheme.of(context)
                  .scaffoldBackgroundColor
                  .withAlpha(!kIsWeb && (Platform.isAndroid || Platform.isIOS)
                      ? 255
                      : 220),
              to: CupertinoTheme.of(context)
                  .scaffoldBackgroundColor
                  .withAlpha(0),
              curve: const Cubic(.05, .26, 1, .55),
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPill(BuildContext context) {
    return IgnorePointer(
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
              color: CupertinoColors.secondarySystemGroupedBackground
                  .resolveFrom(context)
                  .withAlpha(200),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: CupertinoColors.separator.resolveFrom(context),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _pillAction(CupertinoIcons.share, () {}),
                _pillAction(CupertinoIcons.square_favorites, () {}),
                _pillAction(CupertinoIcons.info, () {}),
                _pillAction(CupertinoIcons.delete, _handleDelete,
                    isDestructive: true),
              ],
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
                    color: CupertinoColors.secondarySystemGroupedBackground
                        .resolveFrom(context)
                        .withAlpha(200),
                    border: Border.all(
                      color: CupertinoColors.separator.resolveFrom(context),
                    ),
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
                    child: Icon(icon,
                        color: CupertinoColors.label.resolveFrom(context),
                        size: 22),
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
        color: isDestructive
            ? CupertinoColors.systemRed
            : CupertinoColors.activeBlue,
      ),
    );
  }
}
