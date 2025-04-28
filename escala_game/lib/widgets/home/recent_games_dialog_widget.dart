import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../services/api_service.dart';

// Colores para la aplicación
class AppColors {
  static const Color primaryColor = Color(0xFF3F51B5);
  static const Color accentColor = Color(0xFF009688);
  static const Color onPrimaryColor = Colors.white;
}

class RecentGamesDialog extends StatefulWidget {
  final Function(String) onJoinGame;

  const RecentGamesDialog({Key? key, required this.onJoinGame}) : super(key: key);

  @override
  _RecentGamesDialogState createState() => _RecentGamesDialogState();
}

class _RecentGamesDialogState extends State<RecentGamesDialog> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _recentGames = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadRecentGames();
  }
  
  Future<void> _loadRecentGames() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      
      final games = await _apiService.getRecentGames();
      
      setState(() {
        _recentGames = games;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error al cargar partidas recientes: $e';
      });
    }
  }
  
  String _formatTimeAgo(String createdAtStr) {
    final createdAt = DateTime.parse(createdAtStr);
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inMinutes < 1) {
      return 'Hace ${difference.inSeconds} segundos';
    } else {
      return 'Hace ${difference.inMinutes} minutos';
    }
  }
  
  Widget _buildGameItem(Map<String, dynamic> game) {
    final gameCode = game['gameCode'] as String;
    final createdAt = game['createdAt'] as String;
    final playerCount = game['playerCount'] as int;
    final timeRemaining = 5 * 60 - (game['timeRemaining'] as int);
    final maxTime = game['maxTime'] as int;
    
    // Calcular el porcentaje de tiempo restante
    final percentRemaining = (timeRemaining / maxTime).clamp(0.0, 1.0);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryColor,
          child: Icon(
            Icons.videogame_asset,
            color: AppColors.onPrimaryColor,
          ),
        ),
        title: Text('Partida: $gameCode', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Creada: ${_formatTimeAgo(createdAt)}'),
            Text('Jugadores: $playerCount'),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: percentRemaining,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                percentRemaining < 0.2 ? Colors.red : AppColors.primaryColor,
              ),
            ),
            Text(
              'Desaparecerá en ${(5 - (timeRemaining ~/ 60))} min ${60 - (timeRemaining % 60)} seg',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: percentRemaining < 0.2 ? Colors.red : Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentColor,
          ),
          onPressed: () {
            widget.onJoinGame(gameCode);
            Navigator.of(context).pop();
          },
          child: const Text('Unirse', style: TextStyle(color: Colors.white)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Partidas Recientes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadRecentGames,
                  tooltip: 'Actualizar',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _hasError
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage ?? 'Error desconocido',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadRecentGames,
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        )
                      : _recentGames.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.sports_esports, size: 48, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'No hay partidas recientes disponibles.\nCrea una nueva partida.',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _recentGames.length,
                              itemBuilder: (context, index) {
                                return _buildGameItem(_recentGames[index]);
                              },
                            ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
