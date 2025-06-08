import 'package:latlong2/latlong.dart';
import '../models/location_model.dart';

class RouteModel {
  final LocationModel origin;
  final LocationModel destination;
  final List<LatLng> routePoints;
  final double distance; // en mètres
  final double duration; // en secondes
  
  RouteModel({
    required this.origin,
    required this.destination,
    required this.routePoints,
    required this.distance,
    required this.duration,
  });
  
  factory RouteModel.fromJson(Map<String, dynamic> json, LocationModel origin, LocationModel destination) {
    final route = json['routes'][0];
    final geometry = route['geometry'];
    final List<LatLng> points = [];
    
    // Conversion des coordonnées du format GeoJSON au format LatLng
    for (final coord in geometry['coordinates']) {
      // Note: GeoJSON utilise [longitude, latitude]
      points.add(LatLng(coord[1], coord[0]));
    }
    
    return RouteModel(
      origin: origin,
      destination: destination,
      routePoints: points,
      distance: route['distance'],
      duration: route['duration'],
    );
  }
  
  String get formattedDistance {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    } else {
      return '${distance.toStringAsFixed(0)} m';
    }
  }
  
  String get formattedDuration {
    final minutes = (duration / 60).floor();
    final hours = (minutes / 60).floor();
    
    if (hours > 0) {
      final remainingMinutes = minutes % 60;
      return '$hours h ${remainingMinutes > 0 ? '$remainingMinutes min' : ''}';
    } else {
      return '$minutes min';
    }
  }
}
