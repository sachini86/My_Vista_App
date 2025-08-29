import 'package:flutter/material.dart';
import 'package:my_vista/data/onboarding_data.dart';
import 'package:my_vista/screens/onboarding/front_page.dart';
import 'package:my_vista/screens/onboarding/shared_onboarding.dart'
    show SharedOnboardingScreen;
import 'package:my_vista/widgets/custom_button.dart';

class OnboardingScreens extends StatefulWidget {
  const OnboardingScreens({super.key});

  @override
  State<OnboardingScreens> createState() => _OnboardingScreensState();
}

class _OnboardingScreensState extends State<OnboardingScreens> {
  final PageController _pageController = PageController();
  bool showDetailsPage = false;
  int _currentpage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                //onboarding screens
                PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentpage = index;
                    });
                  },
                  children: [
                    const FrontPage(),
                    SharedOnboardingScreen(
                      title: OnboardingData.onboardingDataList[0].title,
                      imagePath: OnboardingData.onboardingDataList[0].imagePath,
                      description:
                          OnboardingData.onboardingDataList[0].description,
                    ),
                  ],
                ),

                if (_currentpage == 1) ...[
                  Positioned(
                    bottom: 200,
                    left: 70,
                    right: 70,
                    height: 55,
                    child: CustomButton(
                      buttonName: "Sign In",

                      // fontSize: 22, // Removed or replace with the correct parameter if available
                      onPressed: () {
                        Navigator.pushNamed(context, '/Sign In');
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 100,
                    left: 70,
                    right: 70,
                    height: 55,
                    child: CustomButton(
                      buttonName: "Sign Up",

                      onPressed: () {
                        Navigator.pushNamed(context, '/Sign Up');
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
