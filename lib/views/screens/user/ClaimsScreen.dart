import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:pfe/utils/api_const.dart';

class Claim {
  final String description;
  final String? answer;

  Claim({required this.description, this.answer});

  factory Claim.fromJson(Map<String, dynamic> json) {
    return Claim(
      description: json['description'],
      answer: json['answer'],
    );
  }
}

class ClaimScreen extends StatefulWidget {
  final String userId;

  const ClaimScreen({super.key, required this.userId});

  @override
  State<ClaimScreen> createState() => _ClaimScreenState();
}

class _ClaimScreenState extends State<ClaimScreen> {
  late Future<List<Claim>> futureClaims;

  @override
  void initState() {
    super.initState();
    futureClaims = fetchClaims(widget.userId);
  }

  Future<List<Claim>> fetchClaims(String userId) async {
    final response = await http.get(
      Uri.parse('${ApiConst.getClaimByUserIdApi}$userId'),
    );

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      return body.map((item) => Claim.fromJson(item)).toList();
    } else {
      throw Exception('Erreur de chargement des réclamations');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Réclamations'),
      ),
      body: FutureBuilder<List<Claim>>(
        future: futureClaims,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune réclamation trouvée.'));
          } else {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final claim = snapshot.data![index];
                return Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Description:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(claim.description),
                        const SizedBox(height: 12),
                        const Text(
                          'Réponse:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          claim.answer ?? 'Pas encore de réponse.',
                          style: TextStyle(
                            color: claim.answer != null ? Colors.black : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}