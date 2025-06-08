import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as latlong;
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import '../../../utils/colors.dart';
import '../transporter/Home.dart';
import 'PostClientScreen.dart';

class OpenStreetMapScreen extends StatefulWidget {
  final String userId;
  const OpenStreetMapScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<OpenStreetMapScreen> createState() => _OpenStreetMapScreenState();
}

class _OpenStreetMapScreenState extends State<OpenStreetMapScreen> with SingleTickerProviderStateMixin {
  // Constantes
  static const String _apiKey = '4712826713974fb7871eced09286ff76';
  static const latlong.LatLng _initialPosition = latlong.LatLng(36.8065, 10.1815);

  // Contrôleurs
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final fmap.MapController _mapController = fmap.MapController();
  late AnimationController _animationController;
  late Animation<double> _panelAnimation;

  // Variables d'état
  bool _isSearching = false;
  bool _isTracking = false;
  bool _isPanelExpanded = true;
  String _selectedRole = 'USER';
  DateTime _selectedDate = DateTime.now();

  // Éléments de la carte
  List<fmap.Polyline> _polylines = [];
  List<fmap.Marker> _markers = [];

  // Autocomplétion
  List<Map<String, dynamic>> _originSuggestions = [];
  List<Map<String, dynamic>> _destinationSuggestions = [];
  Timer? _debounceOrigin;
  Timer? _debounceDestination;

