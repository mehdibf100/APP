import 'package:flutter/material.dart';
import 'package:pfe/services/userService.dart';
import '../../../services/chatService.dart';
import '../../widgets/ConversationTile.dart';
import 'ChatDetailScreen.dart';

class ConversationsScreen extends StatefulWidget {
  final String userId;

  const ConversationsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ConversationsScreenState createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final ChatApiService _apiService = ChatApiService();
  final UserService _userService = UserService();
  late Future<List<dynamic>> _conversationsFuture;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadConversations();
  }

  void _loadConversations() {
    setState(() {
      _conversationsFuture = _apiService.getConversations(widget.userId);
    });
  }

  Future<void> _loadUser() async {
    try {
      final userData = await _userService.getUserById(widget.userId);
      if (mounted) {
        setState(() {
          _user = userData;
        });
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement de l'utilisateur: $e");
    }
  }

  Future<String> _loadOtherUser(String id) async {
    try {
      final userData = await _userService.getUserById(id);
      return userData["name"] ?? "Inconnu";
    } catch (e) {
      debugPrint("Erreur lors du chargement de l'autre utilisateur: $e");
      return "Inconnu";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _conversationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucune conversation disponible."));
          }

          final conversations = snapshot.data!;
          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final bool isCurrentUserClient =
                  widget.userId == conversation['clientId'];

              final String otherUserId = isCurrentUserClient
                  ? conversation['livreurId']
                  : conversation['clientId'];

              final String contactAvatar = isCurrentUserClient
                  ? (conversation['livreurAvatar'] ?? '')
                  : (conversation['clientAvatar'] ?? '');

              return FutureBuilder<String>(
                future: _loadOtherUser(otherUserId),
                builder: (context, contactSnapshot) {
                  final String contactName =
                      contactSnapshot.data ?? "Inconnu";

                  return ConversationTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            conversationId: conversation['id'],
                            clientId: conversation['clientId'],
                            livreurId: conversation['livreurId'],
                            currentUserId: widget.userId,
                            currentUserName: _user!["name"] ?? "Utilisateur",
                            contactName: contactName,
                            contactAvatar: contactAvatar,
                          ),
                        ),
                      ).then((updated) {
                        if (updated == true) {
                          _loadConversations();
                        }
                      });
                    },
                    conversation: conversation,
                    currentUserId: widget.userId,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}