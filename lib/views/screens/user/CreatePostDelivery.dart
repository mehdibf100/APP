import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:pfe/services/mapService.dart';
import 'package:pfe/utils/api_const.dart';
import 'package:pfe/utils/colors.dart';
import 'package:get/get.dart'; // Added for translations
import '../../../models/PackageItem.dart';

class CreateDeliveryScreen extends StatefulWidget {
  final String userId;
  const CreateDeliveryScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _CreateDeliveryScreenState createState() => _CreateDeliveryScreenState();
}

class _CreateDeliveryScreenState extends State<CreateDeliveryScreen> {
  // Package form controllers
  final TextEditingController _packageNameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  // Location controllers
  final TextEditingController _pickupAddressController = TextEditingController();
  final TextEditingController _deliveryAddressController = TextEditingController();

  // Coordinates stored as "lat,lng"
  String? _pickupCoordinates;
  String? _deliveryCoordinates;
  final MapService mapService = MapService();

  // Date controller
  final TextEditingController _deliveryDateController = TextEditingController();
  DateTime? selectedDate;

  // OpenCage API key
  final String _apiKey = '4712826713974fb7871eced09286ff76';

  // Autocomplete suggestions state
  List<Map<String, dynamic>> _originSuggestions = [];
  List<Map<String, dynamic>> _destinationSuggestions = [];
  Timer? _debounceOrigin;
  Timer? _debounceDestination;

  // Delivery data
  List<PackageItem> packages = [];
  bool _isLoading = false;
  bool _showParcelDetails = true;
  bool _showPrediction = false;
  double _totalPredictedPrice = 0;
  bool _isPredicting = false;

