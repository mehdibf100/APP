import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pfe/models/DeliveryRequestTransporter.dart';
import '../../../models/Deliveryrequestcustomer.dart';
import '../../../services/userService.dart';
import '../../../utils/api_const.dart';
import '../../widgets/DeliveryRequestTransporterCard.dart';

class MyDeliveryRequestCustomerScreen extends StatefulWidget {
  final String userId;

  const MyDeliveryRequestCustomerScreen({super.key, required this.userId});

  @override
  State<MyDeliveryRequestCustomerScreen> createState() => _MyDeliveryRequestCustomerScreenState();
}

class _MyDeliveryRequestCustomerScreenState extends State<MyDeliveryRequestCustomerScreen> {

  List<DeliveryRequestTransporter> postTransporters = [];
  String notificationMessage = "";
  String errorMessage = "";
  Map<int, bool> expandedCards = {};
  DeliveryRequestCustomer? deliverie ;

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> fetchDeliveries() async {
    print(widget.userId);
    try {
      final url = Uri.parse('${ApiConst.getDeliveryRequestTransporterByCustomerIdApi}${widget.userId}');
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        final List<DeliveryRequestTransporter> fetchedOrders = data.map((json) => DeliveryRequestTransporter.fromJson(json)).toList();

        await Future.wait(fetchedOrders.map((t) => _resolvePlaceNames(t)));

        setState(() {
          postTransporters = fetchedOrders;
          errorMessage = "";
        });
      } else {
        setState(() => errorMessage = "Erreur : ${response.body}");
      }
    } catch (e) {
      setState(() => errorMessage = "Erreur de connexion: $e");
      print("Erreur fetchDeliveries: $e");
    }
  }
  Future<void> _resolvePlaceNames(DeliveryRequestTransporter t) async {
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



  @override
  void initState() {
    super.initState();
    fetchDeliveries();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 15),
            Expanded(
              child: postTransporters.isEmpty
                  ? Center(
                child: Text(
                  errorMessage.isNotEmpty ? errorMessage : 'Aucune livraison trouvée',
                ),
              )
                  :ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: postTransporters.length,
                itemBuilder: (context, index) {
                  final order = postTransporters[index];
                  final isExpanded = expandedCards[order.packageId] ?? false;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: DeliveryRequestTransporterCard(
                      id: '${order.packageId}',
                      type: 'livraison',
                      origine: order.fromAdresseDelivery,
                      destination: order.toAdresseDelivery,
                      date: _formatDate(DateTime.parse(order.date)),
                      time: order.time,
                      cout: '${order.cout} TND',
                      status: '${order.status.toLowerCase() }  traitement',
                      statusColor: order.status.toLowerCase() == 'en cours'
                          ? Colors.orange
                          : (order.status.toLowerCase() == 'accepted' ||
                          order.status.toLowerCase() == 'en route')
                          ? Colors.green
                          : Colors.red,
                      packageItems: order.packageItems,
                      isExpanded: isExpanded,
                      onToggleDetails: () {
                        setState(() {
                          expandedCards[index] = !isExpanded;
                        });
                      },
                      test: false,

                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
