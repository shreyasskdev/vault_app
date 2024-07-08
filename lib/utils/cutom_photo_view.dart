import 'package:flutter/material.dart';
import 'package:Vault/widget/touchable.dart';
import 'dart:io';

class PhotoView extends StatefulWidget {
  final String url;
  final int index;
  const PhotoView({super.key, required this.url, required this.index});

  @override
  State<PhotoView> createState() => _PhotoViewState();
}

class _PhotoViewState extends State<PhotoView> {
  List<FileSystemEntity> files = [];
  // String photoDirectoryPath = "";
  PageController pageController = PageController();

  @override
  void initState() {
    super.initState();
    getImages();
    pageController = PageController(initialPage: widget.index);
  }

  void getImages() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Directory appDocDir = await getApplicationDocumentsDirectory();
    // photoDirectoryPath = '${appDocDir.path}/Collectons/${widget.name}';

    try {
      // Get a list of all entities (files and directories) in the app directory
      List<FileSystemEntity> entities = Directory(widget.url).listSync();

      setState(() {
        files = entities.whereType<File>().toList();
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
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
        title: const Text("Photo"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        forceMaterialTransparency: true,
      ),
      body: Stack(
        children: [
          PageView.builder(
            // onPageChanged: (page) => {
            //   setState(() {
            //     activePage =page;
            //   });
            // },

            controller: pageController,
            pageSnapping: true,
            physics: const ClampingScrollPhysics(),
            itemCount: files.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Center(
                  child: Hero(
                    tag: widget.url,
                    child: Image.file(
                      File(files[index].path),
                      fit: BoxFit.contain,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        print("Wallet_Error: $error");
                        return const Center(
                          child: Text("error"),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
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
        ],
      ),
    );
  }
}
