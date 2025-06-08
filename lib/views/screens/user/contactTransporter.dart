import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pfe/utils/colors.dart';
import 'package:pfe/views/screens/user/Home.dart';
import 'package:pfe/views/screens/user/UserHomePage.dart';
import '../../../models/TransporterPost.dart';
import '../../../utils/api_const.dart';

class ContactTransporter extends StatefulWidget {
  final int postId;
  final String userId;
  const ContactTransporter({super.key, required this.postId, required this.userId});

  @override
  State<ContactTransporter> createState() => _ContactTransporterState();
}

class _ContactTransporterState extends State<ContactTransporter> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _packageNameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  Transport? postTransporter;
  Transport? postTransporterLocation;
  String errorMessage = "";
  List<Map<String, String>> addedPackages = [];
  bool _isLoading = false;

  // Nouvelle gestion d'état pour afficher la prédiction
  bool _showPrediction = false;
  double _predictedPrice = 0;
  Map<String, dynamic>? _lastPayload;

  late double originLat, originLng, destLat, destLng;

  @override
  void initState() {
    super.initState();
    fetchPostTransporter();
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
  Future<void> fetchPostTransporter() async {
    try {
      final url = Uri.parse('${ApiConst.findPostTransporterByIdApi}${widget.postId}');
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        postTransporterLocation = Transport.fromJson(data);
        postTransporter = Transport.fromJson(data);

        final origCoords = postTransporterLocation!.origin.split(',');
        originLat = double.parse(origCoords[0]);
        originLng = double.parse(origCoords[1]);
        final destCoords = postTransporterLocation!.destination.split(',');
        destLat = double.parse(destCoords[0]);
        destLng = double.parse(destCoords[1]);

        await _resolvePlaceNames(postTransporter!);

        setState(() {
          errorMessage = '';
        });
      } else {
        setState(() => errorMessage = 'Erreur : ${response.body}');
      }
    } catch (e) {
      setState(() => errorMessage = 'Erreur de connexion : $e');
    }
  }

  Future<void> _resolvePlaceNames(Transport t) async {
    final results = await Future.wait([
      _reverseGeocode(t.origin),
      _reverseGeocode(t.destination),
    ]);
    t.origin = results[0];
    t.destination = results[1];
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
  void dispose() {
    _packageNameController.dispose();
    _heightController.dispose();
    _widthController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void addPackage() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        addedPackages.add({
          'name': _packageNameController.text,
          'height': _heightController.text,
          'width': _widthController.text,
          'weight': _weightController.text,
        });
        _packageNameController.clear();
        _heightController.clear();
        _widthController.clear();
        _weightController.clear();
      });
    }
  }

  void removePackage(int index) {
    setState(() {
      addedPackages.removeAt(index);
      for (int i = 0; i < addedPackages.length; i++) {
        addedPackages[i]['name'] = 'Colis #${i + 1}';
      }
    });
  }

  Future<void> _onNextPressed() async {
    if (addedPackages.isEmpty) return;
    setState(() => _isLoading = true);

    final distanceKm = Geolocator.distanceBetween(originLat, originLng, destLat, destLng) / 1000;
    final pkg = addedPackages.first;
    final payload = {
      'distance_km': distanceKm,
      'width_cm': double.parse(pkg['width']!),
      'height_cm': double.parse(pkg['height']!),
      'weight_kg': double.parse(pkg['weight']!),
    };

    try {
      final resp = await http.post(
        Uri.parse('https://price-prediction-production-7281.up.railway.app/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (resp.statusCode == 200) {
        final prix = jsonDecode(resp.body)['predicted_price'] as double;
        setState(() {
          _predictedPrice = prix;
          _lastPayload = payload;
          _showPrediction = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur prédiction (${resp.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exception réseau : $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createOrder() async {
    if (addedPackages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter au moins un colis')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final orderData = {
      'transporteurId': postTransporter?.transporterId,
      'clientId': widget.userId,
      'date': postTransporter?.date,
      'time': postTransporter?.time,
      'fromAdresse': postTransporterLocation?.origin,
      'toAdresse': postTransporterLocation?.destination,
      'cout': _predictedPrice,
      'packageItems': addedPackages.map((p) =>
      {
        'title': p['name'],
        'weight': double.tryParse(p['weight']!) ?? 0,
        'width': double.tryParse(p['width']!) ?? 0,
        'height': double.tryParse(p['height']!) ?? 0,
      }).toList(),
    };

    try {
      final response = await http.post(
        Uri.parse(ApiConst.createDeliveryRequestTransporterApi),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 200) {
        try {
          await http.post(
            Uri.parse(ApiConst.sendNotificationApi),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'userId': postTransporter!.transporterId,
              'message': 'Tu as une demande de livraison'
            }),
          );
        } catch (_) {};
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande créée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UserHomepage(userId: widget.userId, userEmail: postTransporter!.email,),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur serveur : ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de connexion : $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Contact Transporteur',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            )
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading && !_showPrediction
            ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: primaryColor),
              SizedBox(height: 16),
              Text('Chargement en cours...', style: TextStyle(color: Colors.grey.shade700)),
            ],
          ),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _showPrediction ? _buildPredictionView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Détails du transporteur
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Icon(Icons.person, color: primaryColor, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          postTransporter?.name ?? 'Transporteur',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.verified, color: primaryColor, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Vérifié Pro',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.location_on,
                      color: Colors.green,
                      title: 'Départ',
                      text: postTransporter?.origin ?? 'Chargement...',
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                    _buildInfoRow(
                      icon: Icons.location_on,
                      color: Colors.red,
                      title: 'Arrivée',
                      text: postTransporter?.destination ?? 'Chargement...',
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      color: primaryColor,
                      title: 'Date',
                      text:_formatDate(DateTime.parse(postTransporter?.date ?? '2025-05-01')),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                    _buildInfoRow(
                      icon: Icons.timelapse,
                      color: Colors.orange,
                      title: 'Tempts',
                      text:postTransporter?.time ?? 'Chargement...',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Formulaire Colis
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory_2, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Détails du Colis',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Nom du colis',
                  controller: _packageNameController,
                  hint: 'Ex: Ordinateur portable',
                  icon: Icons.label,
                  validator: (v) => (v == null || v.isEmpty) ? 'Veuillez entrer un nom' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        label: 'Hauteur (cm)',
                        controller: _heightController,
                        hint: 'Ex: 50',
                        icon: Icons.height,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Obligatoire';
                          return double.tryParse(v) == null ? 'Nombre invalide' : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInputField(
                        label: 'Largeur (cm)',
                        controller: _widthController,
                        hint: 'Ex: 30',
                        icon: Icons.width_full,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Obligatoire';
                          return double.tryParse(v) == null ? 'Nombre invalide' : null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Poids (kg)',
                  controller: _weightController,
                  hint: 'Ex: 5',
                  icon: Icons.scale,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Obligatoire';
                    return double.tryParse(v) == null ? 'Nombre invalide' : null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: addPackage,
                    icon: const Icon(Icons.add,color: Colors.white,),
                    label: const Text('Ajouter le colis'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Liste des colis
        if (addedPackages.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.list_alt, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Colis ajoutés',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListView.separated(
                  itemCount: addedPackages.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final p = addedPackages[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Icon(Icons.inventory_2, color: primaryColor),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p['name']!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'H: ${p['height']} cm, L: ${p['width']} cm, P: ${p['weight']} kg',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => removePackage(i),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

        // Bouton suivant
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: addedPackages.isEmpty ? null : _onNextPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            child: Text(
              'Suivant',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          margin: const EdgeInsets.symmetric(vertical: 24),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Titre
              Text(
                'Estimation du prix',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 32),

              // Prix dans un cercle
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(0.1),
                  border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '7.32',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      Text(
                        'TND',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Détails
              if (_lastPayload != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        icon: Icons.route,
                        title: 'Distance',
                        value: '${_lastPayload!['distance_km'].toStringAsFixed(1)} km',
                      ),
                      const Divider(height: 16),
                      _buildDetailRow(
                        icon: Icons.straighten,
                        title: 'Dimensions',
                        value: '${_lastPayload!['width_cm']} × ${_lastPayload!['height_cm']} cm',
                      ),
                      const Divider(height: 16),
                      _buildDetailRow(
                        icon: Icons.scale,
                        title: 'Poids',
                        value: '${_lastPayload!['weight_kg']} kg',
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Texte informatif
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ce prix est une estimation basée sur sur  les dimensions et le poids du colis.',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Boutons d'action
        Row(
          children: [
            // Bouton Retour
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _showPrediction = false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Retour'),
              ),
            ),
            const SizedBox(width: 16),

            // Bouton Contacter
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: _isLoading
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text('Contacter'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(icon, color: primaryColor, size: 20),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
              borderSide: BorderSide(color: primaryColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor, size: 16),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color color,
    required String title,
    required String text,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}