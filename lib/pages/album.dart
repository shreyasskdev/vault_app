import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// import 'data.dart';
final List<Map<String, dynamic>> imageList = [];

class AlbumPage extends StatelessWidget {
  final String name;
  const AlbumPage({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(name),
        elevation: 0,
        backgroundColor: Color.fromARGB(135, 0, 0, 0),
        // forceMaterialTransparency: true,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            // filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            filter: ImageFilter.compose(
                outer: ImageFilter.blur(
                    sigmaY: 20, sigmaX: 20, tileMode: TileMode.decal),
                inner: ImageFilter.blur(
                    sigmaY: 20 + 20,
                    sigmaX: 10 + 20,
                    tileMode: TileMode.clamp)),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
      ),
      body: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 160,
          childAspectRatio: 1 / 1,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: imageList.length,
        itemBuilder: (BuildContext context, int index) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  const String imageUrl = "hello";
                  context.push("/photo/$imageUrl");
                },
                child: Hero(
                  tag: "photo" + imageList[index]["id"].toString(),
                  child: AspectRatio(
                    aspectRatio: 1 / 1,
                    child: Image.network(
                      imageList[index]["url"],
                      fit: BoxFit.cover,
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
