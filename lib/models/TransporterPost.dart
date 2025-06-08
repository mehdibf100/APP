class Transport {
  final int transporterId;
  final int id;
  final String time;

  final String name;
  final String status;
  final String email;
  final String vehicleType;
   String origin;
   String destination;
  final String date;

  Transport( {
    required this.transporterId,
    required this.id,
    required this.name,
    required this.email,
    required this.time,
    required this.status,
    required this.vehicleType,
    required this.origin,
    required this.destination,
    required this.date,
  });

  // Method to create Transport instance from JSON
  factory Transport.fromJson(Map<String, dynamic> json) {
    return Transport(
      transporterId: json['transporteur']['id'] ?? "Inconnu",
      id: json['id'] ?? "Inconnu",
      name: json['transporteur']?["name"] ?? "Inconnu",
      email: json['transporteur']?["email"] ?? "Inconnu",
      status: json['status'] ?? "Inconnu",
      vehicleType: json['typeVehicule'] ?? "Inconnu",
      origin: json['fromAdresseDelivery'] as String?? "Inconnu",
      destination: json['toAdresseDelivery'] as String?? "Inconnu",
      date: json['date'] ?? "Inconnu",
      time: json['time'] ?? "Inconnu",
    );
  }

}