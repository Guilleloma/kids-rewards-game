class WeekModel {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final int totalPoints;
  final int coinsEarned;
  final List<String> completedTasks;
  final List<String> rewardsEarned;

  WeekModel({
    required this.id,
    required this.startDate,
    required this.endDate,
    this.totalPoints = 0,
    this.coinsEarned = 0,
    required this.completedTasks,
    required this.rewardsEarned,
  });

  // Convertir de Firestore a WeekModel
  factory WeekModel.fromJson(Map<String, dynamic> json, String id) {
    return WeekModel(
      id: id,
      startDate: (json['startDate'] as dynamic)?.toDate() ?? DateTime.now(),
      endDate: (json['endDate'] as dynamic)?.toDate() ?? DateTime.now().add(const Duration(days: 7)),
      totalPoints: json['totalPoints'] ?? 0,
      coinsEarned: json['coinsEarned'] ?? 0,
      completedTasks: List<String>.from(json['completedTasks'] ?? []),
      rewardsEarned: List<String>.from(json['rewardsEarned'] ?? []),
    );
  }

  // Convertir a formato Firestore
  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate,
      'endDate': endDate,
      'totalPoints': totalPoints,
      'coinsEarned': coinsEarned,
      'completedTasks': completedTasks,
      'rewardsEarned': rewardsEarned,
    };
  }

  // Crear una semana nueva para las fechas actuales
  factory WeekModel.createNewWeek() {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    
    return WeekModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startDate: startOfWeek,
      endDate: startOfWeek.add(const Duration(days: 6)),
      totalPoints: 0,
      coinsEarned: 0,
      completedTasks: [],
      rewardsEarned: [],
    );
  }
  
  // Verificar si una tarea ha sido completada
  bool isTaskCompleted(String taskId) {
    return completedTasks.contains(taskId);
  }
  
  // Añadir una tarea completada y calcular puntos
  WeekModel addCompletedTask(String taskId, int pointsForTask) {
    if (completedTasks.contains(taskId)) {
      return this;
    }
    
    final newCompletedTasks = List<String>.from(completedTasks)..add(taskId);
    final newTotalPoints = totalPoints + pointsForTask;
    
    // Calcular monedas (1 moneda cada 30 puntos)
    final newCoinsEarned = (newTotalPoints / 30).floor();
    
    return WeekModel(
      id: id,
      startDate: startDate,
      endDate: endDate,
      totalPoints: newTotalPoints,
      coinsEarned: newCoinsEarned,
      completedTasks: newCompletedTasks,
      rewardsEarned: rewardsEarned,
    );
  }
  
  // Añadir una recompensa desbloqueada
  WeekModel addReward(String rewardId) {
    if (rewardsEarned.contains(rewardId)) {
      return this;
    }
    
    final newRewardsEarned = List<String>.from(rewardsEarned)..add(rewardId);
    
    return WeekModel(
      id: id,
      startDate: startDate,
      endDate: endDate,
      totalPoints: totalPoints,
      coinsEarned: coinsEarned,
      completedTasks: completedTasks,
      rewardsEarned: newRewardsEarned,
    );
  }
}
