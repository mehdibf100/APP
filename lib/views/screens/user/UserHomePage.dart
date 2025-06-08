import 'package:flutter/material.dart';
import 'package:pfe/views/screens/chat/MessengerScreen.dart';
import 'package:pfe/views/screens/user/ClientDelivery.dart';
import 'Home.dart';
import 'Profile.dart';

class UserHomepage extends StatefulWidget {
  final String userEmail;
  final String userId;

  const UserHomepage({Key? key, required this.userEmail, required this.userId}) : super(key: key);

  @override
  State<UserHomepage> createState() => _UserHomepageState();
}

class _UserHomepageState extends State<UserHomepage> {
  int _selectedIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      Home(userId: widget.userId),
      Clientdelivery(userId: widget.userId),
      ConversationsScreen(userId: widget.userId,),
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Livraisons'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}