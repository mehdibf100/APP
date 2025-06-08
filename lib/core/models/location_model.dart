import 'package:latlong2/latlong.dart';

class LocationModel {
  final String formattedAddress;
  final double latitude;
  final double longitude;
  
  LocationModel({
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
  });
  
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>;
    return LocationModel(
      formattedAddress: json['formatted'] as String,
      latitude: geometry['lat'] as double,
      longitude: geometry['lng'] as double,
    );
  }
  
  LatLng get latLng => LatLng(latitude, longitude);
  
  String get coordinatesString => "$latitude,$longitude";
}
