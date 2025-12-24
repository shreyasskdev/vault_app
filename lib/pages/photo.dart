import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    show MaterialRectArcTween; // Added Colors
import 'package:flutter/services.dart';
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

// Added SingleTickerProviderStateMixin for the AnimationController
class _PhotoViewState extends ConsumerState<PhotoView>
    with fileapi.FileApiWrapper, SingleTickerProviderStateMixin {
  late final PageController pageController;

  // Animation Controller for unified, smooth transitions
  late final AnimationController _animationController;
  late final Animation<double> _animationCurve;

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

    // Initialize the explicit animation controller
    _animationController = AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: 500), // Slightly longer for "Linux" feel
    );
    _animationCurve = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack, // Very smooth deceleration
    );
    _animationController.value = 1.0; // Start in the 'shown' state

    if (widget.initialThumbnail != null) {
      _thumbnailCache[widget.index] = widget.initialThumbnail!;
    }

    _loadImageList();
    _resetControlsTimer();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _animationController.dispose(); // Dispose the controller
    pageController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    _controlsTimer?.cancel();
    if (_showControls) {
      _animationController.reverse();
      _showControls = false;
    } else {
      _animationController.forward();
      _showControls = true;
      _resetControlsTimer();
    }
    setState(
        () {}); // Still needed to trigger visibility logic for IgnorePointer
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    if (!mounted) return;
    if (!_showControls) {
      _animationController.forward();
      setState(() => _showControls = true);
    }
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showControls) {
        _animationController.reverse();
        setState(() => _showControls = false);
      }
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
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final useAdvancedTextures =
        ref.watch(settingsModelProvider).advancedTextures;

    final Widget gallery = PhotoViewGallery.builder(
      scrollPhysics: const BouncingScrollPhysics(),
      gaplessPlayback: true,
      onPageChanged: _onPageChanged,
      backgroundDecoration: BoxDecoration(
        color: CupertinoTheme.of(context).scaffoldBackgroundColor,
      ),
      builder: (context, index) => PhotoViewGalleryPageOptions.customChild(
        child: _buildImageLoader(index),
        initialScale: PhotoViewComputedScale.contained,
        minScale: PhotoViewComputedScale.contained * 0.8,
        maxScale: PhotoViewComputedScale.contained * 3.0,
        heroAttributes: PhotoViewHeroAttributes(
          tag: index,
          createRectTween: (begin, end) {
            return MaterialRectArcTween(begin: begin, end: end);
          },
        ),
        onTapUp: (_, __, ___) => _toggleControls(),
      ),
      itemCount: imageValue?.length ?? widget.count,
      pageController: pageController,
    );

    return CupertinoPageScaffold(
      backgroundColor:
          CupertinoTheme.of(context).scaffoldBackgroundColor.withAlpha(0),
      resizeToAvoidBottomInset: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: MouseRegion(
          onHover: (_) => _resetControlsTimer(),
          child: GestureDetector(
            onTap: _toggleControls,
            child: SizedBox.expand(
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
                          ? AnimatedBuilder(
                              animation: _animationCurve,
                              builder: (context, child) =>
                                  ProgressiveBlurWidget(
                                linearGradientBlur: const LinearGradientBlur(
                                  values: [1, 0],
                                  stops: [0, 0.25],
                                  start: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                sigma: _animationCurve.value *
                                    24.0, // Blur linked to explicit animation
                                child: child!,
                              ),
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
                    child: FadeTransition(
                      opacity: _animationCurve,
                      child: IgnorePointer(
                        ignoring: !_showControls,
                        child: SafeArea(
                          bottom: false,
                          child: CupertinoNavigationBar(
                            backgroundColor: CupertinoTheme.of(context)
                                .scaffoldBackgroundColor
                                .withAlpha(0),
                            border: null,
                            enableBackgroundFilterBlur: false,
                            padding: EdgeInsetsDirectional.zero,
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
                  if (isDesktop) ...[
                    if (_currentPage > 0)
                      _buildSideNav(isLeft: true, icon: CupertinoIcons.back),
                    if (_currentPage < (imageValue?.length ?? widget.count) - 1)
                      _buildSideNav(
                          isLeft: false, icon: CupertinoIcons.forward),
                  ],

                  // --- LAYER 4: BOTTOM PILL ACTION BAR ---
                  Positioned(
                    bottom: bottomInset > 0
                        ? bottomInset
                        : 20, // Stabilized bottom padding
                    left: 0,
                    right: 0,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _animationCurve,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _animationCurve,
                            child: Transform.translate(
                              // Precise slide: 40 pixels down when hidden
                              offset:
                                  Offset(0, 40 * (1.0 - _animationCurve.value)),
                              child: Transform.scale(
                                // Precise scale: 0.85 when hidden
                                scale: 0.85 + (0.15 * _animationCurve.value),
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: _buildBottomPill(context),
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
    return FadeTransition(
      opacity: _animationCurve,
      child: IgnorePointer(
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
      child: FadeTransition(
        opacity: _animationCurve,
        child: Center(
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
