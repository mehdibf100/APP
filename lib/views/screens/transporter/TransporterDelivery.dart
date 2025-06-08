import 'package:flutter/material.dart';
import 'package:pfe/views/screens/transporter/MyDeliveryRequestTransporterScreen.dart';

import 'DeliveryRequestTranporterScreen.dart';
import 'DeliveryTrackTransporterScreen.dart';


class Transporterdelivery extends StatefulWidget {
  final String userId;

  const Transporterdelivery({super.key, required this.userId});

  @override
  State<Transporterdelivery> createState() => _TransporterdeliveryState();
}

class _TransporterdeliveryState extends State<Transporterdelivery> {
  GlobalKey<ScaffoldState> scaffoldKey=GlobalKey();
  @override
  Widget build(BuildContext context) {
    return  DefaultTabController(length: 3, child: Scaffold(
        key: scaffoldKey,
        appBar: AppBar(title: Text("Transporter Deliveries"),bottom: TabBar(
            unselectedLabelStyle: TextStyle(color: Colors.grey),
            labelColor: Colors.blue,
            indicatorColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs:[
              Tab(child:Text("Deliveries in Progress",)),
              Tab(child:Text("My deliveries requests",)),
              Tab(child: Text("Deliveries requests"),)
            ]),),
        body:TabBarView(children: [
          DeliveryTrackScreen(userId: widget.userId),
          Mydeliveryrequesttransporterscreen(userId: widget.userId),
          DeliveryRequestTransporterScreen(userId: widget.userId)
        ])
    ));
  }
}