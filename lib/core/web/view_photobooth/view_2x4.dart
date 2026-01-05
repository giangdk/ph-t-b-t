import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:photobooth_marri/core/web/photo_cell_web.dart';
import 'package:photobooth_marri/gen/assets.gen.dart';

class View2x4 extends StatefulWidget {
  const View2x4({super.key, required this.photos, required this.repaintKey});
  final List<Uint8List?> photos;
  final GlobalKey repaintKey;
  @override
  State<View2x4> createState() => _View2x4State();
}

class _View2x4State extends State<View2x4> {
  int maxPhotos = 8;
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: widget.repaintKey,
      child: AspectRatio(
        aspectRatio: 25 / 37,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              // Grid ảnh
              Positioned.fill(
                child: _buildPhotoGrid(),
              ),
              // Khung ảnh
              Image.asset(
                Assets.images.a2x4.path,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    int currentIndex = widget.photos.indexWhere((photo) => photo != null);
    return Container(
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(
        color: Colors.red,
      ),
      child: GridView.builder(
        padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3 / 2,
          crossAxisSpacing: 0,
          mainAxisSpacing: 0,
        ),
        itemCount: maxPhotos,
        itemBuilder: (context, index) {
          return PhotoCellWeb(
            isActive: index == currentIndex,
            photoBytes: widget.photos[index],
          );
        },
      ),
    );
  }
}
