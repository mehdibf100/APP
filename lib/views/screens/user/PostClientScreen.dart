import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:pfe/utils/api_const.dart';
import 'dart:convert';
import '../../../models/Order.dart';
import '../../../services/mapService.dart';
import '../../widgets/DeliveryCard.dart';

class Postscreen extends StatefulWidget {
  final String origine;       // Doit être "lat,lng"
  final String destination;   // Doit être "lat,lng"
  final String date;
  const Postscreen({
    super.key,
    required this.origine,
    required this.destination,
    required this.date,
  });

  @override
  State<Postscreen> createState() => _PostscreenState();
}

class _PostscreenState extends State<Postscreen> {
  List<Order> orders = [];
  String errorMessage = "";
  bool isLoading = false;
  Map<String, bool> expandedCards = {};
  MapService mapService=new MapService();

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

// dans votre StatefulWidget

  Future<void> fetchOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final uri = Uri.parse(
        "${ApiConst.filterPostClientApi}"/*
        '${ApiConst.filterPostClientApi}?fromAdresse=${Uri.encodeComponent(widget.origine)}'
          '&toAdresse=${Uri.encodeComponent(widget.destination)}'
    '&date=${Uri.encodeComponent(widget.date)}',*/
      );
      print("${widget.origine} //${widget.destination}");
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur ${response.statusCode} : ${response.body}');
      }

      // Décodage : on suppose une List<...> en racine
      final raw = jsonDecode(response.body);
      final List<dynamic> dataList = raw is List<dynamic>
          ? raw
          : (raw is Map<String, dynamic> && raw['livraisons'] is List)
          ? raw['livraisons'] as List<dynamic>
          : [];

      final fetchedOrders = dataList
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();

      // Résoudre les noms de lieux
      await Future.wait(fetchedOrders.map(mapService.resolvePlaceNames));

      if (!mounted) return;
      setState(() {
        orders = fetchedOrders;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Erreur de chargement : $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _resolvePlaceNames(Order order) async {
    Future<String> lookup(String coords) async {
      final parts = coords.split(',');
      if (parts.length != 2) return coords;
      try {
        final lat = double.parse(parts[0]);
        final lng = double.parse(parts[1]);
        final placemarks = await placemarkFromCoordinates(lat, lng);
        final place = placemarks.first;
        return '${place.locality ?? place.administrativeArea}, ${place.country}';
      } catch (_) {
        return coords;
      }
    }

    order.fromAdresseDelivery = await lookup(order.fromAdresseDelivery);
    order.toAdresseDelivery = await lookup(order.toAdresseDelivery);
  }

  void toggleCardDetails(String id) {
    setState(() {
      expandedCards[id] = !(expandedCards[id] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                color: Color(0xFF3B82F6),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Livraison',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF3B82F6)),
            onPressed: fetchOrders,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Livraisons disponibles',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${orders.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: fetchOrders,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Actualiser'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),

          // Contenu principal
          Expanded(
            child: isLoading
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : errorMessage.isNotEmpty
                ? _buildErrorView()
                : _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: const TextStyle(color: Color(0xFFB91C1C)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: fetchOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final order = orders[index];
        final id = order.packageId.toString();
        return DeliveryCard(
          id: id,
          type: 'livraison',
          route: '${order.fromAdresseDelivery} → ${order.toAdresseDelivery}',
          cout: '${order.cout}',
          status: order.status,
          statusColor: _getStatusColor(order.status),
          packageItems: order.packageItems,
          enRoute: order.status.toLowerCase() == 'en route',
          isExpanded: expandedCards[id] ?? false,
          onToggleDetails: () => toggleCardDetails(id),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'en cours') return Colors.orange;
    if (s == 'accepted' || s == 'en route') return Colors.green;
    return Colors.red;
  }
}
