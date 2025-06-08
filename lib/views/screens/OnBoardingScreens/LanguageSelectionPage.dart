import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pfe/views/screens/OnBoardingScreens/OnBoardingScreens.dart';
import 'package:pfe/utils/colors.dart';
import 'package:pfe/controllers/LanguageController.dart';

class LanguageSelectionScreen extends StatelessWidget {
  final LanguageController langController = Get.find();

  final List<Map<String, String>> languages = [
    {'name': 'English', 'native': 'English', 'flag': 'images/flags/English.png', 'code': 'en'},
    {'name': 'Arabic', 'native': 'العربية', 'flag': 'images/flags/Flag_of_Palestine.svg.webp', 'code': 'ar'},
    {'name': 'French', 'native': 'Français', 'flag': 'images/flags/French.png', 'code': 'fr'},
  ];

  LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title:  Center(
          child: Text(
            'Change Language'.tr,
            style: TextStyle(color: Colors.black, fontSize: 23, fontWeight: FontWeight.w500),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final language = languages[index];

                return Obx(() {
                  final isSelected = langController.selectedLanguage.value == language['code'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Image.asset(language['flag']!, width: 40, height: 40),
                      title: Text(
                        language['name']!,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        language['native']!,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: primaryColor, size: 24)
                          : Icon(Icons.check_circle_outline, color: Colors.grey.shade300, size: 24),
                      onTap: () {
                        langController.setLanguage(language['code']!);
                      },
                    ),
                  );
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  await langController.setLanguage(langController.selectedLanguage.value);
                  Get.offAll(() => OnBoardingScreens());
                },
                child:  Text(
                  "Save".tr,
                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}