  @override
  void initState() {
    super.initState();
    _loadSelectedRole();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // Initialisation de l'animation du panel
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _panelAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Panel initialement déployé
    _animationController.value = 1.0;
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _dateController.dispose();
    _debounceOrigin?.cancel();
    _debounceDestination?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // ===== MÉTHODES PRINCIPALES =====

  // Chargement du rôle utilisateur
  Future<void> _loadSelectedRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedRole = prefs.getString('selectedRole') ?? 'USER';
    });
  }

  // Gestion de l'autocomplétion
  void _onTextChanged(String input, bool isOrigin) {
    final debounce = isOrigin ? _debounceOrigin : _debounceDestination;
    debounce?.cancel();

    final timer = Timer(const Duration(milliseconds: 500), () {
      _fetchSuggestions(input, isOrigin);
    });

    if (isOrigin) {
      _debounceOrigin = timer;
    } else {
      _debounceDestination = timer;
    }
  }

  // Récupération des suggestions d'adresses
  Future<void> _fetchSuggestions(String query, bool isOrigin) async {
    if (query.isEmpty) {
      setState(() {
        if (isOrigin) _originSuggestions = [];
        else _destinationSuggestions = [];
      });
      return;
    }

    final uri = Uri.parse(
        'https://api.opencagedata.com/geocode/v1/json?q=${Uri.encodeComponent(query)}&key=$_apiKey&limit=5');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = List<Map<String, dynamic>>.from(data['results']);
        setState(() {
          if (isOrigin) _originSuggestions = results;
          else _destinationSuggestions = results;
        });
      }
    } catch (e) {
      _showSnackBar('Erreur de connexion', isError: true);
    }
  }

  // Récupération des coordonnées d'une adresse
  Future<latlong.LatLng?> _getCoordinates(String place) async {
    final uri = Uri.parse(
        'https://api.opencagedata.com/geocode/v1/json?q=${Uri.encodeComponent(place)}&key=$_apiKey&limit=1');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final List results = data['results'];
        if (results.isNotEmpty) {
          final geo = results[0]['geometry'] as Map<String, dynamic>;
          return latlong.LatLng(geo['lat'], geo['lng']);
        }
      }
    } catch (e) {
      _showSnackBar('Erreur de connexion', isError: true);
    }
    return null;
  }

  // Recherche d'itinéraire
  Future<void> _searchRoute() async {
    if (_originController.text.isEmpty || _destinationController.text.isEmpty) {
      _showSnackBar('Veuillez remplir tous les champs');
      return;
    }

    setState(() => _isSearching = true);

    // Obtenir les coordonnées
    final originCoords = await _getCoordinates(_originController.text);
    final destinationCoords = await _getCoordinates(_destinationController.text);

    if (originCoords == null || destinationCoords == null) {
      setState(() => _isSearching = false);
      _showSnackBar('Lieu introuvable');
      return;
    }

    // Obtenir l'itinéraire via OSRM
    final url = 'https://router.project-osrm.org/route/v1/driving/'
        '${originCoords.longitude},${originCoords.latitude};'
        '${destinationCoords.longitude},${destinationCoords.latitude}'
        '?overview=full&geometries=geojson';

    try {
      final resp = await http.get(Uri.parse(url));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final coords = data['routes'][0]['geometry']['coordinates'];

        setState(() {
          // Ajouter le polyline avec animation
          _polylines = [
            fmap.Polyline(
              points: coords.map<latlong.LatLng>((c) => latlong.LatLng(c[1], c[0])).toList(),
              strokeWidth: 5,
              color: AppConstants.primaryColor,
            ),
          ];

          // Ajouter les marqueurs
          _markers = [
            _createMarker(originCoords, Icons.trip_origin, Colors.blue),
            _createMarker(destinationCoords, Icons.location_on, Colors.red),
          ];

          _isSearching = false;
          _isTracking = true;
          _isPanelExpanded = false;
          _animationController.reverse();

          // Ajuster la vue de la carte avec animation
          _mapController.fitBounds(
            fmap.LatLngBounds(originCoords, destinationCoords),
            options: const fmap.FitBoundsOptions(padding: EdgeInsets.all(50)),
          );
        });
      } else {
        setState(() => _isSearching = false);
        _showSnackBar('Erreur lors du calcul de l\'itinéraire');
      }
    } catch (e) {
      setState(() => _isSearching = false);
      _showSnackBar('Erreur de connexion');
    }
  }

  // Navigation vers l'écran suivant
  Future<void> _navigateToNextScreen() async {
    if (_originController.text.isEmpty || _destinationController.text.isEmpty) {
      _showSnackBar('Veuillez remplir tous les champs');
      return;
    }

    setState(() => _isSearching = true);

    final originCoords = await _getCoordinates(_originController.text);
    final destinationCoords = await _getCoordinates(_destinationController.text);

    setState(() => _isSearching = false);

    if (originCoords == null || destinationCoords == null) {
      _showSnackBar('Impossible de trouver les coordonnées pour les adresses fournies');
      return;
    }

    final originLatLng = "${originCoords.latitude},${originCoords.longitude}";
    final destinationLatLng = "${destinationCoords.latitude},${destinationCoords.longitude}";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _selectedRole == 'USER'
            ? TransportListScreen(
          origine: originLatLng,
          destination: destinationLatLng,
          date: _dateController.text,
          userId: widget.userId,
        )
            : Postscreen(
          origine: originLatLng,
          destination: destinationLatLng,
          date: _dateController.text,
        ),
      ),
    );
  }

  // ===== MÉTHODES UTILITAIRES =====

  // Affichage d'un message SnackBar
  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade800 : AppConstants.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
        elevation: 8,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Inversion des adresses origine/destination
  void _swapLocations() {
    final tmp = _originController.text;
    setState(() {
      _originController.text = _destinationController.text;
      _destinationController.text = tmp;

      final tmpSuggestions = _originSuggestions;
      _originSuggestions = _destinationSuggestions;
      _destinationSuggestions = tmpSuggestions;
    });
  }

  // Arrêt du suivi d'itinéraire
  void _stopTracking() {
    setState(() {
      _isTracking = false;
      _polylines.clear();
      _markers.clear();
      _isPanelExpanded = true;
      _animationController.forward();
    });
  }

  // Basculement du panel
  void _togglePanel() {
    setState(() {
      _isPanelExpanded = !_isPanelExpanded;
      if (_isPanelExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  // Sélection de date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2025, 12),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppConstants.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppConstants.primaryColor,
              ),
            ),
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // Création d'un marqueur
  fmap.Marker _createMarker(latlng.LatLng point, IconData icon, Color color) {
    return fmap.Marker(
      point: point,
      width: 50,
      height: 50,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 36),
            ),
          );
        },
      ),
    );
  }

  // ===== WIDGETS DE CONSTRUCTION UI =====

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Carte
          _buildMap(),

          // Panel de recherche
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _panelAnimation,
              builder: (context, child) {
                return SizeTransition(
                  sizeFactor: _panelAnimation,
                  axisAlignment: -1,
                  child: _isPanelExpanded ? _buildSearchPanel() : _buildCollapsedPanel(),
                );
              },
            ),
          ),

          // Indicateur de chargement
          if (_isSearching) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // Construction de la carte
  Widget _buildMap() {
    return fmap.FlutterMap(
      mapController: _mapController,
      options: fmap.MapOptions(
        center: _initialPosition,
        zoom: 13.0,
        minZoom: 5.0,
        maxZoom: 18.0,
      ),
      children: [
        fmap.TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.example.app',
        ),
        if (_polylines.isNotEmpty) fmap.PolylineLayer(polylines: _polylines),
        if (_markers.isNotEmpty) fmap.MarkerLayer(markers: _markers),
      ],
    );
  }

  // Construction du panel de recherche déployé
  Widget _buildSearchPanel() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Où allez-vous ?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: Icon(Icons.keyboard_arrow_down),
                onPressed: _togglePanel,
                tooltip: 'Réduire',
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildLocationField(_originController, 'Point de départ', true),
          const SizedBox(height: 16),
          _buildLocationField(_destinationController, 'Destination', false),
          const SizedBox(height: 16),
          _buildDateField(),
          SizedBox(height: 24),
          _buildSearchButtons(),
          SizedBox(height: 16),
          _buildActionButton(),
        ],
      ),
    );
  }

  // Construction du panel réduit
  Widget _buildCollapsedPanel() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLocationLine(Icons.trip_origin, Colors.blue, _originController.text),
                    Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Container(height: 25, width: 1, color: Colors.grey),
                    ),
                    _buildLocationLine(Icons.location_on, Colors.red, _destinationController.text),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.keyboard_arrow_up),
                onPressed: _togglePanel,
                tooltip: 'Développer',
              ),
            ],
          ),
          SizedBox(height: 16),
          _isTracking
              ? Row(
            children: [
              Expanded(child: _buildStopTrackingButton()),
              SizedBox(width: 10),
              Expanded(child: _buildReservationButton()),
            ],
          )
              : _buildExpandPanelButton(),
        ],
      ),
    );
  }

  // Construction d'une ligne d'adresse
  Widget _buildLocationLine(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Construction d'un champ de saisie d'adresse
  Widget _buildLocationField(TextEditingController controller, String label, bool isOrigin) {
    final suggestions = isOrigin ? _originSuggestions : _destinationSuggestions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            onChanged: (value) => _onTextChanged(value, isOrigin),
            decoration: InputDecoration(
              hintText: isOrigin ? 'Saisir le point de départ' : 'Saisir la destination',
              prefixIcon: Icon(
                isOrigin ? Icons.trip_origin : Icons.location_on,
                color: isOrigin ? Colors.blue : Colors.red,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppConstants.primaryColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: suggestions.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                final item = suggestions[index];
                return ListTile(
                  leading: Icon(
                    Icons.location_on_outlined,
                    color: isOrigin ? Colors.blue : Colors.red,
                  ),
                  title: Text(
                    item['formatted'],
                    style: TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  dense: true,
                  onTap: () {
                    setState(() {
                      controller.text = item['formatted'];
                      if (isOrigin) _originSuggestions = [];
                      else _destinationSuggestions = [];
                    });
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  // Construction du champ de date
  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Date",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _dateController,
            readOnly: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.calendar_today,
                color: AppConstants.primaryColor,
              ),
              suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey),
              hintText: 'Choisissez une date',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppConstants.primaryColor, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
            onTap: () => _selectDate(context),
          ),
        ),
      ],
    );
  }

  // Construction des boutons de recherche
  Widget _buildSearchButtons() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: ElevatedButton.icon(
            onPressed: _isSearching ? null : _searchRoute,
            icon: Icon(Icons.directions, color: Colors.white),
            label: Text(
              _isSearching ? 'Recherche...' : 'Itinéraire',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: IconButton(
              icon: Icon(Icons.swap_vert, color: Colors.black87),
              onPressed: _swapLocations,
              tooltip: 'Inverser les adresses',
            ),
          ),
        ),
      ],
    );
  }

  // Construction du bouton d'action principal
  Widget _buildActionButton() {
    return ElevatedButton.icon(
      onPressed: _navigateToNextScreen,
      icon: Icon(
        _selectedRole == 'USER' ? Icons.search : Icons.local_shipping,
        color: Colors.white,
      ),
      label: Text(
        _selectedRole == 'USER' ? 'Trouver un transport' : 'Proposer un trajet',
        style: TextStyle(fontSize: 16, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.secondaryColor,
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        padding: EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  // Construction du bouton d'arrêt de suivi
  Widget _buildStopTrackingButton() {
    return ElevatedButton.icon(
      onPressed: _stopTracking,
      icon: Icon(Icons.close, color: Colors.white),
      label: Text(
        'Arrêter le suivi',
        style: TextStyle(fontSize: 15, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[700],
        padding: EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
      ),
    );
  }

  // Construction du bouton de réservation
  Widget _buildReservationButton() {
    return ElevatedButton.icon(
      onPressed: _navigateToNextScreen,
      icon: Icon(
        _selectedRole == 'USER' ? Icons.search : Icons.local_shipping,
        color: Colors.white,
      ),
      label: Text(
        _selectedRole == 'USER' ? 'Réserver' : 'Proposer',
        style: TextStyle(fontSize: 15, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.secondaryColor,
        padding: EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
      ),
    );
  }

  // Construction du bouton d'expansion du panel
  Widget _buildExpandPanelButton() {
    return ElevatedButton.icon(
      onPressed: _togglePanel,
      icon: Icon(Icons.expand_less, color: Colors.white),
      label: Text(
        'Voir détails',
        style: TextStyle(fontSize: 15, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.primaryColor,
        minimumSize: Size(double.infinity, 45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
      ),
    );
  }

  // Construction de l'overlay de chargement
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                'Recherche en cours...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
