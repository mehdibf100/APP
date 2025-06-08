import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:pfe/utils/api_const.dart';
import '../../../models/TransporterPost.dart';
import '../user/contactTransporter.dart';

class TransportListScreen extends StatefulWidget {
  final String origine;
  final String destination;
  final String date;
  final String userId;

  const TransportListScreen({
    super.key,
    required this.origine,
    required this.destination,
    required this.date,
    required this.userId,
  });

  @override
  _TransportListScreenState createState() => _TransportListScreenState();
}

class _TransportListScreenState extends State<TransportListScreen> {
  List<Transport> postTransporters = [];
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    fetchPostTransporter();
  }

  Future<void> fetchPostTransporter() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      final url = Uri.parse(
        '${ApiConst.filterPostTransporterApi}'
            '?fromAdresse=36.8002068,10.1857757'
            '&toAdresse=36.3319504,10.0453'
            '&date=${Uri.encodeComponent(widget.date)}',
      );
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        print('${widget.origine } ${widget.destination}');
        final List<dynamic> data = jsonDecode(response.body);
        postTransporters = data.map((json) => Transport.fromJson(json)).toList();
        print(postTransporters);
        // Géocodage des adresses en parallèle
        await Future.wait(
          postTransporters.map((t) => _resolvePlaceNames(t)),
        );
      } else {
        errorMessage = "Erreur serveur : ${response.body}";
      }
    } catch (e) {
      errorMessage = "Erreur de connexion : $e";
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _resolvePlaceNames(Transport t) async {
    final results = await Future.wait([
      _reverseGeocode(t.origin),
      _reverseGeocode(t.destination),
    ]);
    t.origin = results[0];
    t.destination = results[1];
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

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: Center(child: Text(errorMessage)),
      );
    }

    if (postTransporters.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: Center(child: Text('Aucune livraison disponible')),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: postTransporters.length,
        itemBuilder: (context, i) {
          final t = postTransporters[i];
          return Column(
            children: [
              _buildTransportCard(t),
              SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        'Transport Connect',
        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.white,
      elevation: 0,

    );
  }

  Widget _buildTransportCard(Transport t) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(
                "https://cdn-icons-png.flaticon.com/512/4140/4140037.png",
              ),
            ),
            title: Text(t.name, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(t.status, style: TextStyle(color: Colors.grey)),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _buildInfoRow(Icons.local_shipping, t.vehicleType),
                SizedBox(height: 8),
                _buildInfoRow(Icons.location_on, t.origin),
                SizedBox(height: 8),
                _buildInfoRow(Icons.location_on_outlined, t.destination),
                SizedBox(height: 8),
                _buildInfoRow(Icons.calendar_today, _formatDate(DateTime.parse(t.date))),
                SizedBox(height: 8),
                _buildInfoRow(Icons.timelapse, t.time)
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ContactTransporter(postId: t.id, userId: widget.userId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Contacter', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(fontSize: 14))),
      ],
    );
  }
}