import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:vault/utils/filename.dart';
import 'package:vault/widget/touchable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vault/src/rust/api/file.dart' as api;

class AlbumPage extends StatefulWidget {
  final String name;
  const AlbumPage({super.key, required this.name});

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  // List<File> files = [];
  List<String> files = [];
  String photoDirectoryPath = "";

  @override // stratup code
  void initState() {
    super.initState();
    getImages();
  }

  Future getImageFromGallery() async {
    WidgetsFlutterBinding.ensureInitialized();

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String directory = '${appDocDir.path}/Collectons';

    final XFile? image =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (image == null) return;

    // await File(image.path).copy(
    //   '$directory/${widget.name}/${filename("${widget.name}.image", "$directory/${widget.name}", "_d", false)}',
    // );

    final bytes = await File(image.path).readAsBytes();
    final Uint8List uint8list = Uint8List.fromList(bytes);
    await api.saveFile(
      imageData: uint8list,
      filePath:
          '$directory/${widget.name}/${filename("${widget.name}.image", "$directory/${widget.name}", "_d", false)}',
    );

    getImages();
  }

  void getImages() async {
    WidgetsFlutterBinding.ensureInitialized();

    Directory appDocDir = await getApplicationDocumentsDirectory();
    photoDirectoryPath = '${appDocDir.path}/Collectons/${widget.name}';

    // try {
    //   List<FileSystemEntity> entities =
    //       Directory(photoDirectoryPath).listSync();

    //   setState(() {
    //     files = entities.whereType<File>().toList();
    //   });
    // } catch (e) {
    //   print('Error: $e');
    // }

    // await api.getImages(dir: photoDirectoryPath).then((files) {
    //   setState(() {
    //     this.files = files;
    //   });
    // });

    setState(() {
      files = api.getImages(dir: photoDirectoryPath);
    });
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
                  String imageUrl =
                      Uri.encodeQueryComponent(photoDirectoryPath);
                  context.push("/photo/$imageUrl/$index");
                },
                child: Hero(
                  tag: index,
                  child: AspectRatio(
                    aspectRatio: 1 / 1,
                    // child: Image.file(
                    //   File("$photoDirectoryPath/${files[index]}"),
                    //   fit: BoxFit.cover,
                    //   errorBuilder: (context, error, stackTrace) {
                    //     debugPrint("Wallet_Error: $error");
                    //     return const Center(
                    //       child: Text("error"),
                    //     );
                    //   },
                    // ),
                    child: Image.memory(
                      Uint8List.fromList(api.getFile(
                          path: "$photoDirectoryPath/${files[index]}")),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint("Wallet_Error: $error");
                        return const Center(
                          child: Text("error"),
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
