import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Pour MediaType
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart'; // Pour lookupMimeType
import 'package:shared_preferences/shared_preferences.dart';

import '../../../utils/api_const.dart';
import '../../../utils/colors.dart';
import 'LoginScreen.dart';




class Signupscreen extends StatefulWidget {
  const Signupscreen({Key? key}) : super(key: key);

  @override
  State<Signupscreen> createState() => _SignupscreenState();
}

class _SignupscreenState extends State<Signupscreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String _selectedRole = 'USER';
  bool isLoading = false; // Pour le chargement de l'inscription générale
  bool _isValidatingID = false; // Pour le chargement spécifique de la validation Gemini

  File? _identityImage;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadSelectedRole();
  }

  @override
  void dispose() {
    // Libérez les contrôleurs lorsque le widget est supprimé
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }


  Future<void> _loadSelectedRole() async {
    final prefs = await SharedPreferences.getInstance();
    // Assurez-vous que le widget est toujours monté avant d'appeler setState
    if(mounted) {
      setState(() {
        _selectedRole = prefs.getString('selectedRole') ?? 'USER';
      });
    }
  }

  Future<void> _pickIdentityImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() => _identityImage = File(picked.path));
    }
  }
  Future<void> _pickIdentityProfileImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  // --- Fonction de Validation avec Gemini ---
  Future<bool> validateIdentityCardWithGemini(File userImage) async {
    if (!mounted) return false; // Vérifie si le widget est toujours là
    setState(() {
      _isValidatingID = true;
    });


    const String apiKey = "AIzaSyAyehqyTPRwvm8AfO-LoQZuz_7m7nwnOac";

    if (apiKey != apiKey) {
      print("ERREUR: Veuillez remplacer 'VOTRE_CLE_API_GEMINI_ICI' par votre clé réelle.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Erreur de configuration : Clé API manquante."))
        );
        setState(() => _isValidatingID = false);
      }
      return false;
    }


    // 1. Charger l'image d'exemple depuis les assets
    final String exampleImagePath = 'images/cartIdentity.jpg'; // Adaptez si nécessaire
    String exampleBase64;
    String exampleMimeType = 'image/png'; // Adaptez si c'est un autre type
    try {
      final ByteData exampleByteData = await rootBundle.load(exampleImagePath);
      exampleBase64 = base64Encode(exampleByteData.buffer.asUint8List());
    } catch (e) {
      print("Erreur lors du chargement de l'image d'exemple: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Impossible de charger l'image d'exemple: $e"))
        );
        setState(() => _isValidatingID = false);
      }
      return false;
    }


    // 2. Lire l'image de l'utilisateur et la convertir en base64
    final List<int> userImageBytes = await userImage.readAsBytes();
    final String userBase64 = base64Encode(userImageBytes);
    final String? userMimeType = lookupMimeType(userImage.path);

    if (userMimeType == null || !userMimeType.startsWith('image/')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Type de fichier d'identité invalide."))
        );
        setState(() => _isValidatingID = false);
      }
      return false;
    }

    // 3. Construire la requête pour l'API Gemini
    // Utilisez gemini-1.5-flash-latest ou gemini-pro-vision ou gemini-1.5-pro-latest
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$apiKey');

    final requestBody = jsonEncode({
      "contents": [
        {
          "parts": [
            {
              "text": "Compare ces deux images. La seconde image (fournie par l'utilisateur) semble-t-elle être une carte d'identité valide, similaire en format et structure générale à la première image (l'exemple) ? Ignore le texte spécifique, concentre-toi sur la mise en page et le type de document. Réponds uniquement par OUI ou NON."
            },
            {
              "inline_data": {
                "mime_type": exampleMimeType,
                "data": exampleBase64
              }
            },
            {
              "inline_data": {
                "mime_type": userMimeType,
                "data": userBase64
              }
            }
          ]
        }
      ],
      "generationConfig": { // Optionnel mais recommandé pour une réponse courte
        "candidateCount": 1,
        "maxOutputTokens": 10, // Juste assez pour OUI ou NON
        "temperature": 0.1, // Moins créatif, plus déterministe
        "topP": 0.1,
      },
      "safetySettings": [ // Optionnel: ajuster les filtres de sécurité si nécessaire
        {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
        {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
        {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
        {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"}
      ]
    });

    try {
      // 4. Envoyer la requête
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      // 5. Analyser la réponse
      if (!mounted) return false; // Re-vérifier si le widget est toujours là après l'appel async

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Vérifier la structure de la réponse prudemment
        if (responseData.containsKey('candidates') &&
            responseData['candidates'] is List &&
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0].containsKey('content') &&
            responseData['candidates'][0]['content'].containsKey('parts') &&
            responseData['candidates'][0]['content']['parts'] is List &&
            responseData['candidates'][0]['content']['parts'].isNotEmpty &&
            responseData['candidates'][0]['content']['parts'][0].containsKey('text'))
        {
          final String textResponse = responseData['candidates'][0]['content']['parts'][0]['text'].trim().toUpperCase();
          print('Réponse Gemini: $textResponse'); // Pour le débogage

          if (textResponse.contains("OUI")) { // Un peu plus flexible que == "OUI"
            setState(() => _isValidatingID = false);
            return true; // L'image semble valide
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Format de la carte d'identité non reconnu par l'IA."))
            );
            setState(() => _isValidatingID = false);
            return false; // L'image n'est pas valide
          }
        } else {
          // La structure de la réponse n'est pas celle attendue
          print('Structure de réponse Gemini inattendue: ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Réponse inattendue de l'IA."))
          );
          setState(() => _isValidatingID = false);
          return false;
        }

      } else {
        // Gérer les erreurs API (mauvaise clé, quota dépassé, etc.)
        print('Erreur API Gemini: ${response.statusCode}');
        print('Corps de la réponse: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur validation image (${response.statusCode}). Vérifiez la clé API et les quotas."))
        );
        setState(() => _isValidatingID = false);
        return false;
      }
    } catch (e) {
      print("Exception lors de l'appel à Gemini: $e");
          if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur réseau lors de la validation: $e"))
        );
        setState(() => _isValidatingID = false);
      }
      return false;
    }
  }


  // --- Fonction _signup modifiée ---
  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == 'TRANSPORTEUR' && _identityImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Choisissez une carte d'identité.")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final uri = Uri.parse(ApiConst.signUpApi);
      final req = http.MultipartRequest('POST', uri);

      // 1️⃣ DTO JSON
      final dto = {
        'email':   _emailController.text.trim(),
        'name':    _usernameController.text.trim(),
        'phone':   int.parse(_phoneController.text.trim()),
        'password': _passwordController.text.trim(),
        'role': _selectedRole,
      };
      req.files.add(http.MultipartFile.fromString(
        'user', jsonEncode(dto),
        contentType: MediaType('application', 'json'),
      ));

      // 2️⃣ profileImage → Cloudinary
      if (_profileImage != null) {
        final mimeType = lookupMimeType(_profileImage!.path)!;
        final stream   = http.ByteStream(_profileImage!.openRead());
        final length   = await _profileImage!.length();
        req.files.add(http.MultipartFile(
          'profileImage', stream, length,
          filename: _profileImage!.path.split('/').last,
          contentType: MediaType.parse(mimeType),
        ));
      }

      // 3️⃣ identityCard → stockage local
      if (_identityImage != null) {
        final mimeType = lookupMimeType(_identityImage!.path)!;
        final stream   = http.ByteStream(_identityImage!.openRead());
        final length   = await _identityImage!.length();
        req.files.add(http.MultipartFile(
          'identityCard', stream, length,
          filename: _identityImage!.path.split('/').last,
          contentType: MediaType.parse(mimeType),
        ));
      }

      final resp = await req.send();
      final body = await resp.stream.bytesToString();

      if (resp.statusCode == 201) {
        final data = jsonDecode(body);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'])));
        // Ici data['imageUrl'] te donne déjà l'URL Cloudinary
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Loginscreen()));
      } else {
        final error = jsonDecode(body)['message'] ?? 'Erreur';
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Échec: $error")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Exception: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 SizedBox(height: 32),
                 Text(
                  'Create your\nAccount'.tr,
                  style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 48),
                // Username
                TextFormField(
                  controller: _usernameController,
                  decoration: _inputDecoration('Username'.tr, Icons.person_outline),
                  validator: (v) => v == null || v.isEmpty ? 'Enter a username'.tr : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration('Phone'.tr, Icons.phone_outlined),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter a phone number'.tr;
                    if (int.tryParse(v) == null) return 'Enter a valid phone number'.tr;
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('Email'.tr, Icons.email_outlined),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter an email'.tr;
                    // Simple email validation regex
                    bool emailValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(v);
                    if (!emailValid) return 'Enter a valid email'.tr;
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                // VERSION SIMPLE ET MODERNE
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _profileImage != null ? Colors.green : Colors.grey.shade300,
                    ),
                    color: _profileImage != null ? Colors.green.shade50 : Colors.grey.shade50,
                  ),
                  child: Row(
                    children: [
                      // Avatar circulaire
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                        child: _profileImage == null
                            ? Icon(Icons.person, color: Colors.grey.shade500, size: 24)
                            : null,
                      ),

                      const SizedBox(width: 12),

                      // Bouton
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue.shade700,
                            elevation: 0,
                            side: BorderSide(color: Colors.blue.shade200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: (_isValidatingID || isLoading) ? null : _pickIdentityProfileImage,
                          icon: _isValidatingID
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : Icon(
                            _profileImage != null ? Icons.edit : Icons.add_a_photo,
                            size: 18,color: primaryColor,
                          ),
                          label: Text(
                            _profileImage != null ? 'Modifier'.tr : 'Ajouter photo'.tr,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),

                      // Icône de validation
                      if (_profileImage != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12,height: 15,),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _inputDecoration('Password'.tr, Icons.lock_outline),
                  validator: (v) => v == null || v.length < 6 ? 'Password must be 6+ characters'.tr : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: _inputDecoration('Confirm Password'.tr, Icons.lock_outline),
                  validator: (v) => v != _passwordController.text ? 'Passwords do not match'.tr : null,
                  textInputAction: TextInputAction.done, // Last field
                ),
                const SizedBox(height: 16),

// Upload carte identité si transporteur
                if (_selectedRole == 'TRANSPORTEUR') ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _identityImage != null ? Colors.green : Colors.grey.shade300,
                      ),
                      color: _identityImage != null ? Colors.green.shade50 : Colors.grey.shade50,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Icône de document
                            Container(
                              width: 48,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Icon(
                                _identityImage != null ? Icons.credit_card : Icons.credit_card_outlined,
                                color: _identityImage != null ? Colors.green.shade600 : Colors.grey.shade500,
                                size: 20,

                              ),
                            ),

                            const SizedBox(width: 12),

                            // Bouton
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.blue.shade700,
                                  elevation: 0,
                                  side: BorderSide(color: Colors.blue.shade200),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: (_isValidatingID || isLoading) ? null : _pickIdentityImage,
                                icon: _isValidatingID
                                    ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                                    : Icon(
                                  _identityImage != null ? Icons.edit : Icons.add_photo_alternate,
                                  size: 18,
                                  color: primaryColor,
                                ),
                                label: Text(
                                  _identityImage != null ? 'Modifier'.tr: 'Carte d\'identité'.tr,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),

                            // Icône de validation
                            if (_identityImage != null) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.check_circle, color: Colors.green, size: 20),
                            ],
                          ],
                        ),

                        // Prévisualisation de l'image
                        if (_identityImage != null) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.file(
                              _identityImage!,
                              height: 80,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    height: 80,
                                    width: double.infinity,
                                    color: Colors.grey.shade200,
                                    child:  Center(
                                      child: Text(
                                        "Erreur d'affichage".tr,
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Sign up button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (isLoading || _isValidatingID) ? null : _signup, // Désactive pendant l'une ou l'autre opération
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white, // Texte en blanc
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                    child: (isLoading || _isValidatingID)
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        :  Text('Sign up'.tr),
                  ),
                ),
                const SizedBox(height: 24),
                // Link to Sign in
                Row( // Center the row content
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Text('Already have an account?'.tr),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const Loginscreen()),
                      ),
                      child:  Text('Sign in'.tr, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper pour la décoration des inputs
  InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
    prefixIcon: Icon(icon, color: Colors.grey.shade500),
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade500),
    filled: true,
    fillColor: Colors.grey.shade100,
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none, // Pas de bordure par défaut
    ),
    enabledBorder: OutlineInputBorder( // Bordure quand inactif
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
    ),
    focusedBorder: OutlineInputBorder( // Bordure quand actif
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: primaryColor, width: 1.5),
    ),
    errorBorder: OutlineInputBorder( // Bordure en cas d'erreur
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 1.0),
    ),
    focusedErrorBorder: OutlineInputBorder( // Bordure en cas d'erreur et actif
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    ),
  );
}