class NotificationModel {
  final int id;
  final String userId;
  final String message;
  final DateTime timestamp;


  NotificationModel({
    required this.id,
    required this.userId,
    required this.message,
    required this.timestamp,

  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['userId'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp'])      // format ISO 8601 :contentReference[oaicite:6]{index=6}

    );
  }
}
