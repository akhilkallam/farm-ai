import 'package:flutter/material.dart';
import 'core/theme.dart';

void main() {
  runApp(const FarmAIApp());
}

class FarmAIApp extends StatelessWidget {
  const FarmAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FarmAI',
      theme: FarmAITheme.theme,
      home: const Scaffold(
        body: Center(child: Text('FarmAI')),
      ),
    );
  }
}
