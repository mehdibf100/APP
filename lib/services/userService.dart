import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import 'package:pfe/utils/api_const.dart';
import 'package:pfe/views/screens/auth/LoginScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../views/screens/auth/UpdatePassword.dart';
import '../views/screens/auth/VerifyResetCodePage.dart';

class UserService {
  Future<bool> signIn(String email, String password) async {
    var client = http.Client();
    try {
      var url = Uri.parse(ApiConst.signInApi);

      var response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        var decodedResponse = jsonDecode(response.body);
        String token = decodedResponse['token'];
        Map<String, dynamic> payload = Jwt.parseJwt(token);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setBool('isLoggedIn', true);

        print('Login Successful: $payload');
        return true;
      } else {
        print('Login Failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error: $e');
      return false;
    } finally {
      client.close();
    }
  }
  Future<Map<String, dynamic>> signup({
    required String username,
    required int phone,
    required String email,
    required String role,
    required String password,
    File? identityCardImage,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse(ApiConst.signUpApi));
    request.fields['username'] = username;
    request.fields['phone'] = phone.toString();
    request.fields['email'] = email;
    request.fields['role'] = role;
    request.fields['password'] = password;

    if (role == 'TRANSPORTEUR' && identityCardImage != null) {
      request.files.add(await http.MultipartFile.fromPath('identityCardImage', identityCardImage.path));
    }

    try {
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (responseData.isEmpty) {
        return {'success': false, 'message': 'Empty response from server'};
      }

      final jsonData = jsonDecode(responseData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': jsonData['message'] ?? 'Account created successfully.'
        };
      } else if (response.statusCode == 413) {
        return {
          'success': false,
          'message': jsonData['error'] ?? 'File size exceeds the maximum limit.'
        };
      } else {
        return {
          'success': false,
          'message': jsonData['error'] ?? 'Signup failed.'
        };
      }
    } on FormatException catch (e) {
      return {'success': false, 'message': 'Invalid JSON response: $e'};
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }
   Future<void> sendEmail(String email, BuildContext context) async {
    final String apiUrl =ApiConst.forgetPasswordApi;

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        print('Email sent successfully: ${response.body}');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Check your email for further instructions.")),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => VerifyResetCodePage(email: email,)));
      } else {
        final errorResponse = jsonDecode(response.body);
        String errorMessage = errorResponse['message'] ?? 'Failed to send email';
        print('Failed to send email: $errorMessage (status: ${response.statusCode})');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print('Error during sending email: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again later.')),
      );
    }
  }
  Future<void> validCode(String code, String email,BuildContext context) async {
    final String apiUrl = "${ApiConst.validCodeApi}?otpCode=$code";

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        final String message = response.body;
        print('✅ Code validé : $message');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ $message. Veuillez réinitialiser votre mot de passe.")),
        );

        Future.delayed(Duration(seconds: 1), () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => UpdatePasswordScreen(email:email)));
        });
      } else {
        final String errorMessage = response.body.isNotEmpty ? response.body : 'Code invalide';
        print('❌ Erreur: $errorMessage (status: ${response.statusCode})');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ $errorMessage")),
        );
      }
    } catch (e) {
      print('🚨 Erreur réseau : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Erreur de connexion. Veuillez réessayer.')),
      );
    }
  }
  Future<void> updatePassword(String email, String password, BuildContext context) async {
    final String apiUrl = "${ApiConst.updatePasswordByEmailApi}?email=$email&newPassword=$password";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({'email': email, 'newPassword': password}),
      );

      if (response.statusCode == 200) {
        print('Password updated successfully: ${response.body}');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password updated successfully.")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Loginscreen()),
        );
      } else {
        print('Failed with email: $email');
        print('Response: ${response.body}');

        final errorResponse = jsonDecode(response.body);
        String errorMessage = errorResponse['error'] ?? 'Failed to update password';

        print('Failed to update password: $errorMessage (status: ${response.statusCode})');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print('Error during password update: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again later.')),
      );
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> updatedUser) async {
    final String url = ApiConst.updateUserByIdApi+"/$userId";

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updatedUser),
      );

      if (response.statusCode == 200) {
        print("Utilisateur mis à jour avec succès !");
      } else {
        throw Exception("Erreur de mise à jour : ${response.body}");
      }
    } catch (e) {
      throw Exception("Échec de la mise à jour : $e");
    }
  }
  Future<Map<String, dynamic>> getUserById(String userId) async {
    final response = await http.get(Uri.parse('${ApiConst.getAllUsersApi}/id/$userId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors du chargement de l\'utilisateur');
    }
  }
}