import 'package:flutter/material.dart';
import 'package:lembretes/pages/home_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lembretes',
      home: HomeScreen(),
    );
  }
}
