import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_io.dart';
import 'package:vault/providers.dart';
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

// class _PhotoViewState extends ConsumerState<PhotoView>
//     with fileapi.FileApiWrapper {
//   late final PageController pageController;

//   List<Map<String, (String, double)>>? imageValue;
//   Uint8List? finalImage;
//   Uint8List? thumbImage;

//   @override
//   void initState() {
//     super.initState();
//     // getImages();
//     pageController = PageController(initialPage: widget.index);
//     thumbLoad(widget.index).then((_) => {chainedAsyncOperations(widget.index)});
//   }

//   Future<int> thumbLoad(index) async {
//     // await getFileThumbWrapper(
//     //         "${widget.url}/${imageValue?[index].keys.toList().first}", ref)
//     //     .then((value) {
//     //   thumbImage ??= value;
//     // });
//     await getImagesWrapper(widget.url).then((value) {
//       imageValue ??= sortMapToList(value);
//     });

//     setState(() {
//       thumbImage = ref.read(ImageCacheProvider).cachedThumbImage[
//           "${widget.url}/${imageValue?[index].keys.toList().first}"];
//     });
//     return 1;
//   }

//   void chainedAsyncOperations(index) async {
//     // await getFileThumbWrapper(
//     //         "${widget.url}/${imageValue?[index].keys.toList().first}", ref)
//     //     .then((value) {
//     //   thumbImage ??= value;
//     // });
//     // await getImagesWrapper(widget.url).then((value) {
//     //   imageValue ??= sortMapToList(value);
//     // });

//     Uint8List imageData = await getFileWrapper(
//         "${widget.url}/${imageValue?[index].keys.toList().first}", ref);
//     setState(() {
//       finalImage = imageData;
//       thumbImage = null;
//     });
//     // return Image.memory(
//     //   Uint8List.fromList(imageData),
//     //   fit: BoxFit.contain,
//     //   width: double.infinity,
//     //   errorBuilder: (context, error, stackTrace) {
//     //     debugPrint("Vault error: INFO: $error");
//     //     return const Center(
//     //       child: CircularProgressIndicator(),
//     //     );
//     //   },
//     // );
//   }

//   // Widget _buildImagePage() {
//   //   return PhotoViewGallery.builder(
//   //     // gaplessPlayback: true,
//   //     scrollPhysics: (Platform.isFuchsia ||
//   //             Platform.isLinux ||
//   //             Platform.isWindows ||
//   //             Platform.isMacOS)
//   //         ? const ScrollPhysics()
//   //         : const BouncingScrollPhysics(),
//   //     gaplessPlayback: true,

//   //     builder: (BuildContext context, int index) {
//   //       return PhotoViewGalleryPageOptions.customChild(
//   //         // child: FutureBuilder<Widget>(
//   //         //   // initialData: Image.memory(
//   //         //   //   ref.read(ImageCacheProvider).cachedThumbImage[
//   //         //   //       "${widget.url}/${imageValue?[index].keys.toList().first}"]!,
//   //         //   // ),
//   //         //   initialData: Container(
//   //         //       color: const Color.fromARGB(255, 255, 0, 0),
//   //         //       child: const CircularProgressIndicator()),
//   //         //   future: chainedAsyncOperations(index),
//   //         //   builder: (context, snapshot) {
//   //         //     print(context);
//   //         //     // if (snapshot.hasData) {
//   //         //     return snapshot.data!;
//   //         //     // }
//   //         //     // return snapshot.requireData;
//   //         //   },
//   //         // ),
//   //         child: Image.memory(
//   //           // (ref.read(ImageCacheProvider).cachedThumbImage[
//   //           //         "${widget.url}/${imageValue?[index].keys.toList().first}"] ??
//   //           //     finalImage)!,
//   //           (thumbImage ?? finalImage)!,
//   //           fit: BoxFit.contain,
//   //           // finalImage!,
//   //           gaplessPlayback: true,
//   //         ),
//   //         initialScale: PhotoViewComputedScale.contained,
//   //         minScale: PhotoViewComputedScale.contained,
//   //         heroAttributes: PhotoViewHeroAttributes(tag: index),
//   //       );
//   //     },
//   //     itemCount: widget.count,

//   //     // loadingBuilder: (context, event) => Center(
//   //     //   child: Container(
//   //     //     width: 20.0,
//   //     //     height: 20.0,
//   //     //     color: const Color.fromARGB(255, 255, 0, 0),
//   //     //     child: const CircularProgressIndicator(),
//   //     //   ),
//   //     // ),
//   //     // backgroundDecoration: widget.backgroundDecoration,
//   //     pageController: pageController,
//   //     // pageController: PageController(initialPage: 5),
//   //     // onPageChanged: onPageChanged,
//   //   );
//   // }

