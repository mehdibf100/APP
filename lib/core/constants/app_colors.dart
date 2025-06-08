import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales
  static const Color primary = Color(0xFF3F51B5);      // Bleu indigo
  static const Color primaryDark = Color(0xFF303F9F);  // Bleu indigo foncé
  static const Color primaryLight = Color(0xFFC5CAE9); // Bleu indigo clair
  static const Color accent = Color(0xFFFF5722);       // Orange profond
  
  // Couleurs secondaires
  static const Color secondary = Color(0xFF4CAF50);    // Vert
  static const Color secondaryDark = Color(0xFF388E3C);// Vert foncé
  
  // Couleurs neutres
  static const Color background = Color(0xFFF5F5F5);   // Gris très clair
  static const Color surface = Colors.white;
  static const Color cardBackground = Colors.white;
  
  // Couleurs de texte
  static const Color textPrimary = Color(0xFF212121);  // Presque noir
  static const Color textSecondary = Color(0xFF757575);// Gris foncé
  static const Color textHint = Color(0xFFBDBDBD);     // Gris moyen
  
  // Couleurs fonctionnelles
  static const Color error = Color(0xFFD32F2F);        // Rouge
  static const Color success = Color(0xFF388E3C);      // Vert
  static const Color warning = Color(0xFFFFA000);      // Ambre
  static const Color info = Color(0xFF1976D2);         // Bleu
  
  // Couleurs de carte
  static const Color routeLine = primary;
  static const Color originMarker = info;
  static const Color destinationMarker = accent;
}