  @override
  void dispose() {
    _packageNameController.dispose();
    _weightController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _pickupAddressController.dispose();
    _deliveryAddressController.dispose();
    _deliveryDateController.dispose();
    _debounceOrigin?.cancel();
    _debounceDestination?.cancel();
    super.dispose();
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2025, 12),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _deliveryDateController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _searchLocation(String query, bool isOrigin) async {
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
        final List results = data['results'] as List;
        setState(() {
          if (isOrigin) _originSuggestions = List<Map<String, dynamic>>.from(results);
          else _destinationSuggestions = List<Map<String, dynamic>>.from(results);
        });
      }
    } catch (_) {}
  }

  Widget _buildAutoCompleteField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required bool isOrigin,
  }) {
    final suggestions = isOrigin ? _originSuggestions : _destinationSuggestions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.tr,
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: (value) {
            if (isOrigin) {
              _debounceOrigin?.cancel();
              _debounceOrigin = Timer(const Duration(milliseconds: 500), () {
                _searchLocation(value, true);
              });
            } else {
              _debounceDestination?.cancel();
              _debounceDestination = Timer(const Duration(milliseconds: 500), () {
                _searchLocation(value, false);
              });
            }
          },
          decoration: InputDecoration(
            hintText: hint.tr,
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final item = suggestions[index];
                final formatted = item['formatted'] as String;
                final lat = item['geometry']['lat'];
                final lng = item['geometry']['lng'];
                return ListTile(
                  title: Text(formatted, style: GoogleFonts.poppins(fontSize: 14)),
                  onTap: () {
                    setState(() {
                      controller.text = formatted;
                      final coords = '${lat.toString()},${lng.toString()}';
                      if (isOrigin) {
                        _pickupCoordinates = coords;
                        _originSuggestions = [];
                      } else {
                        _deliveryCoordinates = coords;
                        _destinationSuggestions = [];
                      }
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

  void _addPackage() {
    if (_packageNameController.text.isEmpty ||
        _weightController.text.isEmpty ||
        _heightController.text.isEmpty ||
        _widthController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veuillez remplir tous les détails du colis'.tr)));
      return;
    }
    setState(() {
      packages.add(PackageItem(
        title: _packageNameController.text,
        weight: double.parse(_weightController.text),
        width: double.parse(_widthController.text),
        height: double.parse(_heightController.text),
      ));
      _packageNameController.clear();
      _weightController.clear();
      _widthController.clear();
      _heightController.clear();
      _showParcelDetails = false;
    });
  }

  void _removePackage(int index) => setState(() => packages.removeAt(index));

  Future<void> _onNextPressed() async {
    if (_pickupCoordinates == null || _deliveryCoordinates == null || packages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Veuillez sélectionner les lieux et ajouter au moins un colis'.tr)),
      );
      return;
    }
    setState(() => _isPredicting = true);
    try {
      final originParts = _pickupCoordinates!.split(',');
      final destParts = _deliveryCoordinates!.split(',');
      final originLat = double.parse(originParts[0]);
      final originLng = double.parse(originParts[1]);
      final destLat = double.parse(destParts[0]);
      final destLng = double.parse(destParts[1]);
      final distanceKm = Geolocator.distanceBetween(originLat, originLng, destLat, destLng) / 1000;

      final predictionFutures = packages.map((pkg) async {
        final payload = {
          'distance_km': distanceKm,
          'width_cm': pkg.width,
          'height_cm': pkg.height,
          'weight_kg': pkg.weight,
        };
        final resp = await http.post(
          Uri.parse('https://price-prediction-production-7281.up.railway.app/predict'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );
        if (resp.statusCode == 200) {
          return jsonDecode(resp.body)['predicted_price'] as double;
        } else {
          throw Exception('Erreur de prédiction pour le colis ${pkg.title}');
        }
      }).toList();

      final predictedPrices = await Future.wait(predictionFutures);
      final totalPrice = predictedPrices.fold(0.0, (sum, price) => sum + price);

      setState(() {
        _totalPredictedPrice = totalPrice;
        _showPrediction = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'.tr)),
      );
    } finally {
      setState(() => _isPredicting = false);
    }
  }

  Future<void> _createDelivery() async {
    if (_pickupCoordinates == null || _deliveryCoordinates == null || packages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Veuillez sélectionner des lieux valides et ajouter au moins un colis'
                  .tr),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);

    final postData = {
      'clientId': widget.userId,
      'fromAdresse': _pickupCoordinates,
      'toAdresse': _deliveryCoordinates,
      'cout': _totalPredictedPrice,
      'packageItems': packages.map((p) => p.toJson()).toList(),
    };

    try {
      final res = await http.post(
        Uri.parse(ApiConst.createPostClientApi),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(postData),
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Livraison créée avec succès'.tr)));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : ${res.statusCode}'.tr)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de connexion : $e'.tr)));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Create Delivery'.tr,
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _showPrediction ? _buildPredictionView() : _buildFormView(),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (_showPrediction) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _showPrediction = false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Retour'.tr,
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createDelivery,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : Text('Post'.tr,
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white)),
                ),
              ),
            ] else ...[
              Expanded(
                child: ElevatedButton(
                  onPressed: packages.isEmpty || _isPredicting ? null : _onNextPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isPredicting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : Text('Suivant'.tr,
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF2F2FF),
                    foregroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Annuler'.tr,
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAutoCompleteField(
          label: 'Origine',
          hint: 'Ajouter un lieu',
          icon: Icons.search,
          controller: _pickupAddressController,
          isOrigin: true,
        ),
        const SizedBox(height: 12),
        _buildAutoCompleteField(
          label: 'Destination',
          hint: 'Ajouter un lieu',
          icon: Icons.search,
          controller: _deliveryAddressController,
          isOrigin: false,
        ),
        const SizedBox(height: 12),
        Text("Date".tr,
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Text(
                  selectedDate != null
                      ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                      : 'Sélectionner une date'.tr,
                  style: GoogleFonts.poppins(
                      color: selectedDate != null ? Colors.black : Colors.grey[600],
                      fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Détails des colis'.tr,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
            if (!_showParcelDetails)
              TextButton.icon(
                onPressed: () => setState(() => _showParcelDetails = true),
                icon: const Icon(Icons.add_circle_outline, color: primaryColor, size: 18),
                label: Text('Ajouter un colis'.tr,
                    style: GoogleFonts.poppins(color: primaryColor)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_showParcelDetails) ...[
          _buildParcelField(controller: _packageNameController, hint: 'Titre'.tr),
          const SizedBox(height: 12),
          _buildParcelField(
              controller: _weightController,
              hint: 'Poids (kg)'.tr,
              keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          _buildParcelField(
              controller: _heightController,
              hint: 'Hauteur (cm)'.tr,
              keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          _buildParcelField(
              controller: _widthController,
              hint: 'Largeur (cm)'.tr,
              keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addPackage,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Ajouter le colis'.tr,
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
            ),
          ),
        ],
        if (packages.isNotEmpty) ...[
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: packages.length,
            itemBuilder: (context, index) {
              final pkg = packages[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pkg.title,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(
                            'Poids: ${pkg.weight}kg, H: ${pkg.height}cm, L: ${pkg.width}cm'.tr,
                            style: GoogleFonts.poppins(
                                color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                      onPressed: () => _removePackage(index),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
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
              Text(
                'Estimation du prix'.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 32),
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
                        "$_totalPredictedPrice",
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
                      title: 'Distance'.tr,
                      value: '10.5 km',
                    ),
                    const Divider(height: 16),
                    _buildDetailRow(
                      icon: Icons.straighten,
                      title: 'Dimensions'.tr,
                      value: '30 × 20 cm',
                    ),
                    const Divider(height: 16),
                    _buildDetailRow(
                      icon: Icons.scale,
                      title: 'Poids'.tr,
                      value: '2.5 kg',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                        'Ce prix est une estimation basée sur les dimensions et le poids du colis.'
                            .tr,
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
      ],
    );
  }

  Widget _buildParcelField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint.tr,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
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
              title.tr,
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
}