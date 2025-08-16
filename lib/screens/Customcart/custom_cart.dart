import 'package:flutter/material.dart';
import 'package:vista/screens/CustomHome/bottom_nav_bar.dart';

class CustomCart extends StatelessWidget {
  const CustomCart({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(bottomNavigationBar: const RoundedBottomnavbar());
  }
}
