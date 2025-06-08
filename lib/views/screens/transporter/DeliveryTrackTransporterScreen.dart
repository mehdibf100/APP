import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pfe/services/mapService.dart';
import '../../../models/Order.dart';
import '../../../utils/api_const.dart';
import '../../widgets/DeliveryCardTransporter.dart';
import '../user/CreatePostDelivery.dart';

class DeliveryTrackScreen extends StatefulWidget {
  final String userId;
  const DeliveryTrackScreen({super.key, required this.userId});

  @override
  _DeliveryTrackScreenState createState() => _DeliveryTrackScreenState();
}

class _DeliveryTrackScreenState extends State<DeliveryTrackScreen> {
  List<Order> postTransporters = [];
  List<Order> postTransportersLocation = [];
  String notificationMessage = "";
  String errorMessage = "";
  Map<int, bool> expandedCards = {};
  final MapService mapService=new MapService();

  Future<void> updateOrder(String orderId, String status, String answer, String clientId) async {
    final String url = ApiConst.updateOrderStatusByIdApi + "$orderId";

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status, 'answer': answer, 'clientId': clientId}),
      );

      if (response.statusCode == 200) {
        print("Order mis à jour avec succès !");
        print("clienId : $clientId");

        try {
          final responseNotif = await http.post(
            Uri.parse('${ApiConst.sendNotificationApi}'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              "userId": clientId,
              "message": answer
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


  Future<void> fetchPostTransporter() async {
    try {
      final url = Uri.parse('${ApiConst.findOrdersTransporterByIdApi}${widget.userId}');
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        final List<Order> fetchedOrders = data.map((json) => Order.fromJson(json)).toList();
        final List<Order> fetchedOrdersTest = data.map((json) => Order.fromJson(json)).toList();

        await Future.wait(fetchedOrders.map((t) => mapService.resolvePlaceNames(t)));

        setState(() {
          postTransporters = fetchedOrders;
          postTransportersLocation=fetchedOrdersTest;
          errorMessage = "";
        });
      } else {
        setState(() {
          errorMessage = "Erreur ${response.statusCode} : ${response.reasonPhrase}";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Erreur de connexion : $e";
      });
    }
  }


  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  void initState() {
    super.initState();
    fetchPostTransporter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 15),
            Expanded(
              child: postTransporters.isEmpty
                  ? Center(
                  child: Text(errorMessage.isNotEmpty ? errorMessage : 'Aucune livraison trouvée'))
                  : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: postTransporters.length,
                itemBuilder: (context, index) {
                  final order = postTransporters[index];
                  final orderTest = postTransportersLocation[index];
                  final isExpanded = expandedCards[index] ?? false;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: DeliveryCardTransporter(
                      id: '${order.packageId}',
                      type: 'livraison',
                      route: '${order.fromAdresseDelivery} → ${order.toAdresseDelivery}',
                      cout: '7.2TND',
                      date: '${_formatDate(DateTime.parse(order.date))}',
                      time: "00:00",
                      status: order.status=="EN COURS"?"Accepted":order.status,
                      statusColor:

                      order.status.toLowerCase() == 'en cours'  ||order.status.toLowerCase() == 'EN COURS' ||order.status.toLowerCase() == 'accepted' ||order.status.toLowerCase() =='livre'||order.status.toLowerCase() =='en route'?Colors.green :Colors.red,
                      packageItems: order.packageItems,
                      enRoute: order.status.toLowerCase() == 'en route',
                      isExpanded: isExpanded,
                      origineTest:orderTest.fromAdresseDelivery ,
                      destinationTest:orderTest.toAdresseDelivery ,
                      origine:order.fromAdresseDelivery ,
                      destination:order.toAdresseDelivery ,
                      onToggleDetails: () {
                        setState(() {
                          expandedCards[index] = !isExpanded;
                        });
                      },
                      test:order.status.toLowerCase() == 'annuler'||order.status.toLowerCase() == "rejected"||order.status.toLowerCase() == "livre"?false:true ,
                      nameBt1:order.status.toLowerCase() == 'en route'? "Livre":"en route" ,
                      nameBt2: "Annuler" ,
                      onAccept: () async {
                  await updateOrder(
                  order.packageId.toString(),
                    order.status.toLowerCase() == 'en route'? "Livre":"en route" ,
                    order.status.toLowerCase() == 'en route'?"Commande ton est  livrée":"Commande ton est  en route",
                  order.clientId.toString(),
                  );
                  fetchPostTransporter();
                  },
                      onReject:() async {
                        await updateOrder(
                          order.packageId.toString(),
                          "annuler",
                          "Commande ton est annuler",
                          order.clientId.toString(),
                        );
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