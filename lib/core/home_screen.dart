import 'package:flutter/material.dart';
import 'package:photobooth_marri/core/app/photobooth_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedFilterIndex = 0; // Featured is selected

  final List<String> _filters = ['New', 'Tình yêu', 'Nghệ thuật', 'Vintage'];
  final List<IconData> _filterIcons = [Icons.auto_awesome, Icons.favorite, Icons.diamond, Icons.star];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildThemeFilterBar(),
                        const SizedBox(height: 12),
                        _buildTrendingThemes(),
                        const SizedBox(height: 24),
                        _buildCategoryIcons(),
                        const SizedBox(height: 24),
                        _buildChooseLayout(),
                        const SizedBox(height: 100), // Space for floating button
                      ],
                    ),
                  ),
                ),
              ],
            ),
            _buildFloatingCameraButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Photobooth',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeFilterBar() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedFilterIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilterIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFF1493) : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFFF1493) : Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _filterIcons[index],
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _filters[index],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendingThemes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildThemeCard(
                  title: 'Cherry Blossom',
                  description: 'Soft pink vibes',
                  tag: 'Popular',
                  tagColor: const Color(0xFFFF1493),
                  image: _buildPlaceholderImage(const Color(0xFFFFB6C1)),
                );
              } else {
                return _buildThemeCard(
                  title: 'Neon',
                  description: 'Cyberpunk',
                  tag: 'New',
                  tagColor: const Color(0xFFFF1493),
                  image: _buildNeonPlaceholder(),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildThemeCard({
    required String title,
    required String description,
    required String tag,
    required Color tagColor,
    required Widget image,
  }) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: image,
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tagColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage(Color color) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Center(
        child: Icon(
          Icons.image,
          size: 60,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildNeonPlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A0033),
            const Color(0xFF6600CC),
            const Color(0xFFFF1493),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Center(
        child: Icon(
          Icons.diamond,
          size: 60,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildCategoryIcons() {
    final categories = [
      {'name': 'Gradient', 'icon': Icons.gradient, 'color': Colors.orange},
      {'name': 'Artsy', 'icon': Icons.eco, 'color': Colors.green},
      {'name': 'Polaroid', 'icon': Icons.crop_original, 'color': Colors.white},
      {'name': 'More', 'icon': Icons.grid_view, 'color': Colors.white},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: categories.map((category) {
        return Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                color: category['name'] == 'Gradient' ? null : Colors.transparent,
                gradient: category['name'] == 'Gradient'
                    ? const LinearGradient(
                        colors: [Colors.orange, Colors.yellow, Colors.green, Colors.blue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
              ),
              child: Icon(
                category['icon'] as IconData,
                color: category['name'] == 'Gradient' ? Colors.white : category['color'] as Color,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category['name'] as String,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildChooseLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ảnh đã chụp',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Nhìn lại từng khoảnh khắc của bạn',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.grid_3x3,
                    color: Colors.white.withOpacity(0.3),
                    size: 40,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingCameraButton() {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PhotoboothScreen()),
            );
          },
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF1493),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF1493).withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.camera_alt,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}
