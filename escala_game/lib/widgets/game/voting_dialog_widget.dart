import 'package:flutter/material.dart';
import '../../models/game.dart';
import '../../providers/game_provider.dart';

class VotingDialogWidget extends StatefulWidget {
  final GameProvider gameProvider;
  final Function(List<Map<String, dynamic>>) onSubmitVote;

  const VotingDialogWidget({
    Key? key,
    required this.gameProvider,
    required this.onSubmitVote,
  }) : super(key: key);

  @override
  _VotingDialogWidgetState createState() => _VotingDialogWidgetState();
}

class _VotingDialogWidgetState extends State<VotingDialogWidget> {
  final Map<String, int> _votes = {
    'red': 0,
    'yellow': 0,
    'green': 0,
    'blue': 0,
    'purple': 0,
  };

  // Even numbers from 2 to 20
  final List<int> _possibleWeights = [2, 4, 6, 8, 10, 12, 14, 16, 18, 20];

  final Map<String, String> _materialNames = {
    'red': 'Rojo',
    'yellow': 'Amarillo',
    'green': 'Verde',
    'blue': 'Azul',
    'purple': 'Púrpura',
  };
  
  // Bandera para controlar si el jugador ya ha votado
  bool _hasVoted = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adivina los pesos'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '¡La balanza está balanceada! Adivina el peso de cada material:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _votes.length,
                itemBuilder: (context, index) {
                  final materialType = _votes.keys.elementAt(index);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _getColorForMaterial(materialType),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${_materialNames[materialType]}:'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            alignment: WrapAlignment.spaceEvenly,
                            spacing: 4,
                            runSpacing: 4,
                            children: _possibleWeights.map((value) {
                              return _buildWeightButton(materialType, value);
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        if (_hasVoted) ...[
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Esperando a que todos los jugadores voten...',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ),
        ] else ...[
          ElevatedButton(
            onPressed: _submitVotes,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey[700],
            ),
            child: const Text('Enviar'),
          ),
        ],
      ],
    );
  }

  Widget _buildWeightButton(String materialType, int value) {
    final isSelected = _votes[materialType] == value;
    
    return InkWell(
      onTap: () {
        setState(() {
          _votes[materialType] = value;
        });
      },
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueGrey[700] : Colors.blueGrey[200],
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 3,
              offset: const Offset(0, 2),
            )
          ] : null,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.blueGrey[400]!,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            '$value',
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorForMaterial(String materialType) {
    switch (materialType) {
      case 'red':
        return Colors.red;
      case 'yellow':
        return Colors.yellow;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    
    // Verificar si el jugador ya ha votado
    if (widget.gameProvider.currentPlayer != null) {
      _hasVoted = widget.gameProvider.hasVoted(widget.gameProvider.currentPlayer!.id);
    }
    
    // Registrar un callback para mostrar los resultados automáticamente cuando todos hayan votado
    widget.gameProvider.addVoteResultListener((callbackContext) {
      // Usamos context de esta instancia, no el context pasado al callback
      // Cerrar el diálogo de votación si está abierto
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Mostrar resultados
      if (mounted) {
        widget.onSubmitVote([]); // El array vacío indica que ya se procesó la votación
      }
    });
  }
  
  @override
  void dispose() {
    // Limpiar listeners al destruir el widget
    widget.gameProvider.clearVoteResultListeners();
    super.dispose();
  }

  void _submitVotes() {
    if (_hasVoted) return; // Evitar votar más de una vez
    
    final List<Map<String, dynamic>> guesses = _votes.entries
        .map((entry) => {'type': entry.key, 'weight': entry.value})
        .toList();
    
    // Marcar que el jugador ya ha votado
    setState(() {
      _hasVoted = true;
    });
    
    // Enviar la votación con el contexto actual para permitir actualizaciones automáticas
    widget.gameProvider.submitVote(guesses, context);
    
    // Mostrar mensaje de espera
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Votación enviada! Esperando a los demás jugadores...'),
        duration: Duration(seconds: 2),
      ),
    );
    
    // No cerramos el diálogo aquí, se cerrará automáticamente cuando todos hayan votado
  }
}
