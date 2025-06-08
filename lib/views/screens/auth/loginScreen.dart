import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:pfe/services/userService.dart';
import 'package:pfe/utils/colors.dart';
import 'package:pfe/views/screens/OnBoardingScreens/chooseUser.dart';
import 'package:pfe/views/screens/auth/ForgotPassword.dart';
import 'package:pfe/views/screens/transporter/TransporterHomePage.dart';
import 'package:pfe/views/screens/user/UserHomePage.dart';
import 'package:pfe/views/screens/auth/SingupScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/auth_service.dart';
import '../../widgets/SuccessDialog.dart';

class Loginscreen extends StatefulWidget {
  const Loginscreen({super.key});

  @override
  State<Loginscreen> createState() => _LoginscreenState();
}

class _LoginscreenState extends State<Loginscreen> {
  String _selectedRole = 'USER';
  bool isLoading = false;

  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  bool _passwordVisible = false;
  final UserService userService = UserService();
  final AuthService _auth_service= AuthService();


  @override
  void initState() {
    super.initState();
    _isFirstTime();
    _loadSelectedRole();
  }

  Future<void> _isFirstTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
  }
  Future<void> _loadSelectedRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedRole = prefs.getString('selectedRole') ?? 'USER';
    });
  }
  signInWithGoogle(){}

  void _handleLogin() async {
    String userEmail = email.text.trim();
    String userPassword = password.text.trim();
    setState(() => isLoading = true);

    if (userEmail.isEmpty || userPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs")),
      );
      setState(() => isLoading = false);
      return;
    }

    bool loginSuccess = await userService.signIn(userEmail, userPassword);

    if (loginSuccess) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token != null) {
        Map<String, dynamic> payload = Jwt.parseJwt(token);
        String role = payload['role'] ?? "USER";
        prefs.setString('userId',payload['id'].toString());
        if(role==_selectedRole){
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return SuccessDialog(
              onGoToHomepage: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => role == "USER"
                        ? UserHomepage(userEmail: payload['sub'],userId:payload['id'])
                        :  TransporterHomePage(userEmail: payload['sub'],userId:payload['id']),
                  ),
                );
              },
            );
          },
        );
        }
        else {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Échec de la connexion, vérifiez vos informations.")),
          );
        }
      }
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Échec de la connexion, vérifiez vos informations.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(
                "Login to your \nAccount.".tr,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.23,
                child: Image.asset("images/loginImage.png"),
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: email,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined),
                  hintText: 'Email'.tr,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: password,
                obscureText: !_passwordVisible,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                  hintText: 'Password'.tr,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      :  Text(
                    'Sign In'.tr,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const Forgetpassword(),
                    ),
                  );
                },
                child:  Text(
                  'Forgot the password?'.tr,
                  style: TextStyle(
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
               Center(
                child: Text(
                  'or continue with'.tr,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _socialButton('images/facebook.png',signInWithGoogle),
                  _socialButton('images/google.png',signInWithGoogle),
                  _socialButton('images/apple.png',signInWithGoogle),
                ],
              ),
              const SizedBox(height: 10),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Text("Don't have an account?".tr),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const Signupscreen(),
                          ),
                        );
                      },
                      child:  Text(
                        'Sign up'.tr,
                        style: TextStyle(
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const Chooseuser(),
                    ),
                  );
                },
                child:  Text(
                  'Choose User'.tr,
                  style: TextStyle(
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialButton(String iconPath, Function onPressed) {
    return GestureDetector(
      onTap:()async {
        print("google Signin Redy".tr);
          String? token = await _auth_service.signInWithGoogle();
          if (token != null) {
            Navigator.pushReplacementNamed(context, "/home");
          }
        },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Image.asset(
          iconPath,
          height: 24,
          width: 24,
        ),
      ),
    );
  }
}
