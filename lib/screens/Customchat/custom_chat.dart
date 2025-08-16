import 'package:flutter/material.dart';
import 'package:vista/screens/CustomHome/bottom_nav_bar.dart';

class CustomChat extends StatelessWidget {
  const CustomChat({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(bottomNavigationBar: const RoundedBottomnavbar());
  }
}
