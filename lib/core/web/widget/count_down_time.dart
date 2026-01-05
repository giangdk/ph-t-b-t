import 'package:flutter/material.dart';

class CountdownOverlay extends StatefulWidget {
  final VoidCallback onFinish;

  const CountdownOverlay({super.key, required this.onFinish});

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  int _current = 3;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _opacity = Tween(begin: 1.0, end: 0.0).animate(_controller);
    _scale = Tween(begin: 1.5, end: 0.8).animate(_controller);

    _play();
  }

  void _play() {
    _controller.forward(from: 0).then((_) {
      if (_current > 1) {
        setState(() => _current--);
        _play();
      } else {
        widget.onFinish();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.4),
      body: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: ScaleTransition(
            scale: _scale,
            child: Text(
              '$_current',
              style: const TextStyle(
                fontSize: 140,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
