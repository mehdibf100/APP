import 'package:flutter/material.dart';
import 'package:pfe/utils/colors.dart';

class ChatBubble extends StatelessWidget {
  final dynamic message;
  final bool isMe;
  final String time;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.time,
  }) : super(key: key);

  Widget _buildMessageContent() {
    if (message['messageType'] == 'image' &&
        message['imageUrl'] != null &&
        message['imageUrl'] != "") {
      return Image.network(
        message['imageUrl'],
        width: 200,
        height: 200,
        fit: BoxFit.cover,
      );
    } else {
      return Text(
        message['content'] ?? '',
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black87,
          fontSize: 16,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe ? primaryColor : Colors.grey.shade300;
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                bottomRight: isMe ? Radius.zero : const Radius.circular(12),
              ),
            ),
            child: _buildMessageContent(),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
