import 'package:flutter/material.dart';
import 'package:pfe/utils/colors.dart';
import '../../../services/userService.dart';
import '../../widgets/HeaderWidget.dart';

class VerifyResetCodePage extends StatefulWidget {
  final String email;
  const VerifyResetCodePage({super.key, required this.email});

  @override
  State<VerifyResetCodePage> createState() => _VerifyResetCodePageState();
}

class _VerifyResetCodePageState extends State<VerifyResetCodePage> {
  final List<TextEditingController> _controllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  final UserService userService = UserService();

  void _submitCode() {
    String code = _controllers.map((c) => c.text).join();

    if (code.length == 4) {
      print("Code entré: $code");
      userService.validCode(code,widget.email, context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un code valide à 4 chiffres')),
      );
    }
  }

  Widget _buildCodeField(int index) {
    return SizedBox(
      width: 50,
      height: 60,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        maxLength: 1,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
        decoration: InputDecoration(
          counterText: "",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: primaryColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: primaryColor, width: 2.0),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 3) {
            FocusScope.of(context).requestFocus(_focusNodes[index + 1]); // Aller au champ suivant
          } else if (value.isEmpty && index > 0) {
            FocusScope.of(context).requestFocus(_focusNodes[index - 1]); // Retour au champ précédent
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              HeaderWidget("Login", text: 'Vérification du code'),
              const SizedBox(height: 80),
              const Text(
                "Entrez le code de vérification envoyé à votre email",
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              Image.asset("images/verifierPassword.png", height: 250, width: 250),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) => _buildCodeField(index)), // Génération des champs dynamiquement
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitCode,
                child: const Text("Vérifier", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
