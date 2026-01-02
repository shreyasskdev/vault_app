import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show MaterialRectArcTween;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:progressive_blur/progressive_blur.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:smooth_gradient/smooth_gradient.dart';
import 'package:uuid/uuid.dart';
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

  Player? _activePlayer;

  bool _isInteracting = false; // NEW: Tracks if user is scrubbing

  List<Map<String, (String, double)>>? imageValue;
  final Map<int, Uint8List> _thumbnailCache = {};
  final Map<int, Uint8List> _fullImageCache = {};
  final Map<int, Player> _playerCache = {};

  bool _showControls = true;
  Timer? _controlsTimer;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.index;
    pageController = PageController(initialPage: widget.index);

    _animationController = AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: 800), // Slightly longer for "Linux" feel
    );
    _animationCurve = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutBack, // Very smooth deceleration
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
    for (var player in _playerCache.values) {
      player.dispose();
    }
    _playerCache.clear();
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

    // Show controls if they are hidden
    if (!_showControls) {
      _animationController.forward();
      setState(() => _showControls = true);
    }

    // Do NOT start the countdown if:
    // 1. User is scrubbing (_isInteracting)
    // 2. Video is paused
    _controlsTimer = Timer(const Duration(seconds: 5), () {
      // SLOWER: 5 seconds
      if (mounted && _showControls && !_isInteracting) {
        // Only hide if video is playing. If paused, keep controls visible.
        final isPlaying = _activePlayer?.state.playing ?? false;
        if (isPlaying) {
          _animationController.reverse();
          setState(() => _showControls = false);
        }
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
    // setState(() => _currentPage = index);
    setState(() {
      _currentPage = index;

      // 2. Look up if we already have a player for this page in our cache
      _activePlayer = _playerCache[index];

      // If we found a player, ensure controls show up
      if (_activePlayer != null) {
        _showControls = true;
        _animationController.forward();
        _resetControlsTimer();
      } else {
        // No player yet (might be an image or still loading)
        _activePlayer = null;
      }
    });
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
    // 1. Determine if this index is a video or image
    final String fileName = (imageValue != null && index < imageValue!.length)
        ? imageValue![index].keys.first
        : "";
    final bool isVideo = fileName.toLowerCase().endsWith('.video');

    final fullBytes = _fullImageCache[index];
    final thumbnailBytes = _thumbnailCache[index];

    // --- Case A: Full Data is Loaded ---
    if (fullBytes != null) {
      if (isVideo) {
        return VaultVideoPlayer(
          key: ValueKey("video_$index"),
          videoBytes: fullBytes,
          onCreated: (player) {
            // 3. Always store the player in the cache
            _playerCache[index] = player;

            // 4. Only update the UI if this is the page the user is actually looking at
            if (_currentPage == index) {
              setState(() {
                _activePlayer = player;
                _showControls = true;
              });
              _animationController.forward();
              _resetControlsTimer();
            }
          },
        );
      } else {
        // Return existing Image logic for .image files
        return FutureBuilder<Image>(
          key: ValueKey(fullBytes),
          future: compute(_decodeImage, fullBytes),
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

                  // LAYER 1.5: FIXED VIDEO CONTROLS
                  if (_activePlayer != null)
                    Positioned(
                      bottom: 100,
                      left: 0,
                      right: 0,
                      child: VideoControlPill(
                        player: _activePlayer!,
                        visibility: _animationCurve,
                        key: ValueKey(_activePlayer
                            .hashCode), // Forces a refresh for each new player
                        onInteractionStart: () {
                          setState(() => _isInteracting = true);
                          _controlsTimer?.cancel(); // Stop timer immediately
                        },
                        onInteractionEnd: () {
                          setState(() => _isInteracting = false);
                          _resetControlsTimer(); // Restart timer
                        },
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

class VaultVideoPlayer extends StatefulWidget {
  final Uint8List videoBytes;
  final void Function(Player player) onCreated;

  const VaultVideoPlayer({
    super.key,
    required this.videoBytes,
    required this.onCreated,
  });

  @override
  State<VaultVideoPlayer> createState() => _VaultVideoPlayerState();
}

// Add SingleTickerProviderStateMixin for the heartbeat ticker
class _VaultVideoPlayerState extends State<VaultVideoPlayer>
    with SingleTickerProviderStateMixin {
  late final Player _player = Player();
  late final VideoController _controller = VideoController(_player);

  Ticker? _ticker;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();

    // --- THE VIDEO SURFACE TICKER ---
    // Forces the video widget to rebuild every frame during playback.
    // This is required on some Linux/Desktop backends to prevent the
    // video surface from freezing when the UI is static.
    _ticker = createTicker((_) {
      if (mounted && _initialized && _player.state.playing) {
        setState(() {});
      }
    })
      ..start();
  }

  Future<void> _initPlayer() async {
    await _player.setPlaylistMode(PlaylistMode.none);
    final playable = await Media.memory(widget.videoBytes);
    await _player.open(playable, play: true);

    widget.onCreated(_player);

    if (mounted) setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _ticker?.dispose(); // Clean up ticker
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Video(
        controller: _controller,
        controls: NoVideoControls,
      ),
    );
  }
}

class VideoControlPill extends StatefulWidget {
  final Player player;
  final Animation<double> visibility;
  final VoidCallback onInteractionStart;
  final VoidCallback onInteractionEnd;

  const VideoControlPill({
    super.key,
    required this.player,
    required this.visibility,
    required this.onInteractionStart,
    required this.onInteractionEnd,
  });

  @override
  State<VideoControlPill> createState() => _VideoControlPillState();
}

class _VideoControlPillState extends State<VideoControlPill>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      if (widget.player.state.playing) setState(() {});
    })
      ..start();

    widget.player.stream.completed.listen((completed) {
      if (completed) {
        widget.player.pause();
        widget.player.seek(Duration.zero);
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final position = widget.player.state.position;
    final duration = widget.player.state.duration;
    final bool isMuted = widget.player.state.volume == 0;
    final double targetProgress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return FadeTransition(
      opacity: widget.visibility,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1.0).animate(widget.visibility),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            behavior: HitTestBehavior.opaque,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  constraints: const BoxConstraints(maxWidth: 550),
                  height: 50, // 1. FIXED HEIGHT: Keeps the pill consistent
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4), // Reduced horizontal padding
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: CupertinoColors.secondarySystemGroupedBackground
                        .resolveFrom(context)
                        .withAlpha(140),
                    border: Border.all(
                        color: CupertinoColors.separator.resolveFrom(context),
                        width: 0.5),
                  ),
                  child: Row(
                    children: [
                      _buildPlayPause(),
                      _buildProgressBar(targetProgress),
                      _buildMute(isMuted),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayPause() {
    return GestureDetector(
      onTap: () {
        widget.player.playOrPause();
        widget.onInteractionEnd();
        setState(() {});
      },
      onTapDown: (_) => widget.onInteractionStart(),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 50, // 2. SQUARE TARGET: 50x50 touch area
        height: 50,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              widget.player.state.playing
                  ? CupertinoIcons.pause_fill
                  : CupertinoIcons.play_fill,
              color: CupertinoColors.label.resolveFrom(context),
              size: 22,
              key: ValueKey(widget.player.state.playing),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (_) => widget.onInteractionStart(),
            onHorizontalDragUpdate: (details) =>
                _handleScrub(details, constraints.maxWidth),
            onHorizontalDragEnd: (_) => widget.onInteractionEnd(),
            onTapDown: (details) {
              widget.onInteractionStart();
              _handleScrub(details, constraints.maxWidth);
            },
            onTapUp: (_) => widget.onInteractionEnd(),
            child: Container(
              height: 50,
              alignment: Alignment.center,
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: CupertinoColors.label
                            .resolveFrom(context)
                            .withAlpha(30),
                      ),
                    ),
                  ),
                  Align(
                    alignment: AlignmentGeometry.centerLeft,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return FractionallySizedBox(
                          widthFactor: value,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: CupertinoColors.label.resolveFrom(context),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMute(bool isMuted) {
    return GestureDetector(
      onTap: () {
        widget.player.setVolume(isMuted ? 100 : 0);
        widget.onInteractionEnd();
        setState(() {});
      },
      onTapDown: (_) => widget.onInteractionStart(),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 50, // 3. SQUARE TARGET: Matching the play button
        height: 50,
        child: Center(
          child: Icon(
            isMuted
                ? CupertinoIcons.speaker_slash_fill
                : CupertinoIcons.speaker_2_fill,
            color: CupertinoColors.label.resolveFrom(context),
            size: 20,
          ),
        ),
      ),
    );
  }

  void _handleScrub(dynamic details, double maxWidth) {
    final double percentage =
        (details.localPosition.dx / maxWidth).clamp(0.0, 1.0);
    widget.player.seek(Duration(
        milliseconds: (widget.player.state.duration.inMilliseconds * percentage)
            .toInt()));
    setState(() {});
  }
}
