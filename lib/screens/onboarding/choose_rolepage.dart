import 'package:flutter/material.dart';

// Dummy pages for navigation
class ArtistHomePage extends StatelessWidget {
  const ArtistHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("🎨 Artist Home Page")));
  }
}

class BuyerHomePage extends StatelessWidget {
  const BuyerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("🛒 Buyer Home Page")));
  }
}

class ChooseRolePage extends StatefulWidget {
  const ChooseRolePage({super.key});

  @override
  State<ChooseRolePage> createState() => _ChooseRolePageState();
}

class _ChooseRolePageState extends State<ChooseRolePage> {
  String? selectedRole; // to store selected role

  void _onContinue() {
    if (selectedRole == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please choose a role")));
      return;
    }

    // Navigate to correct HomePage
    if (selectedRole == "artist") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ArtistHomePage()),
      );
    } else if (selectedRole == "buyer") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BuyerHomePage()),
      );
    }
  }

  Widget _roleCard({
    required String role,
    required String title,
    required String subtitle,
    required String iconPath,
  }) {
    final isSelected = selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRole = role;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.shade50 : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xff930909) : Colors.black,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(iconPath, height: 70),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xff930909),
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Logo
                Image.asset("assests/images/vist (2) (1).png", width: 280),

                const Text(
                  "Choose Your Role",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff930909),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Choose whether you're an artist ready to showcase your work, or a buyer looking to discover and purchase unique art.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xff000000),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                // Role Options
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _roleCard(
                        role: "artist",
                        title: "I am an Artist",
                        subtitle: "Showcase and sell art",
                        iconPath: "assests/images/Artists Palette Durham.png",
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _roleCard(
                        role: "buyer",
                        title: "I am a Buyer",
                        subtitle: "Discover and collect art",
                        iconPath:
                            "assests/images/Checkout free icons designed by Flat Icons.png",
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // Continue button
                SizedBox(
                  height: 50,
                  width: 350,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff930909),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _onContinue,
                    child: const Text(
                      "Continue",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
