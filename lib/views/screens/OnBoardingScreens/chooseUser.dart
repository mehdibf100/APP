import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pfe/utils/colors.dart';
import 'package:pfe/views/screens/auth/loginScreen.dart';
import '../../widgets/SignInButtonWidget.dart';

class Chooseuser extends StatefulWidget {
  const Chooseuser({Key? key}) : super(key: key);

  @override
  State<Chooseuser> createState() => _ChooseuserState();
}

class _ChooseuserState extends State<Chooseuser> {
  String _selectedRole = 'USER';

  Future<void> _saveSelectedRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedRole', _selectedRole);
  }

  void _navigateToLogin() async {
    await _saveSelectedRole();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Loginscreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 30),
                Image.asset(
                  "images/chooseUser.png",
                  height: MediaQuery.of(context).size.height * 0.3,
                ),
                const SizedBox(height: 32),
                Text(
                  "Together, we make\nyour life better.".tr,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontFamily: 'Urbanist-Bold',
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                _buildRoleSelector(),
                const SizedBox(height: 40),
                SignInButtonWidget(
                  onPressed: _navigateToLogin,
                  text: "Continue".tr,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildRoleOption(
            'USER'.tr,
            'Regular User'.tr,
            'Access services and request transportation'.tr,
            Icons.person_outline,
          ),
          Divider(height: 1, color: Colors.grey[200]),
          _buildRoleOption(
            'TRANSPORTEUR'.tr,
            'Transporter'.tr,
            'Offer transportation services to users'.tr,
            Icons.local_shipping_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleOption(String role, String title, String subtitle, IconData icon) {
    final isSelected = _selectedRole == role;

    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor.withOpacity(0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? primaryColor : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Urbanist-Bold'.tr,
                      fontSize: 16,
                      color: isSelected ? primaryColor : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: role,
              groupValue: _selectedRole,
              onChanged: (value) => setState(() => _selectedRole = value!),
              activeColor: primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}