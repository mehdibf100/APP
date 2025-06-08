import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pfe/utils/colors.dart';
import 'package:pfe/views/screens/OnBoardingScreens/chooseUser.dart';
import '../screens/auth/loginScreen.dart';


class OnboardingPage extends StatelessWidget {
  final String image;
  final String text;
  final String description;
  final int pageIndex;
  final PageController pageController;

  const OnboardingPage({
    Key? key,
    required this.image,
    required this.text,
    required this.description,
    required this.pageIndex,
    required this.pageController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Responsive Image
          Image.asset(
            image,
            width: screenWidth * 0.9,
            height: screenHeight * 0.5,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 20),
          Text(
            text,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: primaryColor,
              fontFamily: 'Urbanist-SemiBold',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              fontSize: 18,
              color: Colors.black,
              fontFamily: 'Urbanist-Regular',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: ()  {
      if (pageIndex == 2) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => Chooseuser()),
                  );}
      else { pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );}
              },

            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:[primaryColor,primaryColor],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Container(
                constraints: BoxConstraints(minWidth: 200, minHeight: 56),
                alignment: Alignment.center,
                child: Text(
                  pageIndex == 2 ? 'Get Started'.tr : 'Next'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}