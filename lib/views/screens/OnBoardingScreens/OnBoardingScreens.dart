import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pfe/utils/colors.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../widgets/OnboardingPage.dart';

class OnBoardingScreens extends StatefulWidget {
  const OnBoardingScreens({super.key});

  @override
  State<OnBoardingScreens> createState() => _OnBoardingScreensState();
}

class _OnBoardingScreensState extends State<OnBoardingScreens> {
  final PageController _pageController = PageController();
  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  currentPage = index;
                });
              },
              children: [
                OnboardingPage(
                  image: "images/OnBoardingScreensImages3.png",
                  text: 'Welcome to Transporter!'.tr,
                  description:
                  "Suivez vos livraisons en temps réel pour une visibilité totale à chaque étape.".tr,
                  pageIndex: 0,
                  pageController: _pageController,
                ),
                OnboardingPage(
                  image: "images/OnBoardingScreensImages2.png",
                  text: 'Discover the time!'.tr,
                  description:
                  "Optimisez vos itinéraires et gagnez en efficacité pour des livraisons toujours plus rapides.".tr,
                  pageIndex: 1,
                  pageController: _pageController,
                ),
                OnboardingPage(
                  image: "images/OnBoardingScreensImages1.png",
                  text: 'Best delivery!'.tr,
                  description:
                  "Gérez l'ensemble de vos opérations de livraison avec une solution intelligente et intuitive.".tr,
                  pageIndex: 2,
                  pageController: _pageController,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SmoothPageIndicator(
            controller: _pageController,
            count: 3,
            effect: ExpandingDotsEffect(
              dotHeight: screenHeight * 0.01,
              dotWidth: screenHeight * 0.01,
              activeDotColor: primaryColor,
              dotColor: Colors.white,
              expansionFactor: 3,
            ),
          ),
          SizedBox(height: screenHeight * 0.03),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}