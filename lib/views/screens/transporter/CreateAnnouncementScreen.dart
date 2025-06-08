import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pfe/utils/api_const.dart';
import 'package:get/get.dart'; // Added for translations

class CreateAnnouncementScreen extends StatefulWidget {
  final String userId;
  const CreateAnnouncementScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _CreateAnnouncementScreenState createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  // Vehicle selection
  String selectedVehicle = 'Car';

  // Controllers
  final departureController = TextEditingController();
  final destinationController = TextEditingController();
  final dateController = TextEditingController();
  final detailsController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  bool _isSubmitting = false;

  // Autocomplete suggestions
  final String _apiKey = '4712826713974fb7871eced09286ff76';
  List<Map<String, dynamic>> _originSuggestions = [];
  List<Map<String, dynamic>> _destinationSuggestions = [];
  Timer? _debounceOrigin;
  Timer? _debounceDestination;

  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      // Format l'heure sous forme HH:mm (ex: 14:30)
      final formattedTime = pickedTime.format(context);
      _timeController.text = formattedTime;
    }
  }

  // Coordinates stored as "lat,lng"
  String? _departureCoordinates;
  String? _destinationCoordinates;

  @override
  void dispose() {
    departureController.dispose();
    destinationController.dispose();
    dateController.dispose();
    detailsController.dispose();
    _timeController.dispose();
    _debounceOrigin?.cancel();
    _debounceDestination?.cancel();
    super.dispose();
  }

  // Theme constants - Simple and minimal
  final _primaryColor = const Color(0xFF3498DB); // Simple blue
  final _accentColor = const Color(0xFF2ECC71); // Simple green

  // Fetch location suggestions - functionality preserved
  Future<void> _searchLocation(String query, bool isOrigin) async {
    if (query.isEmpty) {
      setState(() {
        if (isOrigin) _originSuggestions = [];
        else _destinationSuggestions = [];
      });
      return;
    }
    final uri = Uri.parse(
      'https://api.opencagedata.com/geocode/v1/json?q=${Uri.encodeComponent(query)}&key=$_apiKey&limit=5',
    );
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = (data['results'] as List).cast<Map<String, dynamic>>();
        setState(() {
          if (isOrigin) _originSuggestions = results;
          else _destinationSuggestions = results;
        });
      }
    } catch (e) {
      // ignore errors
    }
  }

  // Simple Autocomplete TextField
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
        Text(
          label.tr,
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: (text) {
            if (isOrigin) {
              _debounceOrigin?.cancel();
              _debounceOrigin = Timer(const Duration(milliseconds: 500), () {
                _searchLocation(text, true);
              });
            } else {
              _debounceDestination?.cancel();
              _debounceDestination = Timer(const Duration(milliseconds: 500), () {
                _searchLocation(text, false);
              });
            }
          },
          decoration: InputDecoration(
            hintText: hint.tr,
            prefixIcon: Icon(
              icon,
              color: isOrigin ? _primaryColor : _accentColor,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isOrigin ? _primaryColor : _accentColor),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
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
                final desc = item['formatted'] as String? ?? '';
                final lat = item['geometry']['lat'];
                final lng = item['geometry']['lng'];
                return ListTile(
                  title: Text(desc, style: GoogleFonts.roboto(fontSize: 14)),
                  onTap: () {
                    setState(() {
                      controller.text = desc;
                      final coords = '$lat,$lng';
                      if (isOrigin) {
                        _departureCoordinates = coords;
                        _originSuggestions = [];
                      } else {
                        _destinationCoordinates = coords;
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

  // Simple InputField (for date/details)
  Widget _buildInputField(
      String label,
      String hint,
      IconData icon,
      TextEditingController controller,
      Color iconColor, {
        int maxLines = 1,
        bool isDate = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.tr,
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: isDate,
          onTap: isDate
              ? () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: ThemeData.light().copyWith(
                    colorScheme: ColorScheme.light(
                      primary: _primaryColor,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              controller.text = DateFormat('dd/MM/yyyy').format(picked);
            }
          }
              : null,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint.tr,
            prefixIcon: Icon(icon, color: iconColor),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: iconColor),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  // Submit form - functionality preserved
  Future<void> _submitForm() async {
    if (_departureCoordinates == null ||
        _destinationCoordinates == null ||
        dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez renseigner tous les champs obligatoires'.tr),
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final date = DateFormat('dd/MM/yyyy').parse(dateController.text);
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final postData = {
        'transporteurId': widget.userId,
        'typeVehicule': selectedVehicle,
        'fromAdresse': _departureCoordinates,
        'toAdresse': _destinationCoordinates,
        'date': formattedDate,
        'time': _timeController.text.trim(),
        'description': detailsController.text,
      };
      final resp = await http.post(
        Uri.parse(ApiConst.createPostTransporterApi),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(postData),
      );
      if (resp.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Annonce publiée avec succès!'.tr),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${resp.body}'.tr)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'.tr)),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        title: Text(
          'Créer une annonce'.tr,
          style: GoogleFonts.roboto(
              fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location Card
            Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Itinéraire'.tr,
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAutoCompleteField(
                      label: 'Point de départ',
                      hint: 'Entrez le lieu de départ',
                      icon: Icons.location_on,
                      controller: departureController,
                      isOrigin: true,
                    ),
                    const SizedBox(height: 16),
                    _buildAutoCompleteField(
                      label: 'Destination',
                      hint: 'Entrez la destination',
                      icon: Icons.location_on,
                      controller: destinationController,
                      isOrigin: false,
                    ),
                  ],
                ),
              ),
            ),

            // Details Card
            Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations supplémentaires'.tr,
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      'Date de livraison',
                      'Sélectionnez une date',
                      Icons.calendar_today,
                      dateController,
                      _primaryColor,
                      isDate: true,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _timeController,
                      readOnly: true,
                      onTap: () => _selectTime(context),
                      decoration: InputDecoration(
                        fillColor: Colors.blue,
                        labelText: 'Heure de livraison'.tr,
                        suffixIcon: Icon(Icons.access_time),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      'Détails supplémentaires',
                      'Ajoutez des informations concernant la livraison',
                      Icons.notes,
                      detailsController,
                      Colors.grey,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  'Publier l\'annonce'.tr,
                  style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}