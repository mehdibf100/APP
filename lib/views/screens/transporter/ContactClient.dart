import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pfe/services/mapService.dart';
import 'package:pfe/utils/api_const.dart';
import 'package:pfe/views/screens/transporter/TransporterHomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfe/models/Order.dart';
import 'package:latlong2/latlong.dart' as latlong;

import '../user/Home.dart';
class Contactclient extends StatefulWidget {
  final String postId;
  const Contactclient({super.key, required this.postId});

  @override
  State<Contactclient> createState() => _ContactclientState();
}

class _ContactclientState extends State<Contactclient> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _coutController = TextEditingController();
  final TextEditingController _origineController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final detailsController = TextEditingController();  final departureController = TextEditingController();
  final destinationController = TextEditingController();

  // Autocomplete suggestions
  List<Map<String, dynamic>> _originSuggestions = [];
  List<Map<String, dynamic>> _destinationSuggestions = [];
  Timer? _debounceOrigin;
  Timer? _debounceDestination;
  final String _apiKey = '4712826713974fb7871eced09286ff76';

  Order? postTransporter;
  Order? postTransporterLocation;

  String errorMessage = "";
  List<Map<String, String>> addedPackages = [];
  bool _isLoading = false;
  String userId = '';
  final MapService mapService=new MapService();



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
  @override
  void initState() {
    super.initState();
    _loadUserId();
    fetchPostTransporter();
  }
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => userId = prefs.getString('userId') ?? '');
  }

  Future<void> fetchPostTransporter() async {
    try {
      final url = Uri.parse(
          'https://pfe-project-backend-production.up.railway.app/api/v1/postClient/id/${widget.postId}');
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        postTransporterLocation = Order.fromJson(data);
        final transporter = Order.fromJson(data);
        postTransporter = transporter;
        await mapService.resolvePlaceNames(postTransporter!);
        setState(() {
          postTransporter = transporter;
          errorMessage = "";
        });
      } else {
        setState(() => errorMessage = "Erreur : ${response.body}");
      }
    } catch (e) {
      setState(() => errorMessage = "Erreur de connexion: $e");
    }
  }

  @override
  void dispose() {
    _coutController.dispose();
    _timeController.dispose();
    _destinationController.dispose();
    _origineController.dispose();
    _debounceOrigin?.cancel();
    _debounceDestination?.cancel();
    super.dispose();
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
          if (isOrigin) {
            _originSuggestions = List<Map<String, dynamic>>.from(results);
          } else {
            _destinationSuggestions = List<Map<String, dynamic>>.from(results);
          }
        });
      }
    } catch (e) {
      // ignore errors
    }
  }

  Widget _buildAutoCompleteField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required bool isOrigin,
  }) {
    final suggestions = isOrigin ? _originSuggestions : _destinationSuggestions;
    final Color iconColor = isOrigin ? Colors.green.shade600 : Colors.red.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500
            )),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextField(
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
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: Icon(icon, color: iconColor),
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
                borderSide: BorderSide(color: iconColor, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            style: GoogleFonts.poppins(fontSize: 13),
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final item = suggestions[index];
                final display = item['formatted'] ?? '';
                return ListTile(
                  dense: true,
                  title: Text(display,
                      style: GoogleFonts.poppins(fontSize: 12)
                  ),
                  onTap: () {
                    setState(() {
                      controller.text = display;
                      if (isOrigin) _originSuggestions = [];
                      else _destinationSuggestions = [];
                    });
                  },
                );
              },
            ),
          ),
        ]
      ],
    );
  }

  Future<latlong.LatLng?> _getCoordinates(String place) async {
    final uri = Uri.parse(
        'https://api.opencagedata.com/geocode/v1/json?q=${Uri.encodeComponent(place)}&key=$_apiKey&limit=1');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final List results = data['results'];
      if (results.isNotEmpty) {
        final geo = results[0]['geometry'] as Map<String, dynamic>;
        return latlong.LatLng(geo['lat'], geo['lng']);
      }
    }
    return null;
  }

  Future<void> _createOrder() async {

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final oCoords = await _getCoordinates(_origineController.text);
    final dCoords = await _getCoordinates(_destinationController.text);
    print("test $oCoords $dCoords");
    if (oCoords == null || dCoords == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text('Lieu introuvable'),
              backgroundColor: Colors.red.shade800,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      return;
    }
    try {
      final orderData = {
        'transporteurId': userId,
        'postClientId': postTransporterLocation!.packageId,
        'clientId': postTransporterLocation!.clientId,
        'fromAdresse': "${oCoords.latitude},${oCoords.longitude}",
        'toAdresse': "${dCoords.latitude},${dCoords.longitude}",
        'cout': int.parse(_coutController.text.trim()),
        'date': postTransporterLocation!.date,
        'time': _timeController.text.trim(),
      };

      final response = await http.post(
        Uri.parse(
            '${ApiConst.createDeliveryRequestCustomerApi}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(orderData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('demande  envoyée avec succès',
                style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TransporterHomePage(userId: userId, userEmail: postTransporter!.email,),
          ),
        );
        // Envoi notification
        try {
          await http.post(
            Uri.parse(ApiConst.sendNotificationApi),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'userId': postTransporter!.clientId,
              'message': 'Tu as une demande de livraison'
            }),
          );
        } catch (_) {}
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${response.statusCode}',
                style: GoogleFonts.poppins()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de connexion : $e',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (postTransporter == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(
            child: CircularProgressIndicator(
              color: Colors.blue,
            )
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
            'Contact Client',
            style: GoogleFonts.poppins(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            )
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                // Infos du transporteur
                _buildTransporterInfo(),
                const SizedBox(height: 16),
                _buildOrderForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderForm() {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.edit_note,
                      color: Colors.blue.shade700,
                      size: 22
                  ),
                  const SizedBox(width: 10),
                  Text('Vos détails',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700
                      )
                  ),
                ],
              ),
              const Divider(height: 30),
              _buildAutoCompleteField(
                label: 'Origine',
                hint: 'Entrez l\'origine',
                icon: Icons.location_on,
                controller: _origineController,
                isOrigin: true,
              ),
              const SizedBox(height: 16),
              _buildAutoCompleteField(
                label: 'Destination',
                hint: 'Entrez la destination',
                icon: Icons.navigation,
                controller: _destinationController,
                isOrigin: false,
              ),
        const SizedBox(height: 16),
        TextField(
          controller: _timeController,
          readOnly: true,
          onTap: () => _selectTime(context),
          decoration: InputDecoration(
            fillColor: Colors.blue,
            labelText: 'Heure de livraison',
            suffixIcon: Icon(Icons.access_time),
            border: OutlineInputBorder(),
          ),),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Coût proposé',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500
                      )
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _coutController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.poppins(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Montant en TND',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: Icon(Icons.monetization_on_outlined, color: Colors.amber.shade700),
                        suffixText: 'TND',
                        suffixStyle: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            color: Colors.black87
                        ),
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
                          borderSide: BorderSide(color: Colors.amber.shade700, width: 1.5),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Entrez un coût';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _createOrder(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5
                    ),
                  )
                      : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.send, size: 18,color: Colors.white,),
                      const SizedBox(width: 8),
                      Text('Contacter Client'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransporterInfo() {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 20, bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.person,
                      color: Colors.blue.shade700, size: 28),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      postTransporter!.name,
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade900
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.verified,
                            size: 14,
                            color: Colors.green.shade600
                        ),
                        const SizedBox(width: 4),
                        Text('Pro Verified',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.green.shade600,
                                fontWeight: FontWeight.w500
                            )
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 30),

            Text('Informations du colis',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800
                )
            ),
            const SizedBox(height: 12),

            ...postTransporter!.packageItems.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12.0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200)
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8)
                          ),
                          child: Icon(Icons.inventory_2_outlined,
                              size: 20,
                              color: Colors.blue.shade700
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(item.title,
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade800
                            )
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildSpecItem(Icons.scale, '${item.weight.toStringAsFixed(1)} kg'),
                        _buildSpecItem(Icons.height, '${item.height.toStringAsFixed(1)} cm'),
                        _buildSpecItem(Icons.straighten, '${item.width.toStringAsFixed(1)} cm'),
                      ],
                    )
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 16),

            // Info prix, adresses et date
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                      Icons.monetization_on,
                      'Prix proposé',
                      '${postTransporter!.cout} TND',
                      Colors.amber.shade700
                  ),
                  const Divider(height: 16),
                  _buildInfoRow(
                      Icons.location_on,
                      'Origine',
                      postTransporter!.fromAdresseDelivery,
                      Colors.green.shade600
                  ),
                  const Divider(height: 16),
                  _buildInfoRow(
                      Icons.navigation,
                      'Destination',
                      postTransporter!.toAdresseDelivery,
                      Colors.red.shade600
                  ),
                  const Divider(height: 16),
                  _buildInfoRow(
                      Icons.calendar_today,
                      'Date',
                      _formatDate(DateTime.parse(postTransporter!.date)),
                      Colors.purple.shade600
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(text,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade700
              )
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500
                )
            ),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900
                )
            ),
          ],
        )
      ],
    );
  }
}