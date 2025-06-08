import '../services/api/geocoding_service.dart';
import '../services/api/routing_service.dart';
import '../services/local/preferences_service.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  
  factory ServiceLocator() => _instance;
  
  ServiceLocator._internal();
  
  final GeocodingService geocodingService = GeocodingService();
  final RoutingService routingService = RoutingService();
  final PreferencesService preferencesService = PreferencesService();
}
