import 'package:flutter/material.dart';
import 'package:pfe/utils/colors.dart';

import 'DeliveryRequestCustomer.dart';
import 'DeliveryTrackUserScreen.dart';
import 'MyDeliveryRequestCustomerScreen.dart';

class Clientdelivery extends StatefulWidget {
  final String userId;

  const Clientdelivery({super.key, required this.userId});

  @override
  State<Clientdelivery> createState() => _ClientdeliveryState();
}

class _ClientdeliveryState extends State<Clientdelivery> {
  GlobalKey<ScaffoldState> scaffoldKey=GlobalKey();
  @override
  Widget build(BuildContext context) {
    return  DefaultTabController(length: 3, child: Scaffold(
      key: scaffoldKey,
      appBar: AppBar(title: Text("Deliveries"),bottom: TabBar(
        unselectedLabelStyle: TextStyle(color: Colors.grey),
        labelColor: Colors.blue,
        indicatorColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          tabs:[
            Tab(child: Text("Delivery in Progress"),),
            Tab(child:Text("My Delivery request",)),
            Tab(child:Text("Delivery request",)),
      ]),),
      body:TabBarView(children: [
        DeliveryTrackUserScreen(userId: widget.userId,),
        MyDeliveryRequestCustomerScreen(userId: widget.userId,),
        DeliveryRequestCustomerScreen(userId: widget.userId,)
      ])
    ));
  }
}
