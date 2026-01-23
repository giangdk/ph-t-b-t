import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui_web' as ui_web;

class CameraPreviewWeb extends StatefulWidget {
  final String? videoElementId;
  final bool mirror;

  const CameraPreviewWeb({
    super.key,
    this.videoElementId,
    this.mirror = false,
  });

  @override
  State<CameraPreviewWeb> createState() => CameraPreviewWebState();
}

class CameraPreviewWebState extends State<CameraPreviewWeb> {
  html.VideoElement? _videoElement;
  html.MediaStream? _stream;
  String? _viewId;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Tạo unique ID cho video element
      _viewId = widget.videoElementId ?? 'camera-preview-${DateTime.now().millisecondsSinceEpoch}';

      // Tạo video element
      _videoElement = html.VideoElement()
        ..id = _viewId!
        ..autoplay = true
        ..setAttribute('playsinline', 'true')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';

      if (widget.mirror) {
        _videoElement!.style.transform = 'scaleX(-1)';
      }

      // Yêu cầu truy cập camera
      _stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {
          'facingMode': 'user', // Front camera
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        },
        'audio': false,
      });

      // Gán stream vào video element
      _videoElement!.srcObject = _stream;

      // Đăng ký video element với Flutter
      ui_web.platformViewRegistry.registerViewFactory(
        _viewId!,
        (int viewId) => _videoElement!,
      );

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Lỗi khởi tạo camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi truy cập camera: $e')),
        );
      }
    }
  }

  Future<Uint8List?> captureFrame() async {
    if (_videoElement == null || _stream == null) return null;

    try {
      // Tạo canvas để capture frame
      final canvas = html.CanvasElement(
        width: _videoElement!.videoWidth,
        height: _videoElement!.videoHeight,
      );
      final context = canvas.context2D;

      // Vẽ frame từ video vào canvas
      if (widget.mirror) {
        // Flip horizontally so captured bytes match mirrored preview
        context.save();
        context.translate(canvas.width!.toDouble(), 0);
        context.scale(-1, 1);
        context.drawImage(_videoElement!, 0, 0);
        context.restore();
      } else {
        context.drawImage(_videoElement!, 0, 0);
      }

      // Chuyển canvas thành blob
      final blob = await canvas.toBlob('image/png');

      // Đọc blob thành Uint8List
      final reader = html.FileReader();
      final completer = Completer<Uint8List>();

      reader.onLoad.listen((event) {
        final result = reader.result as List<int>;
        completer.complete(Uint8List.fromList(result));
      });

      reader.onError.listen((event) {
        completer.completeError('Lỗi đọc ảnh');
      });

      reader.readAsArrayBuffer(blob);
      return await completer.future;
    } catch (e) {
      debugPrint('Lỗi capture frame: $e');
      return null;
    }
  }

  @override
  void dispose() {
    // Dừng stream
    _stream?.getTracks().forEach((track) => track.stop());
    _stream = null;
    _videoElement = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _viewId == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return HtmlElementView(
      viewType: _viewId!,
    );
  }
}
