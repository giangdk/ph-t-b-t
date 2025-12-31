import 'dart:typed_data';
import 'package:flutter/material.dart';

class PhotoCellWeb extends StatelessWidget {
  final bool isActive;
  final Uint8List? photoBytes;

  const PhotoCellWeb({
    super.key,
    required this.isActive,
    required this.photoBytes,
  });

  @override
  Widget build(BuildContext context) {
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

    // Ô đang active nhưng chưa chụp → hiển thị indicator
    if (isActive) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFFF1493),
            width: 2,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.camera_alt,
            color: Color(0xFFFF1493),
            size: 32,
          ),
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
