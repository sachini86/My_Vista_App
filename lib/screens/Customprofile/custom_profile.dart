import 'package:flutter/material.dart';

class CustomProfile extends StatefulWidget {
  const CustomProfile({super.key});

  @override
  State<CustomProfile> createState() => _CustomProfileState();
}

class _CustomProfileState extends State<CustomProfile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.yellow);
  }
}
