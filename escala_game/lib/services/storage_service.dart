import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _playerNameKey = 'player_name';
  static const String _gameHistoryKey = 'game_history';

  Future<void> savePlayerName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playerNameKey, name);
  }

  Future<String?> getPlayerName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_playerNameKey);
  }

  Future<void> saveGameToHistory(String gameCode, String result,
      int team) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_gameHistoryKey) ?? [];
    final entry = '$gameCode - $result - $team'; // Nuevo formato: "ABC123 - Exitoso - 2"
    if (!history.contains(entry)) { // Evitar duplicados
      history.add(entry);
      await prefs.setStringList(_gameHistoryKey, history);
    }
  }

  Future<List<String>> getGameHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_gameHistoryKey) ?? [];
  }

  Future<void> clearGameHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_gameHistoryKey);
  }
}