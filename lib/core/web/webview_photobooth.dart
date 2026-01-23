import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:html' as html;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photobooth_marri/core/web/photo_cell_web.dart';
import 'package:photobooth_marri/core/web/camera_preview.dart';
import 'package:photobooth_marri/core/web/view_photobooth/view_1x1.dart';
import 'package:photobooth_marri/core/web/view_photobooth/view_1x2.dart';
import 'package:photobooth_marri/core/web/view_photobooth/view_2x4.dart';
import 'package:photobooth_marri/core/web/widget/count_down_time.dart';

enum ViewType {
  oneByOne(1, 'assets/images/1x1.png'),
  oneByTwo(2, 'assets/images/1x2.png'),
  twoByFour(8, 'assets/images/2x4.png');

  const ViewType(this.imageCount, this.previewImage);
  final String previewImage;
  final int imageCount;
}

class WebviewPhotobooth extends StatefulWidget {
  const WebviewPhotobooth({super.key});

  @override
  State<WebviewPhotobooth> createState() => _WebviewPhotoboothState();
}

class _WebviewPhotoboothState extends State<WebviewPhotobooth> {
  CameraController? _controller;
  List<CameraDescription> cameras = [];
  final GlobalKey<CameraPreviewWebState> _cameraPreviewKey = GlobalKey<CameraPreviewWebState>();

  int currentIndex = 0;
  List<Uint8List?> photos = List.filled(8, null);
  Uint8List? photoboothImage; // Ảnh photobooth đã tạo

  final GlobalKey repaintKey = GlobalKey();

  ViewType viewType = ViewType.twoByFour;
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

