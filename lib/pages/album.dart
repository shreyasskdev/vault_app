import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show MaterialRectArcTween;
import 'package:flutter/services.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart'; // Added package
import 'package:path_provider/path_provider.dart';
import 'package:progressive_blur/progressive_blur.dart';
import 'package:smooth_gradient/smooth_gradient.dart';
import 'package:vault/providers.dart';
import 'package:vault/utils/file_api_wrapper.dart' as fileapi;

import 'photo.dart';

class AlbumPage extends ConsumerStatefulWidget {
  final String name;
  const AlbumPage({super.key, required this.name});

  @override
  ConsumerState<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends ConsumerState<AlbumPage>
    with fileapi.FileApiWrapper, SingleTickerProviderStateMixin {
  List<Map<String, (String, double)>> files = [];
  String photoDirectoryPath = "";

  // Selection Mode State
  bool _isSelectionMode = false;
  final Set<int> _selectedIndices = {};

  // Animation for the Bottom Pill
  late AnimationController _pillController;
  late Animation<double> _pillAnimation;

  late final ScrollController _scrollController;
  bool _isGradientVisible = false;

  final Map<int, Uint8List> _thumbnailCache = {};
  bool _isThumbnailLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    // Initialize Pill Animation
    _pillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pillAnimation = CurvedAnimation(
      parent: _pillController,
      curve: Curves.fastEaseInToSlowEaseOut,
    );

    _initializeAndLoadFiles();
  }

