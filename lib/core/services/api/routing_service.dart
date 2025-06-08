import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';
import '../../models/location_model.dart';
import '../../models/route_model.dart';

class RoutingService {
  /// Récupère un itinéraire entre deux points
  Future<RouteModel?> getRoute(LocationModel origin, LocationModel destination) async {
    final url = '${ApiConstants.osrmBaseUrl}/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 'Ok') {
          return RouteModel.fromJson(data, origin, destination);
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération de l\'itinéraire: $e');
    }
    
    return null;
  }
}
