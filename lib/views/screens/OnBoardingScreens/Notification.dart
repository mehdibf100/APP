import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pfe/utils/api_const.dart';
import '../../../models/NotificationModel.dart';

class NotificationSreen extends StatefulWidget {
  final String userId;
  const NotificationSreen({super.key, required this.userId});

  @override
  State<NotificationSreen> createState() => _NotificationSreenState();
}

class _NotificationSreenState extends State<NotificationSreen> {
  late Future<List<NotificationModel>> _futureNotifications;
  bool read=false;
  @override
  void initState() {
    super.initState();
    _futureNotifications = fetchNotifications(widget.userId);   // déclenchement initial :contentReference[oaicite:9]{index=9}
  }
  Future<List<NotificationModel>> fetchNotifications(String userId) async {
    final response = await http.get(
      Uri.parse('${ApiConst.sendNotificationApi}/$userId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } else {
      throw Exception('Échec du chargement des notifications');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<NotificationModel>>(
        future: _futureNotifications,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());  // état chargement :contentReference[oaicite:10]{index=10}
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune notification')); // empty state :contentReference[oaicite:11]{index=11}
          } else {
            final notifications = snapshot.data!;
            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: ListTile(
                      leading: Icon(
                        read ? Icons.mark_email_read : Icons.mark_email_unread,
                      ),                       // icône read/unread :contentReference[oaicite:12]{index=12}
                      title: Text(
                        notif.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${notif.timestamp.toLocal()}'
                            .split('.')[0],    // format local sans millisecondes :contentReference[oaicite:13]{index=13}
                      ),
                      trailing: read
                          ? null
                          : const Icon(Icons.fiber_new, color: Colors.red),
                      onTap: () {
                        setState(() {
                          read = true;     // marquer comme lu localement :contentReference[oaicite:14]{index=14}
                        });
                      },
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
