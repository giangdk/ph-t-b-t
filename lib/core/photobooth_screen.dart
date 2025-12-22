import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photobooth_marri/core/photo_cell.dart';

class PhotoboothScreen extends StatefulWidget {
  const PhotoboothScreen({super.key});

  @override
  State<PhotoboothScreen> createState() => _PhotoboothScreenState();
}

class _PhotoboothScreenState extends State<PhotoboothScreen> {
  CameraController? _controller;
  List<CameraDescription> cameras = [];

  int currentIndex = 0;
  List<XFile?> photos = List.filled(6, null);

  final GlobalKey repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    cameras = await availableCameras();

    _controller = CameraController(cameras.first, ResolutionPreset.high, enableAudio: false);

    await _controller!.initialize();
    await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);

    setState(() {});
  }

  Future<void> takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final XFile file = await _controller!.takePicture();

    setState(() {
      photos[currentIndex] = file;

      if (currentIndex < 6) {
        currentIndex++;
        if (currentIndex == 6) {
          capturePhotobooth().then((value) {
            if (context.mounted) {
              setState(() {
                photos = List.filled(6, null);
                currentIndex = 0;
              });
              showPreviewDialog(context, value);
            }
          });
        }
      }
    });
  }

  void showPreviewDialog(BuildContext context, File imageFile) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.green,
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Preview image
              AspectRatio(
                aspectRatio: 2 / 3, // photobooth 5x15
                child: Image.file(imageFile, fit: BoxFit.contain),
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Chụp lại', style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: in / save / share
                      Navigator.pop(context);
                    },
                    child: const Text('In'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<File> capturePhotobooth() async {
    try {
      RenderRepaintBoundary boundary = repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // pixelRatio cao để in đẹp
      ui.Image image = await boundary.toImage(pixelRatio: 3);

      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/photobooth_${DateTime.now().millisecondsSinceEpoch}.png');

      await file.writeAsBytes(pngBytes);
      return file;
    } catch (e) {
      throw Exception('Capture failed: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: 2 / 3,
                child: RepaintBoundary(
                  key: repaintKey,
                  child: Stack(
                    children: [
                      Center(
                        child: AspectRatio(aspectRatio: 2 / 3, child: buildGrid()),
                      ),
                      Center(
                        child: AspectRatio(
                          aspectRatio: 2 / 3,
                          child: Image.asset('assets/images/khung.png', fit: BoxFit.contain),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(alignment: Alignment.bottomCenter, child: buildCaptureButton()),
          ],
        ),
      ),
    );
  }

  Widget buildGrid() {
    return Container(
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 36),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 580 / 458,
          crossAxisSpacing: 0,
          mainAxisSpacing: 0,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return PhotoCell(isActive: index == currentIndex, photo: photos[index], controller: _controller!);
        },
      ),
    );
  }

  Widget buildCaptureButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: GestureDetector(
        onTap: takePhoto,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: const Center(child: Icon(Icons.camera_alt, size: 32, color: Colors.white)),
        ),
      ),
    );
  }
}
