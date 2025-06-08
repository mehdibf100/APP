import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pfe/utils/api_const.dart';

class ChatApiService {
  final String baseUrl = "${ApiConst.baseUrl}/api/v1/chat";

  Future<List<dynamic>> getConversations(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/conversations?userId=$userId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors du chargement des conversations');
    }
  }

  Future<List<dynamic>> getMessages(int conversationId) async {
    final response = await http.get(Uri.parse('$baseUrl/conversations/$conversationId/messages'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors du chargement des messages');
    }
  }
}
