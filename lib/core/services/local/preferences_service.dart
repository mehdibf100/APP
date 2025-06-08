import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _roleKey = 'selectedRole';
  
  /// Récupère le rôle sélectionné par l'utilisateur
  Future<String> getSelectedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey) ?? 'USER';
  }
  
  /// Enregistre le rôle sélectionné par l'utilisateur
  Future<void> setSelectedRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
  }
}
