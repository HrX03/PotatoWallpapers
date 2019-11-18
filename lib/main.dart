import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart';
import 'package:image_downloader/image_downloader.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:simple_animations/simple_animations/controlled_animation.dart';
import 'package:wallpaper/wallpaper.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Potato Wallpapers',
      home: MyHomePage(),
      theme: ThemeData.light().copyWith(
        appBarTheme: AppBarTheme(
          actionsIconTheme: Theme.of(context).iconTheme,
          textTheme: Theme.of(context).textTheme,
          iconTheme: Theme.of(context).iconTheme,
        )
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF121212),
        cardColor: Color(0xFF212121),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<ImageUrlNameAuthor> images = [];
  final double basePadding = 8;
  bool syncing = false;

  @override
  void initState() {
    super.initState();

    fetchImages();
  }

  Future<void> fetchImages() async {
    Response deldog = await get("https://del.dog/raw/potatowalls");
    List<String> splittedBody = deldog.body.split("\n");

    images.clear();

    for(int i = 0; i < splittedBody.length; i++) {
      List<String> imagePair = splittedBody[i].split(",");

      images.add(ImageUrlNameAuthor(imagePair[0], imagePair[1], imagePair[2]));
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark ?
          Brightness.light :
          Brightness.dark,
      systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
      systemNavigationBarIconBrightness: Theme.of(context).brightness == Brightness.dark ?
          Brightness.light :
          Brightness.dark,
    ));

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(MediaQuery.of(context).padding.top + 60),
        child: Material(
          elevation: 2,
          color: Theme.of(context).cardColor,
          child: Container(
            margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            padding: EdgeInsets.only(left: 20, right: 10),
            height: 60,
            child: Row(
              children: <Widget>[
                SvgPicture.asset(
                  "assets/logo.svg",
                  width: 36,
                  height: 36,
                ),
                VerticalDivider(
                  width: 10,
                  color: Colors.transparent
                ),
                Text(
                  "PotatoWallpapers",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: ControlledAnimation(
                    tween: Tween<double>(begin: 0, end: pi * 2),
                    duration: Duration(milliseconds: 900),
                    playback: Playback.LOOP,
                    builder: (context, animation) {
                      return Transform.rotate(
                        angle: syncing ? -animation : 0,
                        child: Icon(
                          Icons.sync,
                        ),
                      );
                    },
                  ),
                  onPressed: () async {
                    syncing = true;
                    await fetchImages();
                    syncing = false;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Container(
            child: images.length > 0 ?
                GridView.builder(
                  padding: EdgeInsets.symmetric(vertical: basePadding),
                  physics: BouncingScrollPhysics(),
                  itemCount: images.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 9/12
                  ),
                  itemBuilder: (context, index) {
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: EdgeInsets.fromLTRB(
                        index % 2 == 0 ? basePadding * 2 : basePadding,
                        basePadding,
                        index % 2 == 0 ? basePadding : basePadding * 2,
                        basePadding),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (context) => ImageView(
                            images: images,
                            initialIndex: index,
                          ),
                        )),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Hero(
                            tag: "image" + index.toString(),
                            child: CachedNetworkImage(
                              imageUrl: images[index].url,
                              fit: BoxFit.cover,
                              placeholder: (context, url) {
                                return Container(
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ) :
                Center(
                  child: Text("No images found"),
                ),
          ),
        ],
      ),
    );
  }
}

class ImageView extends StatefulWidget {
  final List<ImageUrlNameAuthor> images;
  final int initialIndex;

  ImageView({
    @required this.images,
    @required this.initialIndex,
  });

  @override createState() => _ImageViewState();
}

class _ImageViewState extends State<ImageView> {
  PageController controller;
  bool downloading = false;
  double downloadProgress = 0;
  int currentIndex;

  @override
  void initState() {
    super.initState();
    controller = PageController(initialPage: widget.initialIndex);
    currentIndex = widget.initialIndex;
  }

  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark ?
          Brightness.light :
          Brightness.dark,
      systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
      systemNavigationBarIconBrightness: Theme.of(context).brightness == Brightness.dark ?
          Brightness.light :
          Brightness.dark,
    ));

    return Scaffold(
      key: scaffoldKey,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(MediaQuery.of(context).padding.top + 60),
        child: Material(
          elevation: 2,
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Container(
            margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            padding: EdgeInsets.symmetric(horizontal: 10),
            height: 60,
            child: Row(
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Text(
                    widget.images[currentIndex].name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: PhotoViewGallery.builder(
        itemCount: widget.images.length,
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(widget.images[index].url),
            initialScale: PhotoViewComputedScale.covered * 1.0,
            minScale: PhotoViewComputedScale.contained * 1.0,
            heroAttributes: PhotoViewHeroAttributes(
              tag: "image" + index.toString(),
              transitionOnUserGestures: true
            ),
          );
        },
        pageController: controller,
        onPageChanged: (page) {
          setState(() => currentIndex = page);
        },
      ),
      bottomNavigationBar: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        height: 50,
        child: Column(
          children: <Widget>[
            Container(
              height: 2,
              child: Visibility(
                visible: downloading,
                child: LinearProgressIndicator(
                  value: downloadProgress,
                ),
              ),
            ),
            Container(
              height: 48,
              child: Material(
                color: Colors.transparent,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Spacer(),
                    IconButton(
                      tooltip: "Download wallpaper",
                      icon: Icon(Icons.file_download),
                      onPressed: () async {
                        setState(() {
                          downloading = true;
                        });

                        await ImageDownloader.downloadImage(widget.images[currentIndex].url,
                          destination: AndroidDestinationType.custom(
                            inPublicDir: true,
                            directory: 'Pictures',
                            subDirectory: 'PotatoWallpapers/' +
                                widget.images[currentIndex].name + '.png'
                          )
                        );

                        ImageDownloader.callback(onProgressUpdate: (context, index) {
                          setState(() => downloadProgress = index / 100);
                        });

                        setState(() {
                          downloading = false;
                        });

                        scaffoldKey.currentState.showSnackBar(SnackBar(
                          content: Text("Wallpaper saved successfully"),
                        ));
                      },
                    ),
                    Spacer(flex: 2),
                    Text(widget.images[currentIndex].author),
                    Spacer(flex: 2),
                    IconButton(
                      tooltip: "Set wallpaper",
                      icon: Icon(Icons.wallpaper),
                      onPressed: () async {
                        WallpaperSetMode result = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text("Set wallpaper on"),
                            contentPadding: EdgeInsets.all(10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                ListTile(
                                  leading: Icon(Icons.home),
                                  title: Text("Home screen"),
                                  onTap: () => Navigator.pop(context, WallpaperSetMode.HOME),
                                ),
                                ListTile(
                                  leading: Icon(Icons.lock),
                                  title: Text("Lock screen"),
                                  onTap: () => Navigator.pop(context, WallpaperSetMode.LOCKSCREEN),
                                ),
                                ListTile(
                                  leading: Icon(Icons.check),
                                  title: Text("Home and lock screen"),
                                  onTap: () => Navigator.pop(context, WallpaperSetMode.BOTH),
                                ),
                              ],
                            ),
                          ),
                        );

                        if(result != null) {
                          Stream<String> progress = Wallpaper.ImageDownloadProgress(
                              widget.images[currentIndex].url);

                          progress.listen((data) {
                            setState(() {
                              downloadProgress = double.parse(data.replaceAll("%", "")) / 100;
                              downloading = true;
                            });
                          }, onDone: () async {
                            switch(result) {
                              case(WallpaperSetMode.HOME):
                                await Wallpaper.homeScreen();
                                break;
                              case(WallpaperSetMode.LOCKSCREEN):
                                await Wallpaper.lockScreen();
                                break;
                              case(WallpaperSetMode.BOTH):
                                await Wallpaper.bothScreen();
                                break;
                              default:
                                await Wallpaper.bothScreen();
                                break;
                            }

                            setState(() {
                              downloading = false;
                            });

                            scaffoldKey.currentState.showSnackBar(SnackBar(
                              content: Text("Wallpaper set successfully"),
                            ));
                          });
                        }
                      },
                    ),
                    Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum WallpaperSetMode { HOME, LOCKSCREEN, BOTH }

class ImageUrlNameAuthor {
  String url;
  String name;
  String author;

  ImageUrlNameAuthor(url, name, author) {
    this.url = url;
    this.name = name;
    this.author = author;
  }
}