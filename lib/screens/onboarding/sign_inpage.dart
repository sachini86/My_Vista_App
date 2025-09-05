import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:my_vista/screens/onboarding/signup_page.dart';
import 'package:my_vista/screens/onboarding/forgotpasswordpage.dart';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_vista/screens/CustomHome/bottom_nav_bar.dart';
import 'package:my_vista/screens/ArtistHome/artist_bottom_nav.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  //Redirect userlogin
  Future<void> _redirectUserBasedOnRole(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    if (doc.exists) {
      String role = doc["role"];
      if (!mounted) return;

      if (role == "Artist") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ArtistRoundedBottomNavbar()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoundedBottomnavbar()),
        );
      }
    }
  }

  /// ✅ Email + Password Login
  Future<void> login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
            );

        String uid = userCredential.user!.uid;

        if (!mounted) return;
        log("✅ Login successful, navigating to ChooseRolePage...");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Login Successful ✅",
              style: TextStyle(color: Colors.black),
            ),
            backgroundColor: Color(0xffFDEBEC),
          ),
        );

        await _redirectUserBasedOnRole(uid);
      } on FirebaseAuthException catch (e) {
        log("❌ FirebaseAuth error: ${e.message}");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Login failed: ${e.message}",
              style: const TextStyle(color: Colors.black),
            ),
            backgroundColor: const Color(0xffFDEBEC),
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  /// ✅ Google Sign-In
  Future<void> signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
      await googleSignIn.signOut();
      log("Forced Google Sign-Out done.");
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      log("GoogleSignInAccount: $googleUser");

      if (googleUser == null) {
        log("Google sign-in cancelled by user.");
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      log(
        "Google auth tokens obtained: accessToken=${googleAuth.accessToken}, idToken=${googleAuth.idToken}",
      );

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken, // ✅ FIXED
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      log("✅ Firebase sign-in with Google credential successful.");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Signed in with Google ✅",
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Color(0xffFDEBEC),
        ),
      );

      await _redirectUserBasedOnRole(userCredential.user!.uid);
    } catch (e) {
      log("❌ Google sign-in error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Google sign-in failed: $e",
            style: const TextStyle(color: Colors.black),
          ),
          backgroundColor: const Color(0xffFDEBEC),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F4F4),
      appBar: AppBar(
        backgroundColor: const Color(0xffffffff),
        title: const Text(
          "Welcome Back",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xff930909),
          ),
        ),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Email",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xff930909),
                    ),
                  ),
                  SizedBox(
                    height: 60,
                    child: TextFormField(
                      controller: emailController,
                      validator: (value) =>
                          value!.isEmpty ? "Enter your email" : null,
                      decoration: InputDecoration(
                        hintText: "Email",
                        filled: true,
                        fillColor: const Color(0xffEDEDED),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Password",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xff930909),
                    ),
                  ),
                  SizedBox(
                    height: 60,
                    child: TextFormField(
                      controller: passwordController,
                      obscureText: !_isPasswordVisible,
                      validator: (value) =>
                          value!.isEmpty ? "Enter your password" : null,
                      decoration: InputDecoration(
                        hintText: "Your password",
                        filled: true,
                        fillColor: const Color(0xffEDEDED),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 18,
                          ),
                          onPressed: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordPage(),
                          ),
                        );
                      },
                      child: const Text(
                        "Forgot password?",
                        style: TextStyle(fontSize: 15, color: Colors.brown),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff930909),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                          : const Text(
                              "Sign In",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: const TextStyle(color: Colors.black),
                        children: [
                          TextSpan(
                            text: "Sign Up",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xff930909),
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SignupPage(),
                                  ),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[400])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "Or with",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[400])),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: signInWithGoogle,
                      icon: Image.asset(
                        "assets/images/google icon.png", // ✅ FIXED PATH
                        height: 20,
                      ),
                      label: const Text("Sign in with Google"),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
