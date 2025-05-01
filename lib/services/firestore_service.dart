import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../models/week_model.dart';
import '../models/reward_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Referencias de colecciones para un usuario
  CollectionReference _tasksRef(String userId) => 
    _firestore.collection('users').doc(userId).collection('tasks');
  
  CollectionReference _weeksRef(String userId) => 
    _firestore.collection('users').doc(userId).collection('weeks');
  
  CollectionReference _rewardsRef(String userId) => 
    _firestore.collection('users').doc(userId).collection('rewards');

  // Métodos para tareas
  Stream<List<TaskModel>> getTasks(String userId) {
    return _tasksRef(userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<TaskModel> addTask(String userId, TaskModel task) async {
    final docRef = await _tasksRef(userId).add(task.toJson());
    // Creamos un nuevo objeto TaskModel con el ID correcto
    return TaskModel(
      id: docRef.id,
      title: task.title,
      description: task.description,
      category: task.category,
      points: task.points,
      imageUrl: task.imageUrl,
      active: task.active,
    );
  }

  Future<void> updateTask(String userId, TaskModel task) async {
    await _tasksRef(userId).doc(task.id).update(task.toJson());
  }

  Future<void> deleteTask(String userId, String taskId) async {
    await _tasksRef(userId).doc(taskId).delete();
  }

  // Obtener una tarea específica por ID
  Future<TaskModel?> getTaskById(String userId, String taskId) async {
    final docSnapshot = await _tasksRef(userId).doc(taskId).get();
    if (!docSnapshot.exists) {
      return null;
    }
    return TaskModel.fromJson(docSnapshot.data() as Map<String, dynamic>, docSnapshot.id);
  }

  // Métodos para semanas
  Stream<List<WeekModel>> getWeeks(String userId) {
    return _weeksRef(userId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WeekModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Solución temporal que no requiere índice compuesto
  Stream<WeekModel?> getCurrentWeek(String userId) {
    final now = DateTime.now();
    
    // Usando solo un filtro de fecha para evitar la necesidad del índice compuesto
    return _weeksRef(userId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          
          // Filtrar manualmente en memoria
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final startDate = (data['startDate'] as Timestamp).toDate();
            final endDate = (data['endDate'] as Timestamp).toDate();
            
            // Comprobar si la fecha actual está dentro del período
            if (startDate.isBefore(now) && endDate.isAfter(now)) {
              return WeekModel.fromJson(data, doc.id);
            }
          }
          
          return null;
        });
  }

  Future<WeekModel> createNewWeek(String userId) async {
    final newWeek = WeekModel.createNewWeek();
    await _weeksRef(userId).doc(newWeek.id).set(newWeek.toJson());
    return newWeek;
  }

  Future<void> updateWeek(String userId, WeekModel week) async {
    await _weeksRef(userId).doc(week.id).update(week.toJson());
  }

  // Obtener una semana específica por ID
  Stream<WeekModel?> getWeekById(String userId, String weekId) {
    return _weeksRef(userId)
        .doc(weekId)
        .snapshots()
        .map((snapshot) => snapshot.exists
            ? WeekModel.fromJson(snapshot.data() as Map<String, dynamic>, snapshot.id)
            : null);
  }

  // Método para marcar una tarea como completada
  Future<void> completeTask(String userId, String weekId, String taskId, int points) async {
    final weekRef = _weeksRef(userId).doc(weekId);
    
    return _firestore.runTransaction((transaction) async {
      final weekDoc = await transaction.get(weekRef);
      
      if (!weekDoc.exists) {
        throw Exception('La semana no existe');
      }
      
      final week = WeekModel.fromJson(weekDoc.data() as Map<String, dynamic>, weekDoc.id);
      
      // Si la tarea ya está completada, no hacer nada
      if (week.completedTasks.contains(taskId)) {
        return;
      }
      
      // Registrar la fecha actual como fecha de compleción
      final completionDate = DateTime.now();
      
      // Usar el nuevo método para añadir tarea completada con fecha
      final updatedWeek = week.copyWithCompletedTask(
        taskId: taskId,
        completionDate: completionDate,
        taskPoints: points,
      );
      
      transaction.update(weekRef, updatedWeek.toJson());
    });
  }

  // Método para desmarcar una tarea como completada (deshacer)
  Future<void> uncompleteTask(String userId, String weekId, String taskId, int points) async {
    final weekRef = _weeksRef(userId).doc(weekId);
    
    return _firestore.runTransaction((transaction) async {
      final weekDoc = await transaction.get(weekRef);
      
      if (!weekDoc.exists) {
        throw Exception('La semana no existe');
      }
      
      final week = WeekModel.fromJson(weekDoc.data() as Map<String, dynamic>, weekDoc.id);
      
      // Si la tarea no está completada, no hacer nada
      if (!week.completedTasks.contains(taskId)) {
        return;
      }
      
      // Eliminar la tarea de la lista de completadas y restar los puntos
      final updatedWeek = week.copyWithoutCompletedTask(
        taskId: taskId,
        taskPoints: points,
      );
      
      // Actualizar la semana
      transaction.update(weekRef, updatedWeek.toJson());
    });
  }

  // Métodos para recompensas
  Stream<List<RewardModel>> getRewards(String userId) {
    return _rewardsRef(userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RewardModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<RewardModel> addReward(String userId, RewardModel reward) async {
    final docRef = await _rewardsRef(userId).add(reward.toJson());
    // Creamos un nuevo objeto RewardModel con el ID correcto
    return RewardModel(
      id: docRef.id,
      title: reward.title,
      description: reward.description,
      type: reward.type,
      cost: reward.cost,
      imageUrl: reward.imageUrl,
      active: reward.active,
    );
  }

  Future<void> updateReward(String userId, RewardModel reward) async {
    await _rewardsRef(userId).doc(reward.id).update(reward.toJson());
  }

  Future<void> deleteReward(String userId, String rewardId) async {
    await _rewardsRef(userId).doc(rewardId).delete();
  }

  // Obtener una recompensa específica por ID
  Future<RewardModel?> getRewardById(String userId, String rewardId) async {
    final docSnapshot = await _rewardsRef(userId).doc(rewardId).get();
    if (!docSnapshot.exists) {
      return null;
    }
    return RewardModel.fromJson(docSnapshot.data() as Map<String, dynamic>, docSnapshot.id);
  }

  // Método para desbloquear una recompensa
  Future<void> unlockReward(String userId, String weekId, String rewardId) async {
    final weekRef = _weeksRef(userId).doc(weekId);
    
    return _firestore.runTransaction((transaction) async {
      final weekDoc = await transaction.get(weekRef);
      
      if (!weekDoc.exists) {
        throw Exception('La semana no existe');
      }
      
      final week = WeekModel.fromJson(weekDoc.data() as Map<String, dynamic>, weekDoc.id);
      
      // Si la recompensa ya está desbloqueada, no hacer nada
      if (week.rewardsEarned.contains(rewardId)) {
        return;
      }
      
      // Añadir recompensa desbloqueada
      final updatedWeek = week.addReward(rewardId);
      
      transaction.update(weekRef, updatedWeek.toJson());
    });
  }
}
