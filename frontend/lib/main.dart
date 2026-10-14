import 'package:flutter/material.dart';
import 'package:trill_covoit/core/theme/app_theme.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TRILL Covoit’',
      theme: AppTheme.lightTheme,
      home: const Scaffold(
        body: Center(
          child: Text('TRILL Covoit’'),
        ),
      ),
    );
  }
}
