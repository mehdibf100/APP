import 'package:flutter/material.dart';
import '../../services/userService.dart';
import '../screens/chat/ChatDetailScreen.dart';

class ConversationTile extends StatelessWidget {
  final dynamic conversation;
  final VoidCallback onTap;
  final String currentUserId;
  final UserService userApiService = UserService();

  ConversationTile({
    Key? key,
    required this.conversation,
    required this.onTap,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String otherUserId = conversation['clientId'] == currentUserId
        ? conversation['livreurId']
        : conversation['clientId'];

    // Modification : Vérification si le dernier message est de type image
    String lastMessage = "No messages";
    if (conversation['messages'] != null && conversation['messages'].isNotEmpty) {
      final lastMsg = conversation['messages'].last;
      if (lastMsg['messageType'] != null && lastMsg['messageType'] == 'image') {
        lastMessage = "Image";
      } else {
        lastMessage = lastMsg['content'] ?? "";
      }
    }

    bool hasUnreadMessages = conversation['messages'] != null &&
        conversation['messages'].any((msg) => msg['read'] == false);

    return FutureBuilder<Map<String, dynamic>>(
      future: userApiService.getUserById(otherUserId),
      builder: (context, snapshot) {
        String displayName = otherUserId;
        if (snapshot.hasData) {
          displayName = snapshot.data!['name'] ?? otherUserId;
        }
        return ListTile(
          leading: const CircleAvatar(
            backgroundImage: NetworkImage(
                'https://cdn-icons-png.flaticon.com/512/149/149071.png'),
          ),
          title: Text(
            displayName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                conversation['lastMessageTime'] ?? '',
                style: TextStyle(
                  color: hasUnreadMessages ? Colors.green : Colors.grey,
                  fontSize: 12,
                ),
              ),
              if (hasUnreadMessages)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                )
            ],
          ),
          onTap: onTap,
        );
      },
    );
  }
}
