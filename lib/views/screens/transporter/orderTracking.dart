import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class OrderTracking extends StatefulWidget {
  final String origine;      // "lat,lon"
  final String destination;  // "lat,lon"

  const OrderTracking({
    super.key,
    required this.origine,
    required this.destination,
  });

  @override
  State<OrderTracking> createState() => _OrderTrackingState();
}

class _OrderTrackingState extends State<OrderTracking> {
  LatLng? _currentPosition;
  late LatLng _origPoint;
  late LatLng _destPoint;
  List<LatLng> _routePoints = [];
  late StreamSubscription<Position> _positionSubscription;
  bool _loadingRoute = false;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _parsePoints();
    _startTracking();
  }

  void _parsePoints() {
    final origParts = widget.origine.split(',');
    final destParts = widget.destination.split(',');
    _origPoint = LatLng(
      double.parse(origParts[0]),
      double.parse(origParts[1]),
    );
    _destPoint = LatLng(
      double.parse(destParts[0]),
      double.parse(destParts[1]),
    );
  }

  @override
  void dispose() {
    _positionSubscription.cancel();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw 'Services de localisation désactivés';
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        throw 'Permission de localisation refusée';
      }
    }
    if (perm == LocationPermission.deniedForever) {
      throw 'Permission de localisation définitivement refusée';
    }
  }

  void _startTracking() {
    _checkPermissions().then((_) {
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5,
        ),
      ).listen((pos) {
        setState(() {
          _currentPosition = LatLng(pos.latitude, pos.longitude);
        });
        _getMultiStopRoute();
      });
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    });
  }

  /// Calcule un itinéraire multi-étapes: départ (_currentPosition) -> origine -> destination
  Future<void> _getMultiStopRoute() async {
    if (_currentPosition == null || _loadingRoute) return;
    setState(() => _loadingRoute = true);

    const apiKey = '5b3ce3597851110001cf624866893a55bdbd4b12b02b31f0afd1a2be';
    final coords = [
      // Note: ORS expects [lon, lat]
      [_currentPosition!.longitude, _currentPosition!.latitude],
      [_origPoint.longitude, _origPoint.latitude],
      [_destPoint.longitude, _destPoint.latitude],
    ];

    final uri = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/driving-car/geojson',
    );

    try {
      final resp = await http.post(
        uri,
        headers: {
          'Accept': 'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8',
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': apiKey,
        },
        body: json.encode({'coordinates': coords}),
      );

      if (resp.statusCode == 403) {
        throw '403 Forbidden – vérifiez votre clé API et quotas';
      } else if (resp.statusCode != 200) {
        throw 'Erreur API (${resp.statusCode})';
      }

      final data = json.decode(resp.body);
      final features = data['features'] as List;
      if (features.isEmpty) throw 'Aucun itinéraire trouvé';

      final geometry = features[0]['geometry'];
      final coordsList = geometry['coordinates'] as List;
      setState(() {
        _routePoints = coordsList
            .map((pt) => LatLng(pt[1] as double, pt[0] as double))
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur route : $e")),
      );
    } finally {
      setState(() => _loadingRoute = false);
    }
  }

  void _centerOnCurrent() {
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi de commande'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _centerOnCurrent,
            tooltip: 'Centrer sur ma position',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_currentPosition == null)
            const Center(child: CircularProgressIndicator())
          else
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _currentPosition!,
                zoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.directions_car,
                        color: Colors.blue,
                        size: 30,
                      ),
                    ),
                    Marker(
                      point: _origPoint,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.flag,
                        color: Colors.green,
                        size: 30,
                      ),
                    ),
                    Marker(
                      point: _destPoint,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                  ],
                ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 5.0,
                        color: Colors.blue.withOpacity(0.7),
                      ),
                    ],
                  ),
              ],
            ),
          if (_loadingRoute)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text(
                      "Calcul de l'itinéraire...",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: _getMultiStopRoute,
              icon: const Icon(Icons.refresh),
              label: const Text("Actualiser itinéraire"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
