// lib/main.dart
import 'package:flutter/material.dart';
import 'core/localization.dart';
import 'views/welcome_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppLocalization _localization = AppLocalization();

  @override
  void initState() {
    super.initState();
    _localization.addListener(_onLocaleChanged);
  }

  void _onLocaleChanged() {
    setState(() {}); // Re-build app to propagate language change
  }

  @override
  void dispose() {
    _localization.removeListener(_onLocaleChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Learning Style Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Inter',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF006A4E), // Cameroon Green
          secondary: Color(0xFFCE1126), // Cameroon Red
          surface: Color(0xFF161E2B),
          background: Color(0xFF0A0E14),
        ),
        useMaterial3: true,
      ),
      home: const WelcomeView(),
    );
  }
}
