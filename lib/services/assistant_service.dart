import 'dart:convert';
import 'package:http/http.dart' as http;

class AssistantService {
  static final Uri _chatEndpoint = Uri.parse('https://pilatechat.onrender.com/chat/');

  Future<String> sendMessage(String message) async {
    try {
      final response = await http
          .post(
            _chatEndpoint,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'message': message}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return 'Le service d assistance est momentanement indisponible. Veuillez reessayer.';
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final reply = data['response']?.toString().trim();

      if (reply == null || reply.isEmpty) {
        return 'Je n ai pas encore de reponse pour cette question.';
      }

      return reply;
    } catch (e) {
      return 'Impossible de contacter l assistance pour le moment. Verifiez votre connexion puis reessayez.';
    }
  }
}
