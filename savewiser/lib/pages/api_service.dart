import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const _apiKey = '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';

  Future<http.Response> fetchAdvice() {
    final uri = Uri.parse(_baseUrl);
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };
    final body = jsonEncode({
      'model': 'deepseek/deepseek-r1:free',
      'messages': [
        {
          'role': 'user',
          'content': 'Currently I have saved Rp 20.000.000, I am saving at the rate of Rp 20.000 per day, my goal is to save Rp 100.000.000 by 30th November 2025, today is 30th June 2025. Give me 20 words or less detailed actionable advice for me to reach my goal. Be to the point no need to add any excess characters like \'*\' or \'(20 words)\'. Use English.'
        }
      ],
    });

    return http.post(uri, headers: headers, body: body);
  }
}