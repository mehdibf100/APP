import 'package:flutter/cupertino.dart';
import 'package:geocoding/geocoding.dart';
import 'package:pfe/models/Order.dart';

class MapService{
  Future<void> resolvePlaceNames(Order t) async {
    final results = await Future.wait([
      _reverseGeocode(t.fromAdresseDelivery),
      _reverseGeocode(t.toAdresseDelivery),
    ]);
    t.fromAdresseDelivery = results[0];
    t.toAdresseDelivery = results[1];
  }

  /// Retourne sous forme 'Gouvernorat, Pays'
  Future<String> _reverseGeocode(String coords) async {
    final parts = coords.split(',');
    if (parts.length != 2) return coords;

    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return coords;

    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) throw Exception('Aucun résultat');

      final p = placemarks.first;
      final region = p.administrativeArea ?? '';
      final country = p.country ?? '';
      if (region.isNotEmpty && country.isNotEmpty) {
        return '$region, $country';
      } else if (region.isNotEmpty) {
        return region;
      } else if (country.isNotEmpty) {
        return country;
      }
      throw Exception('Informations manquantes');
    } catch (e) {
      debugPrint('Geocoding failed for $coords: $e');
      // Fallback simple
      return coords;
    }
  }

}