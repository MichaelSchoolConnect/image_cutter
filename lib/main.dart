import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import 'helpers.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Tile Replacer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Image Tile Replacer'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  File? _imageFile;
  final List<String> _imageDataset = [];
  final List<img.Image> _imageTiles = [];
  List<Color> datasetAvgRgbs = [];

  bool _loading = false;

  var image;
  var newImage;

  void _showSnackbar(String message) {
    print(message);
  }

  //All out logic is in this method
  // Step 2: Divide our input image in 20x20 parts
  Future<img.Image> processImage(int widthCount, int heightCount) async {
    Uint8List imageList = await _imageFile!.readAsBytes();

    img.Image? decodedImage = img.decodeImage(imageList);
    img.Image? newCreatedImage = decodedImage;
    int x = 0, y = 0;

    int width = (decodedImage!.width / widthCount).round();
    int height = (decodedImage.height / heightCount).round();

    List<img.Image> parts = [];
    List<img.Image> newImages = [];

    // Step 3: Calculate the avg RGB for each of the 400 parts in our input image
    List<Color> avgColours = [];
    for (int i = 0; i < heightCount; i++) {
      for (int j = 0; j < widthCount; j++) {
        img.Image imageToAdd = img.copyCrop(decodedImage, x, y, width, height);
        parts.add(imageToAdd);
        Color avgPartRgb = getAverageRBG(imageToAdd);
        int shortestValueIndex = 0;
        double shortestValue = double.maxFinite;
        for (int k = 0; k < datasetAvgRgbs.length; k++) {
          double distance = getDeltaE(datasetAvgRgbs[k], avgPartRgb);

          if (distance < shortestValue) {
            shortestValue = distance;
            shortestValueIndex = k;
          }
        }

        ByteData byteData =
            await rootBundle.load(_imageDataset[shortestValueIndex]);

        Uint8List bytes = byteData.buffer.asUint8List();

        img.Image? imageToReplace = img.decodeImage(bytes);

        img.Image resizedImage = img.copyResize(imageToReplace!,
            width: imageToAdd.width, height: imageToAdd.height);
        newImages.add(resizedImage);
        avgColours.add(avgPartRgb);
        newCreatedImage = img.copyInto(newCreatedImage!, resizedImage,
            dstX: x, dstY: y, srcH: imageToAdd.height, srcW: imageToAdd.width);

        x += width;
      }
      x = 0;
      y += height;
    }
    print('Parts: ${parts.length}');
    return newCreatedImage!;
  }

  Future<void> _getImage(ImageSource source) async {
    print('Get Image');
    try {
      final imageFile = await ImagePicker().pickImage(source: source);
      if (imageFile == null) {
        return;
      }

      setState(() {
        _imageFile = File(imageFile.path);
        _imageTiles.clear();
      });

      final imageBytes = await _imageFile!.readAsBytes();
      image = img.decodeImage(imageBytes)!;

      await _processNewImage(image, 400);
    } on Exception catch (e) {
      _showSnackbar('Error: $e');
    }
  }

  /* FutureOr<List<List<double>>> _calculateDistanceBetweenEachTile(
    var image,
    var tileRGBs,
  ) async {
    final completer = Completer<List<List<double>>>();
    final receivePort = ReceivePort();
    receivePort.listen((result) {
      completer.complete(result);
      receivePort.close();
    });

    await Isolate.spawn(_isolate, [
      image,
      tileRGBs,
      receivePort.sendPort,
    ]);

    return completer.future;
  }

  static void _isolate(List<dynamic> args) {
    final image = args[0] as img.Image;
    tileRGBs = args[1];
    final sendPort = args[2] as SendPort;

    print('Calculate distance between each tile and each part of the image');

    final distances = <List<double>>[];
    for (var i = 0; i < tileRGBs.length; i++) {
      final tileRGB = tileRGBs[i];
      final tileDistances = <double>[];
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final avgR = img.getRed(pixel);
          final avgG = img.getGreen(pixel);
          final avgB = img.getBlue(pixel);
          final distance = sqrt(pow(avgR - tileRGB[0], 2) +
              pow(avgG - tileRGB[1], 2) +
              pow(avgB - tileRGB[2], 2));
          tileDistances.add(distance);
        }
      }
      distances.add(tileDistances);
    }
    print('Distances: $distances');
    print('Distances length: ${distances.length}');

    sendPort.send(distances);
  }*/

  Future<void> _processNewImage(var image, int tileSize) async {
    print('Process Image');
    setState(() {
      _loading = true;
    });

    img.Image newSplitImage = await processImage(20, 20);
    newImage = newSplitImage;

    setState(() {
      _loading = false;
    });
  }

  Future<void> _loadDataset() async {
    setState(() {
      _loading = true;
      print('Loading dataset');
    });

    try {
      final manifestJson = await rootBundle.loadString('AssetManifest.json');
      final imagePaths = json
          .decode(manifestJson)
          .keys
          .where((String key) => key.startsWith('assets/images/dataset/'));

      for (var path in imagePaths) {
        ByteData byteData = await rootBundle.load(path);

        Uint8List bytes = byteData.buffer.asUint8List();

        img.Image? decodedImage = img.decodeImage(bytes);

        //Step 1: Calculate avg RGB for each tile image from our assets folder (Avg R, Avg G, Avg B)
        Color avgRgb = getAverageRBG(decodedImage!);
        datasetAvgRgbs.add(avgRgb);
        _imageDataset.add(path);
      }
    } on Exception catch (e) {
      _showSnackbar('Error: $e');
    } finally {
      setState(() {
        _loading = false;
        print('Dataset loaded');
      });
    }
  }

  Future<void> _replaceTiles() async {
    setState(() {
      _loading = true;
    });

    setState(() {
      _loading = false;
    });
  }

  @override
  void initState() {
    // Use Future.delayed to wait until the widget is fully built
    Future.delayed(Duration.zero, () async {
      setState(() {
        _loading = true;
      });
      await _loadDataset();
      setState(() {
        _loading = false;
      });
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Additional code
  }

  @override
  void deactivate() {
    super.deactivate();
    //this method not called when user press android back button or quit
    print('deactivate');
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQuery = MediaQuery.of(context);
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              if (_imageFile != null)
                Column(
                  children: <Widget>[
                    Image.file(
                      _imageFile!,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    const Divider(
                      color: Colors.red,
                      thickness: 2,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    if (newImage != null)
                      Image.memory(
                        Uint8List.fromList(img.encodePng(newImage!)),
                      )
                    else
                      const Text('Creating new image...'),
                    const SizedBox(height: 20),
                    if (_imageTiles.isNotEmpty)
                      ElevatedButton(
                        onPressed: _replaceTiles,
                        child: const Text('Replace Tiles'),
                      ),
                    if (_loading) const CircularProgressIndicator(),
                  ],
                )
              else
                const Text('Please select an image'),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _getImage(ImageSource.gallery),
        tooltip: 'Select Image',
        child: const Icon(Icons.photo_library),
      ),
    );
  }
}
