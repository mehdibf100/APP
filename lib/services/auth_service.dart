import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final response = await http.post(
        Uri.parse("http://localhost:8081/api/v1/auth/google"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": googleUser.email}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final token = responseData["token"];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", token);

        return token;
      } else {
        return null;
      }
    } catch (e) {
      print("Erreur d'authentification : $e");
      return null;
    }
  }
}
