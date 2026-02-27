import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for fetching word definitions from Dictionary API
class DictionaryApiService {
  static const String _baseUrl = 'https://api.dictionaryapi.dev/api/v2/entries/en';

  /// Fetch the meaning of a word from the dictionary API
  /// Returns the primary definition or throws an exception on error
  Future<String> getWordMeaning(String word) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/${word.toLowerCase()}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (data.isEmpty) {
          throw Exception('No definition found');
        }

        // Extract the first meaning from the response
        final meanings = data[0]['meanings'] as List<dynamic>;
        if (meanings.isEmpty) {
          throw Exception('No definition found');
        }

        final definitions = meanings[0]['definitions'] as List<dynamic>;
        if (definitions.isEmpty) {
          throw Exception('No definition found');
        }

        final definition = definitions[0]['definition'] as String;
        return definition;
      } else if (response.statusCode == 404) {
        throw Exception('Word not found. Please check spelling.');
      } else {
        throw Exception('Failed to fetch definition. Please try again.');
      }
    } catch (e) {
      if (e.toString().contains('Word not found')) {
        rethrow;
      }
      throw Exception('Network error. Please check your connection.');
    }
  }

  /// Get multiple meanings for a word (for future enhancement)
  Future<Map<String, dynamic>> getDetailedWordInfo(String word) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/${word.toLowerCase()}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (data.isEmpty) {
          throw Exception('No definition found');
        }

        final wordData = data[0];
        final meanings = wordData['meanings'] as List<dynamic>;

        List<String> definitions = [];
        String partOfSpeech = '';

        if (meanings.isNotEmpty) {
          partOfSpeech = meanings[0]['partOfSpeech'] as String? ?? '';
          final defs = meanings[0]['definitions'] as List<dynamic>;

          for (var def in defs) {
            definitions.add(def['definition'] as String);
          }
        }

        return {
          'word': wordData['word'] as String,
          'phonetic': wordData['phonetic'] as String? ?? '',
          'partOfSpeech': partOfSpeech,
          'definitions': definitions,
        };
      } else if (response.statusCode == 404) {
        throw Exception('Word not found. Please check spelling.');
      } else {
        throw Exception('Failed to fetch definition. Please try again.');
      }
    } catch (e) {
      if (e.toString().contains('Word not found')) {
        rethrow;
      }
      throw Exception('Network error. Please check your connection.');
    }
  }
}
