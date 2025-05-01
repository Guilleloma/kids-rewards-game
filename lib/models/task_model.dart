enum TaskCategory {
  daily, // Retos diarios (1 punto)
  help,  // Ayudas especiales (2 puntos)
  brave, // Misiones de valiente (3 puntos)
}

extension TaskCategoryExtension on TaskCategory {
  String get name {
    switch (this) {
      case TaskCategory.daily:
        return 'reto';
      case TaskCategory.help:
        return 'ayuda';
      case TaskCategory.brave:
        return 'valiente';
      default:
        return 'reto';
    }
  }
  
  int get points {
    switch (this) {
      case TaskCategory.daily:
        return 1;
      case TaskCategory.help:
        return 2;
      case TaskCategory.brave:
        return 3;
      default:
        return 1;
    }
  }
  
  static TaskCategory fromString(String category) {
    switch (category.toLowerCase()) {
      case 'reto':
        return TaskCategory.daily;
      case 'ayuda':
        return TaskCategory.help;
      case 'valiente':
        return TaskCategory.brave;
      default:
        return TaskCategory.daily;
    }
  }
}

class TaskModel {
  final String id;
  final String title;
  final String? description;
  final TaskCategory category;
  final int points;
  final String imageUrl;
  final bool active;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.points,
    required this.imageUrl,
    required this.active,
  });

  // Convertir de Firestore a TaskModel
  factory TaskModel.fromJson(Map<String, dynamic> json, String id) {
    final categoryStr = json['category'] ?? 'reto';
    final category = TaskCategoryExtension.fromString(categoryStr);
    
    return TaskModel(
      id: id,
      title: json['title'] ?? '',
      description: json['description'],
      category: category,
      points: json['points'] ?? category.points,
      imageUrl: json['imageUrl'] ?? '',
      active: json['active'] ?? true,
    );
  }

  // Convertir a formato Firestore
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category.name,
      'points': points,
      'imageUrl': imageUrl,
      'active': active,
    };
  }

  // Crear una copia del objeto con algunos campos modificados
  TaskModel copyWith({
    String? title,
    String? description,
    TaskCategory? category,
    int? points,
    String? imageUrl,
    bool? active,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      points: points ?? this.points,
      imageUrl: imageUrl ?? this.imageUrl,
      active: active ?? this.active,
    );
  }
}
