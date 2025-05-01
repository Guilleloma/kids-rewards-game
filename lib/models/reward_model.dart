enum RewardType {
  normal,     // Premio normal
  premium,    // Super premio (antes "super")
}

extension RewardTypeExtension on RewardType {
  String get name {
    switch (this) {
      case RewardType.normal:
        return 'normal';
      case RewardType.premium:
        return 'superpremio';
      default:
        return 'normal';
    }
  }
  
  static RewardType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'superpremio':
        return RewardType.premium;
      case 'normal':
      default:
        return RewardType.normal;
    }
  }
}

class RewardModel {
  final String id;
  final String title;
  final String? description;
  final RewardType type;
  final int cost;  // Puntos mínimos necesarios para desbloquear
  final String? imageUrl;
  final bool active;

  RewardModel({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.cost,
    this.imageUrl,
    this.active = true,
  });

  // Convertir de Firestore a RewardModel
  factory RewardModel.fromJson(Map<String, dynamic> json, String id) {
    final typeStr = json['type'] ?? 'normal';
    
    return RewardModel(
      id: id,
      title: json['title'] ?? '',
      description: json['description'],
      type: RewardTypeExtension.fromString(typeStr),
      cost: json['cost'] ?? 60,
      imageUrl: json['imageUrl'],
      active: json['active'] ?? true,
    );
  }

  // Convertir a formato Firestore
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'type': type.name,
      'cost': cost,
      'imageUrl': imageUrl,
      'active': active,
    };
  }

  // Crear una copia del objeto con algunos campos modificados
  RewardModel copyWith({
    String? title,
    String? description,
    RewardType? type,
    int? cost,
    String? imageUrl,
    bool? active,
  }) {
    return RewardModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      cost: cost ?? this.cost,
      imageUrl: imageUrl ?? this.imageUrl,
      active: active ?? this.active,
    );
  }
  
  // Verificar si el reward está desbloqueado con los puntos actuales
  bool isUnlocked(int currentPoints) {
    return currentPoints >= cost;
  }
}
