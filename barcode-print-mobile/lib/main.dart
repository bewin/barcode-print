import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BarcodePrintApp());
}

class BarcodePrintApp extends StatelessWidget {
  const BarcodePrintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '条码打印系统',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1E5AB4),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const HomeScreen(),
    );
  }
}
