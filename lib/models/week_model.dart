class WeekModel {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final int totalPoints;
  final int coinsEarned;
  final List<String> completedTasks;
  final List<String> rewardsEarned;
  final Map<String, DateTime> taskCompletionDates;

  WeekModel({
    required this.id,
    required this.startDate,
    required this.endDate,
    this.totalPoints = 0,
    this.coinsEarned = 0,
    required this.completedTasks,
    required this.rewardsEarned,
    this.taskCompletionDates = const {},
  });

  // Convertir de Firestore a WeekModel
  factory WeekModel.fromJson(Map<String, dynamic> json, String id) {
    Map<String, DateTime> completionDates = {};
    if (json['taskCompletionDates'] != null) {
      (json['taskCompletionDates'] as Map<String, dynamic>).forEach((taskId, dateString) {
        completionDates[taskId] = DateTime.parse(dateString);
      });
    }
    
    return WeekModel(
      id: id,
      startDate: (json['startDate'] as dynamic)?.toDate() ?? DateTime.now(),
      endDate: (json['endDate'] as dynamic)?.toDate() ?? DateTime.now().add(const Duration(days: 7)),
      totalPoints: json['totalPoints'] ?? 0,
      coinsEarned: json['coinsEarned'] ?? 0,
      completedTasks: List<String>.from(json['completedTasks'] ?? []),
      rewardsEarned: List<String>.from(json['rewardsEarned'] ?? []),
      taskCompletionDates: completionDates,
    );
  }

  // Convertir a formato Firestore
  Map<String, dynamic> toJson() {
    Map<String, String> dateStrings = {};
    taskCompletionDates.forEach((taskId, date) {
      dateStrings[taskId] = date.toIso8601String();
    });
    
    return {
      'startDate': startDate,
      'endDate': endDate,
      'totalPoints': totalPoints,
      'coinsEarned': coinsEarned,
      'completedTasks': completedTasks,
      'rewardsEarned': rewardsEarned,
      'taskCompletionDates': dateStrings,
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
      taskCompletionDates: {},
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
    
    final Map<String, DateTime> newCompletionDates = Map<String, DateTime>.from(taskCompletionDates);
    newCompletionDates[taskId] = DateTime.now();
    
    return WeekModel(
      id: id,
      startDate: startDate,
      endDate: endDate,
      totalPoints: newTotalPoints,
      coinsEarned: newCoinsEarned,
      completedTasks: newCompletedTasks,
      rewardsEarned: rewardsEarned,
      taskCompletionDates: newCompletionDates,
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
      taskCompletionDates: taskCompletionDates,
    );
  }

  // Método para obtener las tareas completadas en un día específico
  List<String> getTasksCompletedOnDay(DateTime day) {
    final specificDay = DateTime(day.year, day.month, day.day);
    return taskCompletionDates.entries
        .where((entry) {
          final entryDay = DateTime(entry.value.year, entry.value.month, entry.value.day);
          return entryDay.isAtSameMomentAs(specificDay);
        })
        .map((entry) => entry.key)
        .toList();
  }
  
  // Método para crear una copia con una nueva tarea completada
  WeekModel copyWithCompletedTask({
    required String taskId, 
    required DateTime completionDate,
    required int taskPoints,
  }) {
    final newTotalPoints = totalPoints + taskPoints;
    final newCompletedTasks = List<String>.from(completedTasks);
    if (!newCompletedTasks.contains(taskId)) {
      newCompletedTasks.add(taskId);
    }
    
    final newCompletionDates = Map<String, DateTime>.from(taskCompletionDates);
    newCompletionDates[taskId] = completionDate;
    
    return WeekModel(
      id: id,
      startDate: startDate,
      endDate: endDate,
      totalPoints: newTotalPoints,
      coinsEarned: (newTotalPoints / 30).floor(),
      completedTasks: newCompletedTasks,
      rewardsEarned: rewardsEarned,
      taskCompletionDates: newCompletionDates,
    );
  }
  
  // Método para crear una copia sin una tarea completada (deshacer)
  WeekModel copyWithoutCompletedTask({
    required String taskId, 
    required int taskPoints,
  }) {
    final newCompletedTasks = List<String>.from(completedTasks);
    if (newCompletedTasks.contains(taskId)) {
      newCompletedTasks.remove(taskId);
    } else {
      return this; // Si la tarea no estaba completada, devolver la semana sin cambios
    }
    
    // Restar los puntos y recalcular monedas
    final newTotalPoints = totalPoints - taskPoints;
    final newCoinsEarned = (newTotalPoints / 30).floor();
    
    // Eliminar la fecha de compleción
    final Map<String, DateTime> newCompletionDates = Map<String, DateTime>.from(taskCompletionDates);
    newCompletionDates.remove(taskId);
    
    return WeekModel(
      id: id,
      startDate: startDate,
      endDate: endDate,
      totalPoints: newTotalPoints < 0 ? 0 : newTotalPoints, // Evitar puntos negativos
      coinsEarned: newCoinsEarned < 0 ? 0 : newCoinsEarned, // Evitar monedas negativas
      completedTasks: newCompletedTasks,
      rewardsEarned: rewardsEarned,
      taskCompletionDates: newCompletionDates,
    );
  }
}
