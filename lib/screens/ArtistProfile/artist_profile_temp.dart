import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:developer';

class ArtistProfile extends StatefulWidget {
  const ArtistProfile({super.key});

  @override
  State<ArtistProfile> createState() => _ArtistProfileState();
}

class _ArtistProfileState extends State<ArtistProfile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? user;
  Map<String, dynamic>? userData;
  List<String> paymentMethods = [];
  late Stream<DocumentSnapshot<Map<String, dynamic>>> userStream;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    if (user != null) {
      userStream = _firestore.collection('users').doc(user!.uid).snapshots();
      userStream.listen((doc) {
        setState(() {
          userData = doc.data();
          paymentMethods = List<String>.from(userData?['paymentMethods'] ?? []);
        });
      });
    }
  }

  Future<void> _updateUserData(String field, dynamic value) async {
    if (user != null) {
      await _firestore.collection('users').doc(user!.uid).update({
        field: value,
      });
    }
  }

  Future<void> _addPaymentMethod(String method) async {
    if (user != null) {
      paymentMethods.add(method);
      await _firestore.collection('users').doc(user!.uid).update({
        'paymentMethods': paymentMethods,
      });
    }
  }

  Future<void> _removePaymentMethod(String method) async {
    if (user != null) {
      paymentMethods.remove(method);
      await _firestore.collection('users').doc(user!.uid).update({
        'paymentMethods': paymentMethods,
      });
    }
  }

  Future<void> _signOut() async {
    try {
      if (user != null) {
        // Optional: delete Firestore user doc (check your rules)
        await _firestore.collection('users').doc(user!.uid).delete();

        // Sign out Firebase Auth
        await _auth.signOut();

        if (!mounted) return;

        // Navigate to onboarding screen
        Navigator.of(context).pushReplacementNamed('/SharedOnboardingScreen');
      }
    } catch (e) {
      log('Sign out error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
    }
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Sign Out'),
        content: const Text(
          'Are you sure you want to sign out? All your data will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(String field, String currentValue) {
    TextEditingController controller = TextEditingController(
      text: currentValue,
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit $field'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: field,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newValue = controller.text;
              Navigator.pop(context);
              await _updateUserData(field, newValue);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editProfilePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && user != null) {
      File file = File(image.path);
      try {
        // Upload image to Firebase Storage
        Reference ref = _storage.ref().child('profile_pics/${user!.uid}.jpg');
        await ref.putFile(file);
        String photoUrl = await ref.getDownloadURL();

        // Update Firestore
        await _updateUserData('photoUrl', photoUrl);
      } catch (e) {
        // Handle error
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload photo: $e')));
      }
    }
  }

  void _showAddPaymentDialog() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Payment Method'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Card/PayPal'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _addPaymentMethod(controller.text);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff930909),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 50),
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(
                    userData!['photoUrl'] ?? 'https://via.placeholder.com/150',
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _editProfilePhoto,
                    child: const CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.black,
                      child: Icon(Icons.edit, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            ListTile(
              title: const Text(
                'Name',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              subtitle: Text(
                userData!['name'] ?? 'User',
                style: const TextStyle(fontSize: 16),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.black),
                onPressed: () =>
                    _showEditDialog('name', userData!['name'] ?? ''),
              ),
            ),
            const Divider(),

            ListTile(
              title: const Text(
                'Email',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              subtitle: Text(
                userData!['email'] ?? '',
                style: const TextStyle(fontSize: 16),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.black),
                onPressed: () =>
                    _showEditDialog('email', userData!['email'] ?? ''),
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text(
                'Payment Methods',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: paymentMethods.map((method) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(method),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Color(0xff930909),
                        ),
                        onPressed: () => _removePaymentMethod(method),
                      ),
                    ],
                  );
                }).toList(),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.add, color: Colors.black),
                onPressed: _showAddPaymentDialog,
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xff930909)),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: Color(0xff930909)),
              ),
              onTap: _confirmSignOut,
            ),
          ],
        ),
      ),
    );
  }
}
