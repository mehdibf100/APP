import 'package:flutter/material.dart';


import 'package:pfe/views/screens/transporter/TransporterDelivery.dart';
import 'package:pfe/views/screens/chat/MessengerScreen.dart';
import 'package:pfe/views/screens/user/Home.dart';
import 'package:pfe/views/screens/user/Profile.dart';

class TransporterHomePage extends StatefulWidget {
  final String userEmail;
  final String userId;

  const TransporterHomePage({
    Key? key,
    required this.userEmail,
    required this.userId,
  }) : super(key: key);

  @override
  State<TransporterHomePage> createState() => _TransporterHomePageState();
}

class _TransporterHomePageState extends State<TransporterHomePage> {
  int _selectedIndex = 0;
  late List<Widget> _screens;




  @override
  void initState() {
    super.initState();

    _screens = [
      Home(userId: widget.userId),
      Transporterdelivery(userId: widget.userId),
      ConversationsScreen(userId:  widget.userId,),
      ProfileScreen(Useremail: widget.userEmail),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: false,
        showSelectedLabels: true,
        items: [
          BottomNavigationBarItem(
            icon: Column(
              children: [
                Icon(Icons.home),
                if (_selectedIndex == 0)
                  Container(
                    margin: EdgeInsets.only(top: 4),
                    height: 4,
                    width: 4,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Column(
              children: [
                Icon(Icons.local_shipping),
                if (_selectedIndex == 1)
                  Container(
                    margin: EdgeInsets.only(top: 4),
                    height: 4,
                    width: 4,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            label: 'Livraisons',
          ),
          BottomNavigationBarItem(
            icon: Column(
              children: [
                Icon(Icons.message),
                if (_selectedIndex == 2)
                  Container(
                    margin: EdgeInsets.only(top: 4),
                    height: 4,
                    width: 4,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Column(
              children: [
                Icon(Icons.person_outline),
                if (_selectedIndex == 3)
                  Container(
                    margin: EdgeInsets.only(top: 4),
                    height: 4,
                    width: 4,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
