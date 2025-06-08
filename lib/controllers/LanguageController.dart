import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends GetxController {
  var selectedLanguage = 'en'.obs;

  @override
  void onInit() {
    super.onInit();
    loadLanguage();
  }

  Future<void> setLanguage(String langCode) async {
    selectedLanguage.value = langCode;

    Get.updateLocale(Locale(langCode));

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', langCode);
  }

  Future<void> loadLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? langCode = prefs.getString('language');

    if (langCode != null) {
      selectedLanguage.value = langCode;
      Get.updateLocale(Locale(langCode));
    }
  }
}