import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import your home pages

import 'package:my_vista/screens/CustomHome/bottom_nav_bar.dart';
import 'package:my_vista/screens/ArtistHome/artist_bottom_nav.dart';

class SuccessfulLoginPage extends StatefulWidget {
  const SuccessfulLoginPage({super.key});

  @override
  State<SuccessfulLoginPage> createState() => _SuccessfulLoginPageState();
}

class _SuccessfulLoginPageState extends State<SuccessfulLoginPage> {
  bool _isLoading = false;

  Future<String?> getUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return doc.data()!['role'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user role: $e');
      return null;
    }
  }

  void navigateAccordingToRole() async {
    setState(() {
      _isLoading = true; // show loader while fetching
    });

    String? role = await getUserRole();

    if (!mounted) return; // prevent using context if widget disposed

    setState(() {
      _isLoading = false;
    });

    if (role == 'Buyer') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoundedBottomnavbar()),
      );
    } else if (role == 'Artist') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ArtistRoundedBottomNavbar()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User role not found.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFDEBEC),
      body: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/download.png', height: 140),
              const SizedBox(height: 24),
              const Text(
                'Congratulations!',
                style: TextStyle(
                  color: Color(0xff930909),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your account is complete! Welcome to VistA!\nDive into your personalized art experience now.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : navigateAccordingToRole,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff930909),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Get Started',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
