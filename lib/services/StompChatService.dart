import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

class StompChatService {
  final String socketUrl = 'wss://pfe-project-backend-production.up.railway.app/ws';
  late StompClient client;
  Function(dynamic message)? onMessageReceived;

  void initClient({
    required Function(dynamic message) onMessage,
    required int conversationId,
  }) {
    onMessageReceived = onMessage;
    client = StompClient(
      config: StompConfig(
        url: socketUrl,
        onConnect: (StompFrame frame) {
          client.subscribe(
            destination: '/topic/conversation/$conversationId',
            callback: (StompFrame frame) {
              if (frame.body != null) {
                onMessageReceived!(jsonDecode(frame.body!));
              }
            },
          );
        },
        onWebSocketError: (dynamic error) => print('WebSocket error: $error'),
      ),
    );
    client.activate();
  }

  // Ajout des paramètres imageUrl et messageType
  void sendMessage(String clientId, String livreurId, String sender, String content,
      {String? imageUrl, String messageType = "text"}) {
    final message = {
      "clientId": clientId,
      "livreurId": livreurId,
      "sender": sender,
      "content": content,
      "imageUrl": imageUrl ?? "",
      "messageType": messageType,
    };
    client.send(
      destination: '/app/chat.sendMessage',
      body: jsonEncode(message),
    );
  }

  void disconnect() {
    client.deactivate();
  }
}
