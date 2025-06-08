import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pfe/utils/api_const.dart';
import 'package:pfe/services/userService.dart';
import 'package:pfe/views/screens/auth/loginScreen.dart';

import '../../widgets/SignInButtonWidget.dart';

class ProfileScreen extends StatefulWidget {
  final String Useremail;
  const ProfileScreen({Key? key, required this.Useremail}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userService = UserService();
  final _formKey = GlobalKey<FormState>();

  final _nameController  = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = true;
  String _imageUrl = '';
  String _userName = '';

  late Map<String, dynamic> _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final resp = await http.get(
        Uri.parse('${ApiConst.getUserByEmailApi}/${widget.Useremail}'),
      );
      if (resp.statusCode != 200) {
        throw Exception('Status code: ${resp.statusCode}');
      }

      // 1) Decode JSON en Map typé
      final Map<String, dynamic> data = jsonDecode(resp.body);
print(data);
      // 2) Récupère tes champs
      final name     = data['name']    as String? ?? '';
      final email    = data['email']   as String? ?? '';
      final phoneNum = data['phone']   .toString();
      final imageUrl = data['imageUrl'] as String? ?? '';

      setState(() {
        _userData = data;
        _userName  = name;
        _imageUrl  = imageUrl;

        _nameController.text  = name;
        _emailController.text = email;
        _phoneController.text = phoneNum;

        _isLoading = false;
      });
    } catch (e) {
      // Affiche l'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement profil : $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedData = {
      'name':  _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
    };

    try {
      setState(() => _isLoading = true);
      await _userService.updateUser(_userData['id'].toString(), updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur mis à jour !')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur mise à jour : $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const Loginscreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout))
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              CircleAvatar(
                radius: 60,
                backgroundImage: _imageUrl.isNotEmpty
                    ? NetworkImage(_imageUrl)
                    : const AssetImage(
                    'images/profile.png')
                as ImageProvider,
              ),
              const SizedBox(height: 16),
              Text(
                _userName.isNotEmpty ? _userName : 'Utilisateur',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),

              // Nom
              TextFormField(
                controller: _nameController,
                decoration: _buildDecoration(
                    hint: 'Nom', icon: Icons.person_outline),
                validator: (v) =>
                v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 20),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: _buildDecoration(
                    hint: 'Email', icon: Icons.email_outlined),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Requis';
                  }
                  final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(v)) {
                    return 'Email invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Téléphone
              TextFormField(
                controller: _phoneController,
                decoration: _buildDecoration(
                    hint: 'Téléphone', icon: Icons.phone_android),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Requis';
                  }
                  if (!RegExp(r'^\d{8}$').hasMatch(v)) {
                    return '8 chiffres requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Bouton Update
              SignInButtonWidget(
                text: 'Mettre à jour',
                onPressed: _updateUser,
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildDecoration(
      {required String hint, required IconData icon}) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.blue),
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
    );
  }
}
