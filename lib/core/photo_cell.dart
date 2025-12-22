import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class PhotoCell extends StatelessWidget {
  final bool isActive;
  final XFile? photo;
  final CameraController controller;

  const PhotoCell({super.key, required this.isActive, required this.photo, required this.controller});

  @override
  Widget build(BuildContext context) {
    // Ô đang active → camera preview
    if (isActive) {
      return ClipRRect(child: CameraPreview(controller));
    }

    // Ô đã chụp
    if (photo != null) {
      return ClipRRect(child: Image.file(File(photo!.path), fit: BoxFit.cover));
    }

    // Ô chưa tới lượt
    return Container(decoration: BoxDecoration(color: Colors.black.withOpacity(0.25)));
  }
}
