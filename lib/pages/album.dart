import 'dart:ui';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:vault/utils/filename.dart';
import 'package:vault/widget/touchable.dart';
import 'package:image_picker/image_picker.dart';

import 'package:vault/utils/file_api_wrapper.dart' as fileapi;

class AlbumPage extends StatefulWidget {
  final String name;
  const AlbumPage({super.key, required this.name});

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> with fileapi.FileApiWrapper {
  // List<File> files = [];
  Map<String, String> files = {};
  String photoDirectoryPath = "";

  @override // stratup code
  void initState() {
    super.initState();
    getImages();
  }

  Future getImageFromGallery() async {
    WidgetsFlutterBinding.ensureInitialized();

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String directory = '${appDocDir.path}/Collections';

    final XFile? image =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (image == null) {
      debugPrint("No image selected");
      return;
    }

    final bytes = await File(image.path).readAsBytes();
    final Uint8List uint8list = Uint8List.fromList(bytes);

    saveFileWrapper(uint8list,
        '$directory/${widget.name}/${filename("${widget.name}.image", "$directory/${widget.name}", "_d", false)}');
    getImages();
  }

  void getImages() async {
    WidgetsFlutterBinding.ensureInitialized();

    Directory appDocDir = await getApplicationDocumentsDirectory();
    photoDirectoryPath = '${appDocDir.path}/Collections/${widget.name}';

    await getImagesWrapper(photoDirectoryPath).then((value) {
      setState(() {
        files = value;
      });
    });
  }

  Future<Widget> chainedAsyncOperations(index) async {
    String imagePath = "$photoDirectoryPath/${files.keys.toList()[index]}";
    final imageData = await (getFileThumbWrapper(imagePath));

    return Image.memory(
      Uint8List.fromList(imageData),
      // cacheWidth: 200,
      // cacheHeight: ((size.height / size.width) * 200).toInt(),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        debugPrint("Vault error: INFO: $error");
        return Container(
          color: const Color.fromARGB(255, 14, 14, 14),
          child: const Center(
            child: Text("Error"),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: TouchableOpacity(
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 25,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color.fromARGB(135, 0, 0, 0),
        forceMaterialTransparency: true,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            // filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            filter: ImageFilter.compose(
              outer: ImageFilter.blur(
                  sigmaY: 20, sigmaX: 20, tileMode: TileMode.decal),
              inner: ImageFilter.blur(
                  sigmaY: 20 + 20, sigmaX: 10 + 20, tileMode: TileMode.clamp),
            ),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        actions: <Widget>[
          TouchableOpacity(
            onPressed: () {
              getImageFromGallery();
              HapticFeedback.heavyImpact();
            },
            child: const Padding(
              padding:
                  EdgeInsets.only(right: 15, left: 10, top: 10, bottom: 10),
              child: Icon(
                Icons.add_circle_outline_rounded,
                size: 25,
              ),
            ),
          ),
        ],
      ),
      body: GridView.builder(
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
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  final String imageUrl =
                      Uri.encodeQueryComponent(photoDirectoryPath);
                  context.push("/photo/$imageUrl/$index/${files.length}");
                },
                child: Hero(
                  tag: index,
                  child: AspectRatio(
                    aspectRatio: 1 / 1,
                    child: FutureBuilder<Widget>(
                      future: chainedAsyncOperations(index),
                      builder: (context, snapshot) {
                        Widget child;
                        if (snapshot.hasData) {
                          child = SizedBox.expand(child: snapshot.data!);
                        } else {
                          child = BlurHash(hash: files.values.toList()[index]);
                        }
                        return AnimatedSwitcher(
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          duration: const Duration(milliseconds: 200),
                          child: child,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
