import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:html' as html;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photobooth_marri/core/web/photo_cell_web.dart';

class WebviewPhotobooth extends StatefulWidget {
  const WebviewPhotobooth({super.key});

  @override
  State<WebviewPhotobooth> createState() => _WebviewPhotoboothState();
}

class _WebviewPhotoboothState extends State<WebviewPhotobooth> {
  CameraController? _controller;
  List<CameraDescription> cameras = [];

  int currentIndex = 0;
  List<Uint8List?> photos = List.filled(6, null);

  final GlobalKey repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy camera')),
          );
        }
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khởi tạo camera: $e')),
        );
      }
    }
  }

  Future<void> takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final XFile file = await _controller!.takePicture();
      final Uint8List bytes = await file.readAsBytes();

      setState(() {
        photos[currentIndex] = bytes;

        if (currentIndex < 5) {
          currentIndex++;
        } else {
          // Đã chụp đủ 6 ảnh
          capturePhotobooth();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chụp ảnh: $e')),
        );
      }
    }
  }

  Future<void> capturePhotobooth() async {
    try {
      RenderRepaintBoundary? boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) return;

      // pixelRatio cao để in đẹp
      ui.Image image = await boundary.toImage(pixelRatio: 3);

      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return;

      Uint8List pngBytes = byteData.buffer.asUint8List();

      // Hiển thị dialog preview
      if (mounted) {
        showPreviewDialog(context, pngBytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tạo photobooth: $e')),
        );
      }
    }
  }

  void showPreviewDialog(BuildContext context, Uint8List imageBytes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Preview image
              AspectRatio(
                aspectRatio: 2 / 3,
                child: Image.memory(imageBytes, fit: BoxFit.contain),
              ),
              const SizedBox(height: 16),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      resetPhotos();
                    },
                    child: const Text('Chụp lại', style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      downloadImage(imageBytes);
                      Navigator.pop(context);
                      resetPhotos();
                    },
                    child: const Text('Tải xuống'),
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

  void downloadImage(Uint8List bytes) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    // ignore: unused_local_variable
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'photobooth_${DateTime.now().millisecondsSinceEpoch}.png')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void resetPhotos() {
    setState(() {
      photos = List.filled(6, null);
      currentIndex = 0;
    });
  }

  void deletePhoto(int index) {
    setState(() {
      photos[index] = null;
      if (index < currentIndex) {
        currentIndex = index;
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Row(
          children: [
            // 2/3 bên trái: Preview camera, nút chụp, danh sách ảnh
            Expanded(
              flex: 2,
              child: _buildLeftPanel(),
            ),
            // 1/3 bên phải: Khung ảnh và lồng ghép
            Expanded(
              flex: 1,
              child: _buildRightPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Preview camera
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CameraPreview(_controller!),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Nút chụp
          GestureDetector(
            onTap: takePhoto,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF1493),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF1493).withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt, size: 32, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          // Danh sách ảnh đã chụp
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ảnh đã chụp (${photos.where((p) => p != null).length}/6)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: index == currentIndex ? const Color(0xFFFF1493) : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: photos[index] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      photos[index]!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                          ),
                          if (photos[index] != null)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => deletePhoto(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'Preview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: RepaintBoundary(
              key: repaintKey,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    // Grid ảnh
                    Center(
                      child: AspectRatio(
                        aspectRatio: 2 / 3,
                        child: _buildPhotoGrid(),
                      ),
                    ),
                    // Khung ảnh
                    Center(
                      child: AspectRatio(
                        aspectRatio: 2 / 3,
                        child: Image.asset(
                          'assets/images/khung.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return Container(
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
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
          return PhotoCellWeb(
            isActive: index == currentIndex,
            photoBytes: photos[index],
            controller: _controller!,
          );
        },
      ),
    );
  }
}