  Future<bool> takePhoto() async {
    if (currentIndex >= viewType.imageCount || currentIndex < 0) return false;
    try {
      Uint8List? bytes;

      // Sử dụng CameraPreviewWeb để capture frame
      if (_cameraPreviewKey.currentState != null) {
        bytes = await _cameraPreviewKey.currentState!.captureFrame();
      } else if (_controller != null && _controller!.value.isInitialized) {
        // Fallback: sử dụng CameraController nếu có
        final XFile file = await _controller!.takePicture();
        bytes = await file.readAsBytes();
      }

      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể chụp ảnh')),
          );
        }
        return false;
      }

      bool value = false;
      final int indexToUpdate = currentIndex;
      final bool wasLast = currentIndex == viewType.imageCount - 1;

      // Lưu ảnh vào state
      setState(() {
        photos[indexToUpdate] = bytes;
        if (!wasLast) {
          currentIndex = photos.indexWhere((photo) => photo == null);
          value = true;
        } else {
          // Đã chụp đủ ảnh, sẽ tạo photobooth sau khi frame hiện thị
          value = false;
          currentIndex++;
        }
      });

      // Nếu vừa chụp ảnh cuối cùng, chờ các Image.memory được decode + frame
      if (wasLast) {
        _ensureImagesReadyAndCapture();
      }

      return value;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chụp ảnh: $e')),
        );
      }
      return false;
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

      // Lưu ảnh photobooth vào state
      if (mounted) {
        setState(() {
          photoboothImage = pngBytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tạo photobooth: $e')),
        );
      }
    }
  }

  // Wait until MemoryImage widgets are decoded and a frame is rendered, then capture
  Future<void> _ensureImagesReadyAndCapture() async {
    try {
      final int count = viewType.imageCount;

      for (int i = 0; i < count; i++) {
        final bytes = photos[i];
        if (bytes == null) continue;

        final provider = MemoryImage(bytes);
        final ImageStream stream = provider.resolve(const ImageConfiguration());
        final completer = Completer<void>();
        ImageStreamListener? listener;
        listener = ImageStreamListener((ImageInfo info, bool syncCall) {
          completer.complete();
          stream.removeListener(listener!);
        }, onError: (dynamic _, StackTrace? __) {
          completer.complete();
          stream.removeListener(listener!);
        });
        stream.addListener(listener);

        // Wait up to 2 seconds per image
        try {
          await completer.future.timeout(const Duration(seconds: 2));
        } catch (_) {
          // proceed even if timeout
        }
      }

      // Give one frame to render
      await Future.delayed(const Duration(milliseconds: 50));
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await capturePhotobooth();
      });
    } catch (e) {
      // ignore and still try to capture
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await capturePhotobooth();
      });
    }
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
      photos = List.filled(8, null);
      currentIndex = 0;
      photoboothImage = null;
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
              child: Stack(
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CameraPreviewWeb(
                        key: _cameraPreviewKey,
                        mirror: true,
                      ),
                    ),
                  ),
                  // List viewType với nút chụp ở vị trí đang chọn
                  Container(
                    padding: const EdgeInsets.only(bottom: 20),
                    alignment: Alignment.bottomCenter,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: ViewType.values.map((type) {
                        final isSelected = viewType == type;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              viewType = type;
                              // Reset photos khi đổi viewType
                              photos = List.filled(8, null);
                              currentIndex = 0;
                              photoboothImage = null;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Preview image của viewType
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey[800],
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFFFF1493) : Colors.grey[600]!,
                                      width: isSelected ? 3 : 2,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFFFF1493).withOpacity(0.5),
                                              blurRadius: 12,
                                              spreadRadius: 3,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: ClipOval(
                                    child: Image.asset(
                                      type.previewImage,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                // Nút chụp chỉ hiển thị ở viewType đang chọn
                                if (isSelected)
                                  Positioned.fill(
                                    child: GestureDetector(
                                      onTap: () {
                                        _startCountdownAndCapture();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFFFF1493).withOpacity(0.8),
                                          border: Border.all(color: Colors.white, width: 3),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFFF1493).withOpacity(0.6),
                                              blurRadius: 15,
                                              spreadRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: Image.asset(
                                          type.previewImage,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // CountdownScreen(
                  //   onFinish: () {
                  //     takePhoto();
                  //   },
                  // ),
                ],
              ),
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
                  'Ảnh đã chụp (${photos.where((p) => p != null).length}/${viewType.imageCount})',
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
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: viewType.imageCount,
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

  void _startCountdownAndCapture() {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false, // overlay lên camera
        pageBuilder: (_, __, ___) => CountdownOverlay(
          onFinish: () async {
            takePhoto().then((value) {
              if (value == true) {
                Navigator.pop(context); // tắt countdown
                _startCountdownAndCapture();
              } else {
                Navigator.pop(context); // tắt countdown
              }
            });
          },
        ),
      ),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Builder(builder: (context) {
            switch (viewType) {
              case ViewType.oneByOne:
                return View1x1(photos: photos, repaintKey: repaintKey);
              case ViewType.oneByTwo:
                return View1x2(photos: photos, repaintKey: repaintKey);
              case ViewType.twoByFour:
                return View2x4(photos: photos, repaintKey: repaintKey);
            }
          }),

          const SizedBox(height: 16),
          // Nút Lưu ảnh và Chụp lại
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: photoboothImage != null
                      ? () {
                          downloadImage(photoboothImage!);
                        }
                      : null,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: photoboothImage != null ? const Color(0xFFFF1493) : Colors.grey[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Lưu ảnh',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    resetPhotos();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.grey[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Chụp lại',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget _buildPhotoGrid() {
  //   return Container(
  //     alignment: Alignment.topCenter,
  //     decoration: BoxDecoration(
  //       color: Colors.red,
  //     ),
  //     child: GridView.builder(
  //       physics: const NeverScrollableScrollPhysics(),
  //       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //         crossAxisCount: 2,
  //         childAspectRatio: 159 / 105,
  //         crossAxisSpacing: 0,
  //         mainAxisSpacing: 0,
  //       ),
  //       itemCount: 8,
  //       itemBuilder: (context, index) {
  //         return PhotoCellWeb(
  //           isActive: index == currentIndex,
  //           photoBytes: photos[index],
  //         );
  //       },
  //     ),
  //   );
  // }
}
