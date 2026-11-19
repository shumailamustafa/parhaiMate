import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ParhaiMateApp());
}

/// Temporary Stage 1 entry widget replaced by [App] in later stages.
class ParhaiMateApp extends StatelessWidget {
  const ParhaiMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ParhaiMate',
      home: Scaffold(
        backgroundColor: Color(0xFFFFFFFF),
        body: Center(
          child: Text(
            'ParhaiMate',
            style: TextStyle(
              color: Color(0xFF000000),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
