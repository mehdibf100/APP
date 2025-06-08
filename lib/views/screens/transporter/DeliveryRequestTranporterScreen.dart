import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pfe/models/DeliveryRequestTransporter.dart';
import '../../../services/userService.dart';
import '../../../utils/api_const.dart';
import '../../widgets/DeliveryRequestTransporterCard.dart';
import '../chat/ChatDetailScreen.dart';

class DeliveryRequestTransporterScreen extends StatefulWidget {
  final String userId;

  const DeliveryRequestTransporterScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<DeliveryRequestTransporterScreen> createState() => _DeliveryRequestTransporterScreenState();
}

class _DeliveryRequestTransporterScreenState extends State<DeliveryRequestTransporterScreen> {
  List<DeliveryRequestTransporter> postTransporters = [];
  List<DeliveryRequestTransporter> postTransportersLocation = [];
  String notificationMessage = "";
  String errorMessage = "";
  Map<int, bool> expandedCards = {};
  Map<String, dynamic>? _user;
  final UserService _userService = UserService();

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
  Future<void> updateDeliveryRequestTransporterStatus(String orderId, String status, String answer, String clientId) async {
    final String url = ApiConst.updateDeliveryRequestTransporterStatusByIdApi + "$orderId";

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status, 'answer': answer, 'clientId': clientId}),
      );

      if (response.statusCode == 200) {
        print("Order mis à jour avec succès !");
        print("clientId : $clientId");

        try {
          final responseNotif = await http.post(
            Uri.parse('${ApiConst.sendNotificationApi}'),
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode({"userId": clientId, "message": answer}),
          );

          if (responseNotif.statusCode == 200) {
            print("Notification sent successfully");
          } else {
            print("Error: ${responseNotif.statusCode}, Response: ${responseNotif.body}");
          }
        } catch (e) {
          print("Failed to send notification: $e");
        }
      } else {
        throw Exception("Erreur de mise à jour : ${response.body}");
      }
    } catch (e) {
      throw Exception("Échec de la mise à jour : $e");
    }
  }

  Future<void> fetchPostTransporter() async {
    try {
      final url = Uri.parse('${ApiConst.getDeliveryRequestTransporterByTransporterIdApi}${widget.userId}');
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        print("Réponse reçue: ${response.body}");
        List<dynamic>  data = jsonDecode(response.body);

        final List<DeliveryRequestTransporter> fetchedOrders = data.map((json) => DeliveryRequestTransporter.fromJson(json)).toList();
        final List<DeliveryRequestTransporter> fetchedOrdersTest = data.map((json) => DeliveryRequestTransporter.fromJson(json)).toList();

        await Future.wait(fetchedOrders.map((t) => _resolvePlaceNames(t)));

        setState(() {
          postTransporters = fetchedOrders;
          postTransportersLocation=fetchedOrdersTest;
          errorMessage = "";
        });
      } else {
        setState(() => errorMessage = "Erreur serveur: ${response.body}");
        print("Erreur serveur: ${response.statusCode}, Réponse: ${response.body}");
      }
    } catch (e) {
      setState(() => errorMessage = "Erreur de connexion: $e");
      print("Erreur de connexion: $e");
    }
  }

  void _loadUser() async {
    try {
      final userData = await _userService.getUserById(widget.userId);
      setState(() {
        _user = userData;
      });
    } catch (e) {
      debugPrint("Erreur lors du chargement de l'utilisateur: $e");
    }
  }

  Future<void> _createOrder(String id) async {
    try {
      final url = Uri.parse('${ApiConst.getDeliveryRequestTransporterByIdApi}$id');
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});
      if (response.statusCode != 200) {
        setState(() => errorMessage = "Erreur : ${response.body}");
        return;
      }
      final deliverie = jsonDecode(response.body);
      if (deliverie == null || deliverie['transporteur'] == null) {
        setState(() => errorMessage = "Données invalides reçues");
        return;
      }

      final orderData = {
        'transporteurId':widget.userId,
        'clientId': deliverie['client']['id'],
        'fromAdresse': deliverie['fromAdresseDelivery'],
        'toAdresse': deliverie['toAdresseDelivery'],
        'date': deliverie['date'],
        'time': deliverie['time'],
        'cout': deliverie['cout'],
        'packageItems': deliverie['packageItems'],
      };
      final responseOrder = await http.post(
        Uri.parse(ApiConst.createOrderApi),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(orderData),
      );
      if (responseOrder.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commande créée avec succès')),
        );

        final convData = {
          "clientId":  deliverie['transporteur']['id'].toString(),
          "transporteurId":deliverie['client']['id'].toString(),
        };
        final convResponse = await http.post(
          Uri.parse(ApiConst.createOrGetConversationApi),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(convData),
        );
        if (convResponse.statusCode == 200) {
          final conversation = jsonDecode(convResponse.body);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                conversationId: conversation['id'],
                clientId:deliverie['client']['id'].toString() ,
                livreurId:widget.userId ,
                currentUserId: widget.userId,
                contactName: deliverie['client']['name'] ?? "Transporteur",
                contactAvatar: deliverie['client']['avatar'] ?? "",
                currentUserName: _user!["name"],
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur création conversation : ${convResponse.body}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${responseOrder.statusCode} - ${responseOrder.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion : $e')),
      );
      print("Erreur _createOrder: $e");
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
    _loadUser();
    fetchPostTransporter();
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
                  : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: postTransporters.length,
                itemBuilder: (context, index) {
                  final order = postTransporters[index];
                  final isExpanded = expandedCards[index] ?? false;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: DeliveryRequestTransporterCard(
                      id: '${order.packageId}',
                      type: 'livraison',
                       date: '${_formatDate(DateTime.parse(order.date))}',
                      time: order.time,
                      cout: '${order.cout} TND',
                      status: order.status,
                      origine:order.fromAdresseDelivery,
                      destination: order.toAdresseDelivery,
                      statusColor: order.status.toLowerCase() == 'en cours'
                          ? Colors.orange
                          : order.status.toLowerCase() == 'accepted' || order.status.toLowerCase() == 'en route'
                          ? Colors.green
                          : Colors.red,
                      packageItems: order.packageItems,
                      isExpanded: isExpanded,
                      onToggleDetails: () {
                        setState(() {
                          expandedCards[index] = !isExpanded;
                        });
                      },
                      test: (order.status.toLowerCase() == "en cours"),
                      onAccept: () async {
                        await updateDeliveryRequestTransporterStatus(
                            order.packageId.toString(),
                            "accepted",
                            "Votre demande est acceptée par le client",
                            order.clientId.toString());
                        await _createOrder(order.packageId.toString());
                        fetchPostTransporter();
                      },
                      onReject: () async {
                        await updateDeliveryRequestTransporterStatus(
                            order.packageId.toString(),
                            "rejected",
                            "Votre demande est refusée par le client",
                            order.clientId.toString());
                        fetchPostTransporter();
                      },
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