  void _scrollListener() {
    final bool shouldBeVisible = _scrollController.offset > 0;
    if (shouldBeVisible != _isGradientVisible) {
      setState(() {
        _isGradientVisible = shouldBeVisible;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _pillController.dispose();
    super.dispose();
  }

  void _initializeAndLoadFiles() async {
    WidgetsFlutterBinding.ensureInitialized();

    Directory appDocDir = await getApplicationDocumentsDirectory();
    photoDirectoryPath = '${appDocDir.path}/Collections/${widget.name}';

    final imageList = await getImagesWrapper(photoDirectoryPath);
    if (mounted) {
      setState(() {
        files = sortMapToList(imageList);
      });
      _loadAllThumbnails();
    }
  }

  Future<void> _loadAllThumbnails() async {
    if (_isThumbnailLoading || files.isEmpty) return;
    _isThumbnailLoading = true;

    final List<Future<void>> thumbnailFutures = [];
    for (int i = 0; i < files.length; i++) {
      if (!_thumbnailCache.containsKey(i)) {
        thumbnailFutures.add(_loadThumbnailAtIndex(i));
      }
    }

    await Future.wait(thumbnailFutures);

    if (mounted) {
      setState(() {
        _isThumbnailLoading = false;
      });
    }
  }

  Future<void> _loadThumbnailAtIndex(int index) async {
    if (_thumbnailCache.containsKey(index) || files.isEmpty) return;

    try {
      final imagePath = "$photoDirectoryPath/${files[index].keys.first}";
      final imageData = await getFileThumbWrapper(imagePath, ref);

      if (mounted && !_thumbnailCache.containsKey(index)) {
        setState(() {
          _thumbnailCache[index] = Uint8List.fromList(imageData);
        });
      }
    } catch (e) {
      debugPrint("Error loading thumbnail for index $index: $e");
    }
  }

  Future getImageFromGallery() async {
    WidgetsFlutterBinding.ensureInitialized();
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String directory = '${appDocDir.path}/Collections';

    final List<XFile> images = await ImagePicker().pickMultipleMedia();

    if (images.isEmpty) return;

    await Future.forEach(images, (image) async {
      try {
        final bytes = await image.readAsBytes();
        final Uint8List uint8list = Uint8List.fromList(bytes);
        await saveImageWrapper(uint8list, '$directory/${widget.name}');
      } catch (e) {
        debugPrint("Error processing image: $e");
      }
    });

    _initializeAndLoadFiles();
  }

  // --- SELECTION LOGIC ---

  void _toggleSelectionMode(int index) {
    setState(() {
      _isSelectionMode = true;
      _selectedIndices.add(index);
    });
    _pillController.forward();
    HapticFeedback.mediumImpact();
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
        if (_selectedIndices.isEmpty) {
          _isSelectionMode = false;
          _pillController.reverse();
        }
      } else {
        _selectedIndices.add(index);
      }
    });
    HapticFeedback.lightImpact();
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIndices.clear();
    });
    _pillController.reverse();
  }

  Future<void> _deleteSelectedPhotos() async {
    final bool? confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text("Delete ${_selectedIndices.length} items?"),
        content: const Text("This action cannot be undone."),
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

    if (confirm != true) return;

    final sortedIndices = _selectedIndices.toList()
      ..sort((a, b) => b.compareTo(a));

    await Future.wait(sortedIndices.map((index) async {
      if (index < files.length) {
        final fileName = files[index].keys.first;
        final filePath = "$photoDirectoryPath/$fileName";
        await deleteFileWrapper(filePath);
      }
    }));

    _exitSelectionMode();
    _initializeAndLoadFiles();
  }

  // --- MOVE LOGIC ---

  Future<void> _showMoveModal(BuildContext innerContext) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    final String collectionsPath = '${appDocDir.path}/Collections';
    final List<String> albums = await getDirsWrapper(collectionsPath);

    albums.removeWhere((name) => name == widget.name);

    if (!mounted) return;

    // Use CupertinoScaffold for the "scale background" effect
    CupertinoScaffold.showCupertinoModalBottomSheet(
      context: innerContext,
      expand: false,
      // backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      // topRadius: const Radius.circular(12),
      builder: (context) => CupertinoPageScaffold(
        // backgroundColor:
        //     CupertinoColors.systemGroupedBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grabber Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey3.resolveFrom(context),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),

              Text(
                'Move ${_selectedIndices.length} Items',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),

              Flexible(
                child: SingleChildScrollView(
                  controller: ModalScrollController.of(context),
                  child: CupertinoListSection.insetGrouped(
                    header: const Text('CHOOSE ALBUM'),
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: albums.isNotEmpty
                        ? albums.map((albumName) {
                            return CupertinoListTile(
                              title: Text(albumName),
                              leading: Icon(
                                CupertinoIcons.folder,
                                color: CupertinoTheme.of(context).primaryColor,
                              ),
                              trailing: const Icon(
                                CupertinoIcons.chevron_forward,
                                size: 14,
                                color: CupertinoColors.systemGrey2,
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _moveSelectedPhotos(albumName);
                              },
                            );
                          }).toList()
                        : [
                            const CupertinoListTile(
                              title: Text(
                                "No other albums found",
                                style: TextStyle(
                                    color: CupertinoColors.secondaryLabel),
                              ),
                            )
                          ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: CupertinoButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _moveSelectedPhotos(String destinationAlbum) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    final String destPath = '${appDocDir.path}/Collections/$destinationAlbum';

    for (int index in _selectedIndices) {
      final fileName = files[index].keys.first;
      final sourceFile = File("$photoDirectoryPath/$fileName");
      final destinationFile = File("$destPath/$fileName");

      try {
        if (await sourceFile.exists()) {
          await sourceFile.rename(destinationFile.path);
        }
      } catch (e) {
        debugPrint("Error moving file: $e");
      }
    }

    _exitSelectionMode();
    _initializeAndLoadFiles();
  }

  // --- UI COMPONENTS ---

  Widget _buildSelectionPill(BuildContext innerContext) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _pillAnimation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(_pillAnimation),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  height: 65,
                  width: MediaQuery.of(context).size.width * 0.85,
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
                      _pillAction(
                        CupertinoIcons.folder_badge_plus,
                        "Move",
                        () => _showMoveModal(innerContext),
                      ),
                      _pillAction(
                        CupertinoIcons.delete,
                        "Delete",
                        _deleteSelectedPhotos,
                        isDestructive: true,
                      ),
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

  Widget _pillAction(IconData icon, String label, VoidCallback onTap,
      {bool isDestructive = false}) {
    final Color color =
        isDestructive ? CupertinoColors.systemRed : CupertinoColors.activeBlue;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = CupertinoTheme.of(context);
    return CupertinoScaffold(
      topRadius: const Radius.circular(12),
      body: Builder(builder: (innerContext) {
        final topPadding = MediaQuery.of(innerContext).padding.top +
            kMinInteractiveDimensionCupertino;

        final Widget gridView = GridView.builder(
          controller: _scrollController,
          padding: EdgeInsets.only(
            top: topPadding + 14,
            left: 0,
            right: 0,
            bottom: 100,
          ),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 160,
            childAspectRatio: 1 / 1,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: files.length,
          itemBuilder: (BuildContext context, int index) {
            final isSelected = _selectedIndices.contains(index);
            final thumbnailData = _thumbnailCache[index];

            return RepaintBoundary(
              child: GestureDetector(
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleSelection(index);
                  } else {
                    final String imageUrl =
                        Uri.encodeQueryComponent(photoDirectoryPath);
                    Navigator.of(context)
                        .push(
                          CupertinoPageRoute(
                            builder: (context) => PhotoView(
                              url: Uri.decodeQueryComponent(imageUrl),
                              index: index,
                              count: files.length,
                              initialThumbnail: thumbnailData,
                            ),
                          ),
                        )
                        .then((t) => {_initializeAndLoadFiles()});
                  }
                },
                onLongPress: () {
                  if (!_isSelectionMode) _toggleSelectionMode(index);
                },
                child: Hero(
                  tag: index,
                  createRectTween: (begin, end) =>
                      MaterialRectArcTween(begin: begin, end: end),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (thumbnailData != null)
                          Image.memory(thumbnailData,
                              gaplessPlayback: true, fit: BoxFit.cover)
                        else
                          BlurHash(hash: files[index].values.first.$1),
                        if (_isSelectionMode)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? CupertinoTheme.of(context).primaryColor
                                    : CupertinoColors.secondaryLabel
                                        .resolveFrom(context),
                                border: Border.all(
                                  color: isSelected
                                      ? CupertinoTheme.of(context).primaryColor
                                      : CupertinoColors.systemFill
                                          .resolveFrom(context),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Icon(CupertinoIcons.check_mark,
                                      size: 16,
                                      color: CupertinoTheme.of(context)
                                          .scaffoldBackgroundColor)
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );

        return CupertinoTheme(
          data: themeData,
          child: CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              backgroundColor: CupertinoTheme.of(context)
                  .scaffoldBackgroundColor
                  .withAlpha(0),
              border: null,
              enableBackgroundFilterBlur: false,
              leading: _isSelectionMode
                  ? CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _exitSelectionMode,
                      child: const Icon(CupertinoIcons.xmark, size: 22),
                    )
                  : CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(innerContext).pop(),
                      child: const Icon(CupertinoIcons.back, size: 28),
                    ),
              middle: _isSelectionMode
                  ? Text("${_selectedIndices.length} selected")
                  : Text(widget.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: !_isSelectionMode
                  ? CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        getImageFromGallery();
                        HapticFeedback.heavyImpact();
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(CupertinoIcons.add_circled, size: 26),
                      ),
                    )
                  : null,
            ),
            child: Stack(
              children: [
                ref.watch(settingsModelProvider).advancedTextures
                    ? ProgressiveBlurWidget(
                        linearGradientBlur: const LinearGradientBlur(
                          values: [1, 0],
                          stops: [0, 0.2],
                          start: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        sigma: _isGradientVisible ? 24.0 : 0,
                        blurTextureDimensions: 128,
                        child: gridView)
                    : gridView,
                IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _isGradientVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.fastEaseInToSlowEaseOut,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: SmoothGradient(
                          from: CupertinoTheme.of(context)
                              .scaffoldBackgroundColor
                              .withAlpha(!kIsWeb &&
                                      (Platform.isAndroid || Platform.isIOS)
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
                ),
                if (_isSelectionMode || !_pillAnimation.isDismissed)
                  _buildSelectionPill(innerContext),
              ],
            ),
          ),
        );
      }),
    );
  }
}
