import 'package:flutter/material.dart';
import 'package:vista/constant/colors.dart';
import 'package:vista/data/onboarding_data.dart';
import 'package:vista/screens/onboarding/front_page.dart';
import 'package:vista/screens/onboarding/shared_onboarding.dart'
    show SharedOnboardingScreen;
import 'package:vista/widgets/custom_button.dart';

class OnboardingScreens extends StatefulWidget {
  const OnboardingScreens({super.key});

  @override
  State<OnboardingScreens> createState() => _OnboardingScreensState();
}

class _OnboardingScreensState extends State<OnboardingScreens> {
  final PageController _pageController = PageController();
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
                    Container(color: Colors.red),
                  ],
                ),

                if (_currentpage == 1) ...[
                  Positioned(
                    bottom: 200,
                    left: 20,
                    right: 20,
                    child: CustomButton(
                      buttonName: "Log In",
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 100,
                    left: 20,
                    right: 20,
                    child: CustomButton(
                      buttonName: "Register",
                      onPressed: () {
                        Navigator.pushNamed(context, '/Register');
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
