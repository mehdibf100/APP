
import 'Deliveryrequestcustomer.dart';
import 'PackageItem.dart';

class DeliveryRequestTransporter {
  final String avatar;
  final String name;
  final String time;
  final String date;
  final int packageId;
  final int clientId;
   String fromAdresseDelivery;
   String toAdresseDelivery;
  final String estimatedDelivery;
  final double cout;
  final String status;
  final int statusColor;
  final List<PackageItem> packageItems;

  DeliveryRequestTransporter({
    required this.avatar,
    required this.clientId,
    required this.name,
    required this.time,
    required this.date,
    required this.packageId,
    required this.fromAdresseDelivery,
    required this.toAdresseDelivery,
    required this.estimatedDelivery,
    required this.cout,
    required this.status,
    required this.statusColor,
    required this.packageItems,
  });

  factory DeliveryRequestTransporter.fromJson(Map<String, dynamic> json) {
    var packageItemsList = json['packageItems'] as List<dynamic>? ?? [];
    List<PackageItem> packageItems = packageItemsList.isNotEmpty
        ? packageItemsList.map((item) => PackageItem.fromJson(item)).toList()
        : [PackageItem(title: "No Package", weight: 0.0, width: 0.0, height: 0.0)]; // Default fallback

    return DeliveryRequestTransporter(
      avatar: json['avatar'] ?? "U",
      name: json['client']["name"] ?? 'Unknown',
      clientId: json['client']["id"] ?? 'Unknown',
      time: json['time'] ?? '00:00',
      date: json['date'] ?? '2025-01-01',
      packageId: json['id'] ?? 0,
      fromAdresseDelivery: json['fromAdresseDelivery'] ?? '',
      toAdresseDelivery: json['toAdresseDelivery'] ?? '',
      estimatedDelivery: json['estimatedDelivery'] ?? '4H',
      cout: (json['cout'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      statusColor: json['statusColor'] ?? 0,
      packageItems: packageItems,
    );
  }
}
