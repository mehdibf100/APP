// models/Order.dart

import 'DeliveryRequestTransporter.dart';
import 'PackageItem.dart';

class Order {
  final String avatar;
  final String name;
  final String email;  // client name
  final String nameT;               // transporter name
  final String time;
  final String date;
  final int packageId;
  final int phone;
  final int clientId;
  String fromAdresseDelivery;
  String toAdresseDelivery;
  final String estimatedDelivery;
  final double cout;
  final String status;
  final int statusColor;
  final List<PackageItem> packageItems;

  Order({
    required this.avatar,
    required this.clientId,
    required this.name,
    required this.email,
    required this.date,
    required this.nameT,
    required this.phone,
    required this.time,
    required this.packageId,
    required this.fromAdresseDelivery,
    required this.toAdresseDelivery,
    required this.estimatedDelivery,
    required this.cout,
    required this.status,
    required this.statusColor,
    required this.packageItems,
  });

  factory Order.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError('Order.fromJson appelé avec json null');
    }

    // Parsing client info
    final client = json['client'] as Map<String, dynamic>? ?? {};
    final transporter = json['transporteur'] as Map<String, dynamic>? ?? {};

    // Parsing packageItems
    final rawItems = json['packageItems'] as List<dynamic>? ?? [];
    final List<PackageItem> items = rawItems
        .map((e) => PackageItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return Order(
      avatar: json['imageUrl'] as String? ?? 'U',
      name: client['name'] as String? ?? 'Unknown1',
      email: client['email'] as String? ?? 'Unknown2',
      date: json['date'] as String? ?? '2025-01-01',
      clientId: client['id'] is int
          ? client['id'] as int
          : int.tryParse(client['id']?.toString() ?? '') ?? 0,
      nameT: transporter['name'] as String? ?? 'Unknown3',
      phone: transporter['phone'] is int
          ? transporter['phone'] as int
          : int.tryParse(transporter['phone']?.toString() ?? '') ?? 0,
      time: json['time'] as String? ?? '00:00',
      packageId: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      fromAdresseDelivery: json['fromAdresseDelivery'] as String? ?? '',
      toAdresseDelivery: json['toAdresseDelivery'] as String? ?? '',
      estimatedDelivery: json['estimatedDelivery'] as String? ?? '4H',
      cout: (json['cout'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? '',
      statusColor: json['statusColor'] is int
          ? json['statusColor'] as int
          : int.tryParse(json['statusColor']?.toString() ?? '') ?? 0,
      packageItems: items.isNotEmpty
          ? items
          : [PackageItem(title: "No Package", weight: 0.0, width: 0.0, height: 0.0)],
    );
  }
}
