import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class PhotoCellWeb extends StatelessWidget {
  final bool isActive;
  final Uint8List? photoBytes;
  final CameraController controller;

  const PhotoCellWeb({
    super.key,
    required this.isActive,
    required this.photoBytes,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // Ô đang active → camera preview
    if (isActive) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CameraPreview(controller),
      );
    }

    // Ô đã chụp
    if (photoBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          photoBytes!,
          fit: BoxFit.cover,
        ),
      );
    }

    // Ô chưa tới lượt
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
