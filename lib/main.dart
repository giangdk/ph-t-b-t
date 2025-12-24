import 'package:flutter/material.dart';
import 'package:photobooth_marri/core/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Photobooth',
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}
