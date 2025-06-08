import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pfe/services/mapService.dart';
import 'package:pfe/utils/colors.dart';
import 'package:pfe/views/screens/user/QRCodeOrderScreen.dart';
import '../../../models/Order.dart';
import '../../../utils/api_const.dart';
import '../user/CreatePostDelivery.dart';


import 'ClaimRequest.dart';

class DeliveryTrackUserScreen extends StatefulWidget {
  final String userId;

  const DeliveryTrackUserScreen({super.key, required this.userId});

  @override
  _DeliveryTrackUserScreenState createState() => _DeliveryTrackUserScreenState();
}

class _DeliveryTrackUserScreenState extends State<DeliveryTrackUserScreen> {
  List<Order> postTransporters = [];
  String errorMessage = "";
  Map<int, bool> expandedCards = {};
  bool isLoading = true;
  MapService mapService=new MapService();

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
  Future<void> fetchPostTransporter() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final response = await http.get(
        Uri.parse('${ApiConst.findOrdersClientByIdApi}${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Order> tempList = data.map((item) => Order.fromJson(item)).toList();
        // Résoudre les noms de lieu avant d'affecter à l'état
        await Future.wait(tempList.map((t) => mapService.resolvePlaceNames(t)));
        setState(() {
          postTransporters = tempList;
          // Initialiser l'état des cartes développées
          expandedCards = {for (var o in postTransporters) o.packageId!: false};
        });
      } else {
        setState(() {
          errorMessage = "Erreur ${response.statusCode}: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Erreur de connexion: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }



  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en cours':
        return Colors.amber;
      case 'en route':
        return Colors.green;
      case 'livre':
        return Colors.blue;
      case 'annuler':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'en cours':
        return "En préparation";
      case 'en route':
        return "En livraison";
      case 'arrivé':
        return "Livré";
      case 'rejected':
        return "Annulé";
      default:
        return status;
    }
  }

  Widget buildStepDot(bool isActive, bool isCompleted) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green : (isActive ? primaryColor : Colors.grey.shade300),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: isCompleted
          ? Icon(Icons.check, color: Colors.white, size: 14)
          : null,
    );
  }

  @override
  void initState() {
    super.initState();
    fetchPostTransporter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: fetchPostTransporter,
        color: primaryColor,
        backgroundColor: Colors.white,
        child: SafeArea(
          child: isLoading
              ? Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          )
              : postTransporters.isEmpty
              ? _buildEmptyState()
              : _buildDeliveryList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 80,
            color: primaryColor,
          ),
          SizedBox(height: 16),
          Text(
            errorMessage.isNotEmpty
                ? errorMessage
                : 'Aucune livraison trouvée',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.add,color: Colors.white,),
            label: Text('Créer une livraison'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateDeliveryScreen(userId: widget.userId)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: postTransporters.length,
      itemBuilder: (context, index) {
        final order = postTransporters[index];
        final statusColor = getStatusColor(order.status);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: InkWell(
            onTap: () {
              setState(() {
                if (expandedCards.containsKey(order.packageId)) {
                  expandedCards[order.packageId] = !expandedCards[order.packageId]!;
                } else {
                  expandedCards[order.packageId] = true;
                }
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(padding:EdgeInsets.only(left: 250),onPressed: (){
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EnhancedClaimRequest(orderId:order.packageId.toString() ,userId:widget.userId)

                            ),
                          );
                        }, icon:Icon(Icons.report,color: primaryColor,)),

                        // Header with status and ID
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),

                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    getStatusText(order.status),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '#DEL-${order.packageId.toString().padLeft(3, '0')}',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Locations
                        Row(
                          children: [
                            Icon(Icons.location_on, color: primaryColor, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                order.fromAdresseDelivery,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        // Route visualization
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: Container(
                            width: 2,
                            height: 24,
                            color: Colors.grey.shade300,
                          ),
                        ),

                        Row(
                          children: [
                            Icon(Icons.flag, color: Colors.red.shade700, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                order.toAdresseDelivery,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        // Details row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Arrivée prévue:',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "00:00",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),

                            // QR Code button
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => Qrcodeorderscreen(orderId: order.packageId.toString(),transpoteurName:order.nameT,clientName:order.name,date:order.time,phone:order.phone),
                                  ),
                                );
                              },
                              icon: Image.asset("images/qr-code.png", height: 15),
                              label: Text(
                                'Voir QR',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10
                                ),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: primaryColor.withOpacity(0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Expanded details (conditionally shown)
                  if (expandedCards.containsKey(order.packageId) && expandedCards[order.packageId]!)
                    _buildExpandedDetails(order),
                  ...order.packageItems.take(2).map((item) => Container(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.inventory_2_outlined, size: 20, color: Colors.amber.shade700),
                            ),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Dimensions: ${item.width.toStringAsFixed(1)} × ${item.height.toStringAsFixed(1)} cm',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.weight.toStringAsFixed(1)} kg',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpandedDetails(Order order) {
    // Déterminer l'étape actuelle de livraison
    int currentStep = 0;
    bool isFinished = false;

    switch (order.status.toLowerCase()) {
      case 'en cours':
        currentStep = 0;
        break;
      case 'en route':
        currentStep = 1;
        break;
      case 'livre':
        currentStep = 2;
        isFinished = true;
        break;
      case 'annuler':
        currentStep = -1;
        break;
      default:
        currentStep = 0;
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suivi de livraison',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 16),

          // Timeline widget
          Row(
            children: [
              Column(
                children: [
                  buildStepDot(currentStep >= 0, currentStep > 0 || isFinished),
                  Container(
                    width: 2,
                    height: 40,
                    color: currentStep > 0 ? primaryColor : Colors.orange,
                  ),
                  buildStepDot(currentStep >= 1, currentStep > 1 || isFinished),
                  Container(
                    width: 2,
                    height: 40,
                    color: currentStep > 1 ? primaryColor : Colors.blue,
                  ),
                  buildStepDot(currentStep >= 2, isFinished),
                ],
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTimelineStep(
                      "Commande confirmée",
                      "Votre commande est en cours de préparation",
                      currentStep >= 0,
                      currentStep > 0 || isFinished,
                    ),
                    SizedBox(height: 24),
                    _buildTimelineStep(
                      "En route",
                      "Votre commande est en cours de livraison",
                      currentStep >= 1,
                      currentStep > 1 || isFinished,
                    ),
                    SizedBox(height: 24),
                    _buildTimelineStep(
                      "Livré",
                      "Votre commande a été livrée avec succès",
                      currentStep >= 2,
                      isFinished,
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Info supplémentaire (à adapter selon vos besoins)
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pour plus de détails, contactez notre service client',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(String title, String description, bool isActive, bool isCompleted) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? (isCompleted ? Colors.green : primaryColor)
                      : Colors.grey,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: isActive ? Colors.black54 : Colors.grey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        if (isCompleted)
          Icon(Icons.check_circle, color: Colors.green, size: 20),
      ],
    );
  }
}