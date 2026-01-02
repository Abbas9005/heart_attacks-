import 'package:flutter/material.dart';
import 'package:heart_risk_/risk/heart_risk_form.dart';
import 'package:heart_risk_/tems.dart';
// import 'heart_risk_form.dart';
// import 'app_theme.dart'; // Import the new theme file

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Heart Risk Assessment',
     debugShowMaterialGrid: false,
      theme: AppTheme.lightTheme, // Use the theme from AppTheme class
      home: const HeartRiskForm(),
    );
  }
}
