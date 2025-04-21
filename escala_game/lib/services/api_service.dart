import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/game.dart';
import '../models/player.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api'; // Flutter Web (navegador)
    } else if (Platform.environment.containsKey('ANDROID_EMULATOR')) {
      return 'http://10.0.2.2:5000/api'; // Emulador Android
    } else if (Platform.isAndroid || Platform.isIOS) {
      return 'http://10.0.2.2:5000/api'; // Dispositivos móviles
    } else {
      return 'http://localhost:5000/api'; // Otros entornos locales
    }
  }

  Future<Game> createGame({required int roundTimeSeconds}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/games/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'roundTimeSeconds': roundTimeSeconds}),
      );
      if (response.statusCode == 201) {
        return Game.fromJson(jsonDecode(response.body));
      }
      throw Exception('Error al crear el juego: ${response.body}');
    } catch (e) {
      print('Error creating game: $e');
      rethrow;
    }
  }

  Future<Game> getGame(String gameCode) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/games/$gameCode'));
      if (response.statusCode == 200) {
        return Game.fromJson(jsonDecode(response.body));
      }
      throw Exception('Error al obtener el juego: ${response.body}');
    } catch (e) {
      print('Error getting game: $e');
      rethrow;
    }
  }

  Future<Player> createPlayer(String gameCode, String name, int groupId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/players/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'gameCode': gameCode, 'name': name, 'groupId': groupId}),
      );
      if (response.statusCode == 201) {
        return Player.fromJson(jsonDecode(response.body));
      }
      throw Exception('Error al crear el jugador: ${response.body}');
    } catch (e) {
      print('Error creating player: $e');
      rethrow;
    }
  }

  Future<List<Player>> getPlayers(String gameId) async {
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/players/game/$gameId'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Player.fromJson(json)).toList();
      }
      throw Exception('Error al obtener los jugadores: ${response.body}');
    } catch (e) {
      print('Error getting players: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> placeMaterial(String playerId, String materialId,
      String balanceType, String side) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/players/$playerId/place-material'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'materialId': materialId,
          'balanceType': balanceType,
          'side': side,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Error al colocar material: ${response.body}');
    } catch (e) {
      print('Error placing material: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> makeGuess(String playerId,
      List<Map<String, dynamic>> guesses) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/players/$playerId/guess'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'guesses': guesses}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Error al hacer la adivinanza: ${response.body}');
    } catch (e) {
      print('Error making guess: $e');
      rethrow;
    }
  }

  Future<void> startGame(String gameCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/games/$gameCode/start'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode != 200) {
        throw Exception('Error al iniciar el juego: ${response.body}');
      }
    } catch (e) {
      print('Error starting game: $e');
      rethrow;
    }
  }
}