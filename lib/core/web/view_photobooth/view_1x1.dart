import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:photobooth_marri/core/web/photo_cell_web.dart';
import 'package:photobooth_marri/gen/assets.gen.dart';

class View1x1 extends StatefulWidget {
  const View1x1({super.key, required this.photos, required this.repaintKey});
  final List<Uint8List?> photos;
  final GlobalKey repaintKey;
  @override
  State<View1x1> createState() => _View1x1State();
}

class _View1x1State extends State<View1x1> {
  int maxPhotos = 1;
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
                Assets.images.a1x1.path,
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
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 12, left: 20, right: 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          childAspectRatio: 2 / 3,
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
