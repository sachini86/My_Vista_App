import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:my_vista/screens/onboarding/successful_login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  String? _selectedRole;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> registration() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRole == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please select your role",
              style: TextStyle(color: Colors.black),
            ),
            backgroundColor: Color(0xffFDEBEC),
          ),
        );
        return; // stop here, don’t navigate
      }
      setState(() => _isLoading = true);

      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
            );
        String uid = userCredential.user!.uid; //get current user Id

        //save user data to firestore
        await FirebaseFirestore.instance.collection("users").doc(uid).set({
          "name": nameController.text.trim(),
          "email": emailController.text.trim(),
          "role": _selectedRole, // Artist or Buyer
          "createdAt": FieldValue.serverTimestamp(),
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Registration Successful ✅",
              style: TextStyle(color: Colors.black),
            ),
            backgroundColor: Color(0xffFDEBEC),
          ),
        );

        // Small delay so snackbar can be seen
        await Future.delayed(const Duration(microseconds: 300));

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SuccessfulLoginPage()),
        );
      } on FirebaseAuthException catch (e) {
        String message = "";
        if (e.code == 'weak-password') {
          message = "The password provided is too weak.";
        } else if (e.code == 'email-already-in-use') {
          message = "The account already exists for that email.";
        } else {
          message = "Error: ${e.message}";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xffFDEBEC),
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> signInWithGoogle() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please select your role",
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Color(0xffFDEBEC),
        ),
      );
      return; // stop here, don’t proceed
    }
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
        return; // User cancelled sign-in
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      log(
        "Google auth tokens: accessToken=${googleAuth.accessToken}, idToken=${googleAuth.idToken}",
      );

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.idToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      User? user = userCredential.user;
      if (user != null) {
        // Store user in Firestore if not already exists
        final doc = FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid);
        final snapshot = await doc.get();
        if (!snapshot.exists) {
          await doc.set({
            "name": user.displayName,
            "email": user.email,
            "role": _selectedRole ?? "Buyer", // default role
            "createdAt": FieldValue.serverTimestamp(),
          });
        }
      }

      await FirebaseAuth.instance.signInWithCredential(credential);
      log("Firebase sign-in with Google credential success");

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

      await Future.delayed(const Duration(microseconds: 300));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SuccessfulLoginPage()),
      );
    } catch (e) {
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
                    "Create your account",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Name
                  const Text(
                    "Name",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xff930909),
                    ),
                  ),
                  SizedBox(
                    height: 60,
                    child: TextFormField(
                      controller: nameController,
                      validator: (value) =>
                          value!.isEmpty ? "Enter your name" : null,
                      decoration: InputDecoration(
                        hintText: "Your name",
                        hintStyle: const TextStyle(fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xffEDEDED),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Email
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
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value!.isEmpty) return "Enter your email";
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return "Enter a valid email";
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: "Your email",
                        hintStyle: const TextStyle(fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xffEDEDED),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Password
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
                      validator: (value) {
                        if (value!.isEmpty) return "Enter your password";
                        if (value.length < 6) {
                          return "Password must be at least 6 characters";
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: "Your password",
                        hintStyle: const TextStyle(fontSize: 12),
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
                  const SizedBox(height: 1),

                  // Confirm Password
                  const Text(
                    "Confirm Password",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xff930909),
                    ),
                  ),
                  SizedBox(
                    height: 60,
                    child: TextFormField(
                      controller: confirmPasswordController,
                      obscureText: !_isPasswordVisible,
                      validator: (value) {
                        if (value!.isEmpty) return "Re-enter your password";
                        if (value != passwordController.text) {
                          return "Passwords do not match";
                        }
                        return null;
                      },

                      decoration: InputDecoration(
                        hintText: "Confirm password",
                        hintStyle: const TextStyle(fontSize: 12),
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
                  const SizedBox(height: 5),

                  // Your role
                  const Text(
                    "Your role",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xff930909),
                    ),
                  ),
                  const SizedBox(height: 1),
                  // dropdown for choosing role
                  DropdownButtonFormField(
                    value: _selectedRole,
                    decoration: InputDecoration(
                      hintText: "Select your role",
                      filled: true,
                      fillColor: const Color(0xffEDEDED),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide.none,
                      ),
                    ),

                    items: ["Artist", "Buyer"].map((role) {
                      return DropdownMenuItem(value: role, child: Text(role));
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedRole = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 30),
                  // Sign Up button
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : registration,
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
                              "Sign Up",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Already have account
                  Center(
                    child: RichText(
                      text: TextSpan(
                        text: "Already have an account? ",
                        style: const TextStyle(color: Colors.black),
                        children: [
                          TextSpan(
                            text: "Sign In",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xff930909),
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pushNamed(context, "/Sign In");
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Divider
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

                  // Google Sign in
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : signInWithGoogle,
                      icon: Image.asset(
                        "assets/images/google icon.png", // Fixed path
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
