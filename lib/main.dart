import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pfe/services/NotificationService.dart';
import 'package:pfe/services/WebSocketService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pfe/utils/AppTranslations.dart';
import 'package:pfe/views/screens/OnBoardingScreens/FirstScreen.dart';
import 'package:pfe/views/screens/auth/LoginScreen.dart';
import 'package:pfe/views/screens/user/UserHomePage.dart';
import 'package:pfe/views/screens/transporter/TransporterHomePage.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'controllers/LanguageController.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  NotificationService.initialize();

  await Permission.notification.request();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstTime = prefs.getBool('isFirstTime') ?? true;
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  String? token = prefs.getString('token');
  Get.put(LanguageController());

  final LanguageController langController = Get.find<LanguageController>();
  await langController.loadLanguage();
  String role = "USER";
  String userEmail = "";
  String userId="";

  if (token != null) {
    try {
      Map<String, dynamic> payload = Jwt.parseJwt(token);
      role = payload['role'] ?? "USER";
      userEmail = payload['sub'] ?? "";
      print("userId:"+payload['id']);
      userId = payload['id'];
    } catch (e) {
      print("Error decoding JWT: $e");
    }
  }

  if (userId != null) {
    WebSocketService webSocketService = WebSocketService(userId);
    webSocketService.connect();
  }

  runApp(MyApp(
    isFirstTime: isFirstTime,
    isLoggedIn: isLoggedIn,
    role: role,
    userEmail: userEmail,
    userId: userId,
  ));
}

class MyApp extends StatelessWidget {
  final bool isFirstTime;
  final bool isLoggedIn;
  final String role;
  final String userEmail;
  final String userId;
  const MyApp({
    super.key,
    required this.isFirstTime,
    required this.isLoggedIn,
    required this.role,
    required this.userEmail,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'PFE Project',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),
        ),
        bottomAppBarTheme: const BottomAppBarTheme(
          color: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
        ),
      ),
      debugShowCheckedModeBanner: false,
      translations: AppTranslations(),
      locale: Locale(Get.find<LanguageController>().selectedLanguage.value),
      fallbackLocale: const Locale('en', 'US'),
      home: isFirstTime
          ? const FirstScreen()
          : isLoggedIn
          ? (role == "USER"
          ? UserHomepage(userEmail: userEmail, userId: userId,)
          : TransporterHomePage(userEmail: userEmail,userId:userId))
          : const Loginscreen(),
    );
  }
}
