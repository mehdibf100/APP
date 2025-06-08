import 'PackageItem.dart';

class DeliveryRequestCustomer {
  final int id;
  final Transporteur transporteur;
  final PostClient postClient;
  final double cout;
  final String status;
  final String date;
  final String time;
        String fromAdresseDelivery;
        String toAdresseDelivery;
  final List<PackageItem> packageItems;

  DeliveryRequestCustomer({
    required this.id,
    required this.transporteur,
    required this.postClient,
    required this.cout,
    required this.time,
    required this.status,
    required this.date,
    required this.fromAdresseDelivery,
    required this.toAdresseDelivery,
    required this.packageItems,
  });


  factory DeliveryRequestCustomer.fromJson(Map<String, dynamic> json) {
    var packageItemsList = (json['postClient']?['packageItems'] as List<dynamic>?) ?? [];
    List<PackageItem> packageItems = packageItemsList.isNotEmpty
        ? packageItemsList.map((item) => PackageItem.fromJson(item)).toList()
        : [];

    return DeliveryRequestCustomer(
      id: json['id'] ?? 0,
      transporteur: Transporteur.fromJson(json['transporteur'] ?? {}),
      postClient: PostClient.fromJson(json['postClient'] ?? {}),
      cout: (json['cout'] ?? 0).toDouble(),
      status: json['status'] ?? 'Inconnu',
      date: json['date'] ?? '2025-01-01',
      time: json['time'] ?? '00:00',
      fromAdresseDelivery: json['fromAdresseDelivery'] ?? '',
      toAdresseDelivery: json['toAdresseDelivery'] ?? '',
      packageItems: packageItems,
    );
  }

}


class Transporteur {
  int id;
  String name;
  String avatar;
  Transporteur({required this.id,required this.name,required this.avatar});
  factory Transporteur.fromJson(Map<String, dynamic> json) {
    return Transporteur(
      id: json['id'] ?? 0,
      name:json['name'] ?? "Transporter",
      avatar:json['image']??"Transporter"
    );
  }
}

class PostClient {
  PostClient();
  factory PostClient.fromJson(Map<String, dynamic> json) {
    return PostClient();
  }
}