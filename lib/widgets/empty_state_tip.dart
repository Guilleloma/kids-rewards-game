import 'package:flutter/material.dart';

/// Enum para las categorías de contenido vacío
enum EmptyCategory {
  daily,
  help,
  brave,
  reward,
}

/// Widget reutilizable para mostrar estado vacío con tips/contexto
class EmptyStateTip extends StatelessWidget {
  final EmptyCategory category;

  const EmptyStateTip({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _data = _getDataForCategory(category);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_data.icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _data.title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _data.tip,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  _EmptyStateData _getDataForCategory(EmptyCategory category) {
    switch (category) {
      case EmptyCategory.daily:
        return _EmptyStateData(
          icon: Icons.calendar_today,
          title: 'No hay retos diarios',
          tip: 'Los retos diarios son pequeñas tareas que puedes hacer cada día para ganar puntos.\nEjemplo: Hacer la cama, lavarse los dientes, recoger los juguetes.',
        );
      case EmptyCategory.help:
        return _EmptyStateData(
          icon: Icons.volunteer_activism,
          title: 'No hay misiones de ayuda especial',
          tip: 'Las misiones de ayuda especial son tareas para ayudar a otros en casa o en el cole.\nEjemplo: Ayudar a poner la mesa, cuidar de una mascota, ayudar a un compañero.',
        );
      case EmptyCategory.brave:
        return _EmptyStateData(
          icon: Icons.emoji_events,
          title: 'No hay misiones del valiente',
          tip: 'Las misiones del valiente son retos para superar miedos o hacer cosas nuevas.\nEjemplo: Hablar en público, probar una comida nueva, pedir ayuda cuando lo necesitas.',
        );
      case EmptyCategory.reward:
        return _EmptyStateData(
          icon: Icons.card_giftcard,
          title: 'No hay premios disponibles',
          tip: 'Aquí verás los premios que puedes conseguir al completar tus retos.\nEjemplo: Elegir la película del viernes, una tarde de juegos, un paseo especial.',
        );
    }
  }
}

class _EmptyStateData {
  final IconData icon;
  final String title;
  final String tip;
  const _EmptyStateData({required this.icon, required this.title, required this.tip});
}
