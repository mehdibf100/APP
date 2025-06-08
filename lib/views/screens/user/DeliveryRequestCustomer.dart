import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pfe/utils/api_const.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../models/Deliveryrequestcustomer.dart';
import '../../../services/userService.dart';
import '../../widgets/DeliveryRequestCustomerCard.dart';
import '../chat/ChatDetailScreen.dart';

class DeliveryRequestCustomerScreen extends StatefulWidget {
  final String userId;

  const DeliveryRequestCustomerScreen({super.key, required this.userId});

  @override
  State<DeliveryRequestCustomerScreen> createState() => _DeliveryRequestCustomerScreenState();
}

class _DeliveryRequestCustomerScreenState extends State<DeliveryRequestCustomerScreen> {
  List<DeliveryRequestCustomer> deliveries = [];
  List<DeliveryRequestCustomer> deliveriesLocation = [];

  DeliveryRequestCustomer? deliverie ;
  String errorMessage = "";
  String userId="";
  Map<String, bool> expandedCards = {};
  final TextEditingController _searchController = TextEditingController();
  final UserService _userService = UserService();
  Map<String, dynamic>? _user;

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
  @override
  void initState() {
    super.initState();
    userId=widget.userId;
    fetchDeliveries();
    _loadUser();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  Future<void> _resolvePlaceNames(DeliveryRequestCustomer t) async {
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
  Future<void> fetchDeliveries() async {
    try {
      final url = Uri.parse('${ApiConst.deliveryRequestCustomerByClientIdApi}$userId');
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        print("Réponse reçue: ${response.body}");
        List<dynamic>  data = jsonDecode(response.body);

        final List<DeliveryRequestCustomer> fetchedOrders = data.map((json) => DeliveryRequestCustomer.fromJson(json)).toList();
        final List<DeliveryRequestCustomer> fetchedOrdersTest = data.map((json) => DeliveryRequestCustomer.fromJson(json)).toList();

        await Future.wait(fetchedOrders.map((t) => _resolvePlaceNames(t)));

        setState(() {
          deliveries = fetchedOrders;
          deliveriesLocation=fetchedOrdersTest;
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
  Future<void> updateOrder(String orderId,String transporterId) async {
    final String url = ApiConst.acceptDeliveryRequestCustomerApi + "$orderId";

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print("Order mis à jour avec succès !");

        try {
          final responseNotif = await http.post(
            Uri.parse(ApiConst.sendNotificationApi),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              "userId": transporterId,
              "message": "your request is accepted"
            }),
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
  Future<void> refuseOrder(String orderId,String transporterId)async{
    final String url = ApiConst.UpdateDeliveryRequestCustomerApi + "$orderId";

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': "REFUSER",}),

      );

      if (response.statusCode == 200) {
        print("Order mis à jour avec succès !");

        try {
          final responseNotif = await http.post(
            Uri.parse(ApiConst.sendNotificationApi),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              "userId": transporterId,
              "message": "your request is accepted"
            }),
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
  Future<void> _createOrder(String id) async {
    try {
      final url = Uri.parse('${ApiConst.getDeliveryRequestCustomerByIdApi}$id');
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});
      if (response.statusCode != 200) {
        setState(() => errorMessage = "Erreur : ${response.body}");
        return;
      }
      // 2) Parse en objet métier
      final Map<String, dynamic> raw = jsonDecode(response.body);
      if (raw['transporteur'] == null) {
        setState(() => errorMessage = "Données invalides reçues");
        return;
      }
      final deliverie = DeliveryRequestCustomer.fromJson(raw);

      final List<Map<String, dynamic>> items =
    deliverie.packageItems.map((p) => p.toJson()).toList();


    // Création de la commande
      final orderData = {
        'transporteurId': deliverie.transporteur.id,
        'clientId': userId,
        'fromAdresse': deliverie.fromAdresseDelivery,
        'toAdresse': deliverie.toAdresseDelivery,
        'date': deliverie.date,
        'time': deliverie.time,
        'cout': deliverie.cout,
        'packageItems': items,
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
          "clientId": userId,
          "transporteurId": deliverie.transporteur.id.toString(),
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
            MaterialPageRoute(builder: (_) => ChatScreen(
              conversationId: conversation['id'],
              clientId: userId,
              livreurId: deliverie.transporteur.id.toString(),
              currentUserId: userId,
              contactName: deliverie.transporteur!.name ?? "Transporteur",
              contactAvatar: deliverie.transporteur!.avatar ?? "", currentUserName: _user!["name"],
            )),
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

  void _loadUser() async {
    try {
      final userData = await _userService.getUserById(userId);
      setState(() {
        _user = userData;
      });
    } catch (e) {
      debugPrint("Erreur lors du chargement de l'utilisateur: $e");
    }
  }

  void toggleCardDetails(String id) {
    setState(() {
      expandedCards[id] = !(expandedCards[id] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(height: 20,),
          Expanded(
            child: deliveries.isEmpty
                ? Center(
              child: Text(
                errorMessage.isNotEmpty ? errorMessage : 'Aucune livraison trouvée',
              ),
            ) : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: deliveries.length,
              itemBuilder: (context, index) {
                final delivery = deliveries[index];
                final deliveryId = delivery.id.toString();

                return Column(
                  children: [
                    DeliveryRequestCustomerCard(
                      id: deliveryId,
                      type: 'livraison',
                      origine: '${delivery.fromAdresseDelivery} ',
                      destination:'${delivery.toAdresseDelivery}',
                      cout: '${delivery.cout}TND',
                      date: _formatDate(DateTime.parse(delivery.date)),
                      time: delivery.time,
                      status: delivery.status,
                      statusColor: delivery.status.toLowerCase() == 'en cours'
                          ? Colors.orange
                          : (delivery.status == 'ACCEPTED' ||
                          delivery.status.toLowerCase() == 'en route')
                          ? Colors.green
                          : Colors.red,
                      result:(delivery.status.toLowerCase() == 'en cours') ,
                      packageItems: delivery.packageItems,
                      isExpanded: expandedCards[deliveryId] ?? false,
                      onToggleDetails: () => toggleCardDetails(deliveryId),
                      onAccept: () {updateOrder(deliveryId,delivery.transporteur.id.toString());
                      fetchDeliveries();
                        _createOrder(delivery.id.toString());
                      },
                      onRefuse:() {refuseOrder(deliveryId,delivery.transporteur.id.toString());
                      fetchDeliveries();} ,
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}