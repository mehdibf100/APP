import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'NotificationService.dart';

class WebSocketService {
  StompClient? stompClient;
  final String userId; // ID de l'utilisateur

  WebSocketService(this.userId);

  void connect() {
    // Ajout de userId dans l'URL pour que le handshake l'extraie
    String url = 'wss://pfe-project-backend-production.up.railway.app/ws?userId=$userId';
    stompClient = StompClient(
      config: StompConfig(
        url: url,
        onConnect: (StompFrame frame) {
          print("Connected to WebSocket as user: $userId");
          stompClient?.subscribe(
            destination: '/user/queue/notifications',
            callback: (StompFrame frame) {
              if (frame.body != null) {
                print('Received notification: ${frame.body}');
                NotificationService.showNotification('Nouvelle Notification', frame.body!);
              }
            },
          );
        },
        onWebSocketError: (dynamic error) {
          print("WebSocket Error: $error");
        },
        onDisconnect: (StompFrame? frame) {
          print("WebSocket Disconnected");
        },
      ),
    );
    stompClient?.activate();
  }

  void disconnect() {
    stompClient?.deactivate();
  }
}
