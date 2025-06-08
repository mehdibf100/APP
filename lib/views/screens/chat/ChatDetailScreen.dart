import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:pfe/utils/colors.dart';
import '../../../services/StompChatService.dart';
import '../../../services/chatService.dart';
import '../../../utils/api_const.dart';
import 'chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final String clientId;
  final String livreurId;
  final String currentUserId;
  final String currentUserName;
  final String contactName;
  final String contactAvatar;

  const ChatScreen({
    Key? key,
    required this.conversationId,
    required this.clientId,
    required this.livreurId,
    required this.currentUserId,
    required this.currentUserName,
    required this.contactName,
    required this.contactAvatar,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatApiService _apiService = ChatApiService();
  final StompChatService _stompService = StompChatService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _messages = [];
  final StreamController<List<dynamic>> _messageStreamController =
  StreamController.broadcast();

  @override
  void initState() {
    super.initState();
    _loadMessages();

    // Initialisation du client WebSocket avec callback de réception de message.
    _stompService.initClient(
      onMessage: (message) {
        setState(() {
          _messages.add(message);
        });
        _messageStreamController.add(_messages);
        // Utilisation d'un post-frame callback pour s'assurer que l'affichage est mis à jour avant de scroller.
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      },
      conversationId: widget.conversationId,
    );
  }

  // Envoi d'un message texte.
  void _sendMessage() async {
    if (_controller.text.trim().isNotEmpty) {
      final messageText = _controller.text.trim();
      _stompService.sendMessage(
        widget.clientId,
        widget.livreurId,
        widget.currentUserId,
        messageText,
        messageType: "text",
      );
      try {
        String receiverId = widget.currentUserId == widget.clientId ? widget.livreurId : widget.clientId;
        final notificationMessage = "${widget.currentUserName}: $messageText";
        final responseNotif = await http.post(
          Uri.parse('${ApiConst.baseUrl}/send-notification'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "userId": receiverId,
            "message": notificationMessage,
          }),
        );

        if (responseNotif.statusCode == 200) {
          debugPrint("Notification envoyée avec succès !");
        } else {
          debugPrint("Erreur envoi notification: ${responseNotif.body}");
        }
      } catch (e) {
        debugPrint("Échec d'envoi de la notification : $e");
      }
      _controller.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      String? imageUrl = await _uploadImage(imageFile);
      if (imageUrl != null) {
        _stompService.sendMessage(
          widget.clientId,
          widget.livreurId,
          widget.currentUserId,
          "",
          imageUrl: imageUrl,
          messageType: "image",
        );
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    }
  }

  // Fonction d'upload de l'image vers le serveur.
  Future<String?> _uploadImage(File imageFile) async {
    var request = http.MultipartRequest(
      "POST",
      Uri.parse('${ApiConst}/api/v1/upload/image'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    var res = await request.send();
    var responseData = await res.stream.bytesToString();
    print("Réponse de l'upload : $responseData"); // Debug
    if (res.statusCode == 200) {
      final decoded = jsonDecode(responseData);
      return decoded["url"];
    } else {
      print("Erreur lors de l'upload de l'image. Code : ${res.statusCode}");
      return null;
    }
  }

  void _loadMessages() async {
    final messages = await _apiService.getMessages(widget.conversationId);
    setState(() {
      _messages = messages;
    });
    _messageStreamController.add(_messages);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  // Fonction qui défile vers le bas de la liste.
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _stompService.disconnect();
    _controller.dispose();
    _scrollController.dispose();
    _messageStreamController.close();
    super.dispose();
  }

  ImageProvider _buildContactAvatar() {
    if (widget.contactAvatar.trim().isNotEmpty &&
        widget.contactAvatar.startsWith('http')) {
      return NetworkImage(widget.contactAvatar);
    }
    return const NetworkImage(
        'https://cdn-icons-png.flaticon.com/512/149/149071.png');
  }

  String _buildContactName() {
    return widget.contactName.trim().isEmpty ? 'Inconnu' : widget.contactName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: _buildContactAvatar(),
              radius: 20,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _buildContactName(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Active now',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<dynamic>>(
              stream: _messageStreamController.stream,
              initialData: _messages,
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final bool isMe = msg['sender'] == widget.currentUserId;
                    String formattedTime = '';
                    if (msg['timestamp'] != null) {
                      try {
                        final dateTime = DateTime.parse(msg['timestamp']);
                        formattedTime = DateFormat('HH:mm').format(dateTime);
                      } catch (e) {
                        formattedTime = msg['timestamp'].toString();
                      }
                    }
                    return ChatBubble(
                      message: msg,
                      isMe: isMe,
                      time: formattedTime,
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attachment_outlined, color: Colors.grey),
                  onPressed: _pickAndSendImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Write your message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: primaryColor),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
