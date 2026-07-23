import 'package:flutter/material.dart';
import 'screens/signalement_form_screen.dart';

void main() => runApp(const SignalementApp());

class SignalementApp extends StatelessWidget {
  const SignalementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Signalements Crosne',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const SignalementFormScreen(),
    );
  }
}
