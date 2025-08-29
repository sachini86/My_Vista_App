import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_vista/screens/onboarding_screens.dart';
import 'package:my_vista/screens/onboarding/sign_inpage.dart';
import 'package:my_vista/screens/onboarding/signup_page.dart';
import 'package:my_vista/screens/CustomHome/custom_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
      initialRoute: '/',
      routes: {
        '/': (context) => const OnboardingScreens(),
        '/Sign In': (context) => const SignInPage(),
        '/Sign Up': (context) => const SignupPage(),
        '/customHome': (context) => const CustomerHomePage(),
      },
    );
  }
}
