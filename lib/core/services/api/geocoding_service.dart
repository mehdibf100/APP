import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../constants/api_constants.dart';
import '../../models/location_model.dart';

class GeocodingService {
  /// Récupère des suggestions d'adresses basées sur une requête
  Future<List<LocationModel>> getSuggestions(String query) async {
    if (query.isEmpty) {
      return [];
    }

    final uri = Uri.parse(
      '${ApiConstants.openCageBaseUrl}?q=${Uri.encodeComponent(query)}'
      '&key=${ApiConstants.openCageApiKey}'
      '&limit=${ApiConstants.suggestionLimit}'
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = List<Map<String, dynamic>>.from(data['results']);
        
        return results.map((json) => LocationModel.fromJson(json)).toList();
      }
    } catch (e) {
      print('Erreur lors de la récupération des suggestions: $e');
    }
    
    return [];
  }

  /// Récupère les coordonnées d'un lieu à partir de son nom
  Future<LocationModel?> getCoordinates(String place) async {
    if (place.isEmpty) {
      return null;
    }

    final uri = Uri.parse(
      '${ApiConstants.openCageBaseUrl}?q=${Uri.encodeComponent(place)}'
      '&key=${ApiConstants.openCageApiKey}'
      '&limit=${ApiConstants.geocodingLimit}'
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final List results = data['results'];
        
        if (results.isNotEmpty) {
          return LocationModel.fromJson(results[0]);
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération des coordonnées: $e');
    }
    
    return null;
  }
}
