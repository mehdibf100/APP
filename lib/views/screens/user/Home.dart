import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:pfe/views/screens/user/CreatePostDelivery.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../OnBoardingScreens/Notification.dart';
import '../transporter/CreateAnnouncementScreen.dart';
import 'GoogleMapScreen.dart';
import 'ClaimsScreen.dart';

class Home extends StatefulWidget {
  final String userId;
  const Home({super.key, required this.userId});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String _selectedRole = 'USER';
  int _notificationCount = 3;

  Future<void> _loadSelectedRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedRole = prefs.getString('selectedRole') ?? 'USER';
    });
  }

  @override
  void initState() {
    super.initState();
    _loadSelectedRole();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: RefreshIndicator(
          color: Colors.blue,
          onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildWelcomeSection(),
                _buildQuickActions(),
                _buildRecentActivity(),
                const SizedBox(height: 70),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => _selectedRole == "USER"
                  ? CreateDeliveryScreen(userId: widget.userId)
                  : CreateAnnouncementScreen(userId: widget.userId),
            ),
          );
        },
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _selectedRole == "USER" ? 'Nouvelle livraison' : 'Nouvelle annonce',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        elevation: 4,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bonjour,'.tr, style: TextStyle(fontSize: 15, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text(
                _selectedRole == "USER" ? 'Client' : 'Transporteur',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.blue, size: 26),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => NotificationSreen(userId: widget.userId)),
                    ),
                  ),
                  if (_notificationCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          '$_notificationCount',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue[100],
                  border: Border.all(color: Colors.blue.shade200, width: 2),
                  boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 5)],
                ),
                child: Center(child: Lottie.asset('assets/animations/avatar.json', height: 32)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade500, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child:  Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: Colors.white, size: 14),
                    SizedBox(width: 5),
                    Text(
                      'Express Delivery'.tr,
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
           Text(
            'Bienvenue sur Express Delivery'.tr,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedRole == "USER"
                ? 'Envoyez vos colis en toute sécurité et suivez leur progression.'.tr
                : 'Trouvez des opportunités de livraison et optimisez vos trajets.'.tr,
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OpenStreetMapScreen(userId: widget.userId)),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.explore, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Explorer les opportunités'.tr,
                    style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.local_shipping,
        'label': 'Livraisons'.tr,
        'color': Colors.orange,
        'screen': null,
      },
      {
        'icon': Icons.history,
        'label': 'Historique'.tr,
        'color': Colors.green,
        'screen': null,
      },
      {
        'icon': Icons.book_rounded,
        'label': 'Réclamations'.tr,
        'color': Colors.red,
        'screen': (String userId) => ClaimScreen(userId: widget.userId),
      },
      {
        'icon': Icons.location_on,
        'label': 'Suivi'.tr,
        'color': Colors.purple,
        'screen': null,
      },
    ];


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                'Actions rapides'.tr,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {},
                child:  Text('Voir tout'.tr, style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            physics: const BouncingScrollPhysics(),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return InkWell(
                onTap: () {
                  final dynamic screenBuilder = action['screen'];
                  if (screenBuilder is Function) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => screenBuilder(widget.userId),
                      ),
                    );
                  }
                },

                child: Container(
                  width: 100,
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (action['color'] as Color).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(action['icon'] as IconData, color: action['color'] as Color),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        action['label'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                'Activités récentes'.tr,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 12, color: Colors.blue[700]),
                    const SizedBox(width: 4),
                    Text('À jour'.tr, style: TextStyle(fontSize: 12, color: Colors.blue[700])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  _selectedRole == "USER"
                      ? "Vous n'avez pas encore de livraisons actives".tr
                      : "Aucune livraison disponible pour le moment".tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _selectedRole == "USER"
                            ? CreateDeliveryScreen(userId: widget.userId)
                            : OpenStreetMapScreen(userId: widget.userId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    _selectedRole == "USER" ? 'Créer une livraison'.tr : 'Explorer les opportunités'.tr,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Lottie.asset('assets/animations/camion.json', height: 150),
          ),
        ],
      ),
    );
  }
}