//   Widget _buildImagePage() {
//     return Hero(
//       tag: widget.index,
//       child: PhotoViewGallery.builder(
//         itemCount: widget.count,
//         pageController: pageController,
//         gaplessPlayback: true,
//         loadingBuilder: (context, event) => Center(
//           // child: Container(
//           //   width: 20.0,
//           //   height: 20.0,
//           //   color: const Color.fromARGB(255, 255, 0, 0),
//           //   child: const CircularProgressIndicator(),
//           // ),
//           child: Image.memory(thumbImage!),
//         ),
//         builder: (BuildContext context, int index) {
//           return PhotoViewGalleryPageOptions(
//             imageProvider: Image.memory(
//               // (ref.read(ImageCacheProvider).cachedThumbImage[
//               //         "${widget.url}/${imageValue?[index].keys.toList().first}"] ??
//               //     finalImage)!,
//               (thumbImage ?? finalImage)!,
//               // finalImage!,
//               gaplessPlayback: true,
//             ).image,
//             initialScale: PhotoViewComputedScale.contained,
//             minScale: PhotoViewComputedScale.contained,
//             // heroAttributes: PhotoViewHeroAttributes(tag: index),
//           );
//         },
//       ),
//     );
//   }
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
    thumbLoad(widget.index).then((_) => chainedAsyncOperations(widget.index));
  }

  Future<int> thumbLoad(index) async {
    await getImagesWrapper(widget.url).then((value) {
      imageValue ??= sortMapToList(value);
    });

    setState(() {
      thumbImage = ref.read(ImageCacheProvider).cachedThumbImage[
          "${widget.url}/${imageValue?[index].keys.toList().first}"];
    });
    return 1;
  }

  void chainedAsyncOperations(index) async {
    Uint8List imageData = await getFileWrapper(
        "${widget.url}/${imageValue?[index].keys.toList().first}", ref);
    setState(() {
      finalImage = imageData;
      thumbImage = null;
    });
  }

  Widget _buildImagePage() {
    return Hero(
      tag: widget.index,
      child: PhotoViewGallery.builder(
        itemCount: widget.count,
        pageController: pageController,
        gaplessPlayback: true,
        onPageChanged: (index) {
          thumbLoad(index).then((_) => chainedAsyncOperations(index));
        },
        // loadingBuilder: (context, event) => Center(
        //   child: thumbImage != null
        //       ? Image.memory(thumbImage!)
        //       : const CircularProgressIndicator(),
        // ),
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: Image.memory(
              (thumbImage ?? finalImage)!,
              gaplessPlayback: true,
            ).image,
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
          );
        },
      ),
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
        // PhotoViewGallery.builder(
        //   gaplessPlayback: true,
        //   scrollPhysics: (Platform.isFuchsia ||
        //           Platform.isLinux ||
        //           Platform.isWindows ||
        //           Platform.isMacOS)
        //       ? const ScrollPhysics()
        //       : const BouncingScrollPhysics(),

        //   builder: (BuildContext context, int index) {
        //     return PhotoViewGalleryPageOptions.customChild(
        //       child: FutureBuilder<Widget>(
        //         future: chainedAsyncOperations(index),
        //         builder: (context, snapshot) {
        //           Widget child;
        //           print("object");
        //           if (snapshot.hasData) {
        //             child = snapshot.data!;
        //           } else {z
        //             child = Stack(
        //               children: [
        //                 imageValue == null
        //                     ? const SizedBox()
        //                     : Center(
        //                         child: AspectRatio(
        //                           aspectRatio: imageValue![index]
        //                               .values
        //                               .toList()
        //                               .last
        //                               .$2,
        //                           child: BlurHash(
        //                               hash: imageValue![index]
        //                                   .values
        //                                   .toList()
        //                                   .last
        //                                   .$1),
        //                         ),
        //                       ),
        //                 const Center(
        //                     child: CircularProgressIndicator(
        //                   color: Color.fromARGB(50, 255, 255, 255),
        //                 )),
        //               ],
        //             );
        //           }

        //           return Center(
        //             child: AnimatedSwitcher(
        //               transitionBuilder:
        //                   (Widget child, Animation<double> animation) {
        //                 return FadeTransition(
        //                   opacity: animation,
        //                   child: child,
        //                 );
        //               },
        //               duration: const Duration(milliseconds: 200),
        //               child: child,
        //             ),
        //           );
        //         },
        //       ),
        //       initialScale: PhotoViewComputedScale.contained,
        //       minScale: PhotoViewComputedScale.contained,
        //       heroAttributes: PhotoViewHeroAttributes(tag: index),
        //     );
        //   },
        //   itemCount: widget.count,

        //   loadingBuilder: (context, event) => Center(
        //     child: Container(
        //       width: 20.0,
        //       height: 20.0,
        //       color: const Color.fromARGB(255, 14, 14, 14),
        //       child: const CircularProgressIndicator(),
        //     ),
        //   ),
        //   // backgroundDecoration: widget.backgroundDecoration,
        //   pageController: pageController,
        //   // pageController: PageController(initialPage: 5),
        //   // onPageChanged: onPageChanged,
        // ),
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
