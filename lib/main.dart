import 'package:flutter/material.dart';
import 'package:vista/screens/onboarding_screens.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "VistA",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: "Nonile"),
      home: OnboardingScreens(),
    );
  }
}
