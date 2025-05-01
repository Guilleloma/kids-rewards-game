import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'auth_provider.dart';
import 'service_providers.dart';

// Provider de tareas (lista)
final tasksProvider = StreamProvider.family<List<TaskModel>, String>((ref, userId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getTasks(userId);
});

// Provider de tareas activas
final activeTasksProvider = Provider.family<List<TaskModel>, String>((ref, userId) {
  final tasksAsync = ref.watch(tasksProvider(userId));
  return tasksAsync.when(
    data: (tasks) => tasks.where((task) => task.active).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Provider de tareas por categoría
final tasksByCategoryProvider = Provider.family<Map<TaskCategory, List<TaskModel>>, String>((ref, userId) {
  final tasksAsync = ref.watch(tasksProvider(userId));
  return tasksAsync.when(
    data: (tasks) {
      final Map<TaskCategory, List<TaskModel>> result = {
        TaskCategory.daily: [],
        TaskCategory.help: [],
        TaskCategory.brave: [],
      };
      
      for (final task in tasks) {
        result[task.category]!.add(task);
      }
      
      return result;
    },
    loading: () => {
      TaskCategory.daily: [],
      TaskCategory.help: [],
      TaskCategory.brave: [],
    },
    error: (_, __) => {
      TaskCategory.daily: [],
      TaskCategory.help: [],
      TaskCategory.brave: [],
    },
  );
});

// Notifier para manejar las acciones de tareas
class TasksNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  final StorageService _storageService;
  
  TasksNotifier(this._firestoreService, this._storageService) : super(const AsyncValue.data(null));
  
  // Añadir tarea
  Future<TaskModel?> addTask({
    required String userId,
    required String title,
    String? description,
    required TaskCategory category,
    int? points,
    File? image,
    Uint8List? imageBytes,
    String? imageUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Generar ID temporal para la tarea
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Valores por defecto
      final taskPoints = points ?? category.points;
      String finalImageUrl = imageUrl ?? '';
      
      // Subir imagen si se proporciona
      if (kIsWeb && imageBytes != null) {
        // Para web, subir bytes de imagen
        final uploadedUrl = await _storageService.uploadTaskImageBytes(
          userId: userId,
          imageBytes: imageBytes,
          fileName: 'task_$tempId.jpg',
        );
        
        if (uploadedUrl != null) {
          finalImageUrl = uploadedUrl;
        }
      } else if (!kIsWeb && image != null) {
        // Para móvil, subir archivo
        final uploadedUrl = await _storageService.uploadTaskImage(
          userId: userId,
          imageFile: image,
          fileName: 'task_$tempId.jpg',
        );
        
        if (uploadedUrl != null) {
          finalImageUrl = uploadedUrl;
        }
      }
      
      // Crear modelo de tarea
      final task = TaskModel(
        id: tempId,
        title: title,
        description: description,
        category: category,
        points: taskPoints,
        imageUrl: finalImageUrl,
        active: true,
      );
      
      // Guardar en Firestore
      final addedTask = await _firestoreService.addTask(userId, task);
      
      state = const AsyncValue.data(null);
      return addedTask;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }
  
  // Actualizar tarea
  Future<bool> updateTask({
    required String userId,
    required String taskId,
    String? title,
    String? description,
    TaskCategory? category,
    int? points,
    File? newImage,
    Uint8List? newImageBytes,
    String? newImageUrl,
    bool? active,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Obtener la tarea actual
      final currentTask = await _firestoreService.getTaskById(userId, taskId);
      
      if (currentTask == null) {
        state = AsyncValue.error('La tarea no existe', StackTrace.current);
        return false;
      }
      
      // Procesar imagen si se proporciona
      String imageUrl = currentTask.imageUrl;
      
      // Si se proporciona una nueva URL directamente, usarla
      if (newImageUrl != null) {
        imageUrl = newImageUrl;
      }
      // Para web, usar bytes de imagen
      else if (kIsWeb && newImageBytes != null) {
        // Eliminar imagen anterior si existe
        if (currentTask.imageUrl.isNotEmpty) {
          await _storageService.deleteImage(currentTask.imageUrl);
        }
        
        // Subir nueva imagen
        final uploadedUrl = await _storageService.uploadTaskImageBytes(
          userId: userId,
          imageBytes: newImageBytes,
          fileName: 'task_$taskId.jpg',
        );
        
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      }
      // Para móvil, usar archivo
      else if (!kIsWeb && newImage != null) {
        // Eliminar imagen anterior si existe
        if (currentTask.imageUrl.isNotEmpty) {
          await _storageService.deleteImage(currentTask.imageUrl);
        }
        
        // Subir nueva imagen
        final uploadedUrl = await _storageService.uploadTaskImage(
          userId: userId,
          imageFile: newImage,
          fileName: 'task_$taskId.jpg',
        );
        
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      }
      
      // Actualizar modelo
      final updatedTask = currentTask.copyWith(
        title: title,
        description: description,
        category: category,
        points: points,
        imageUrl: imageUrl,
        active: active,
      );
      
      // Guardar en Firestore
      await _firestoreService.updateTask(userId, updatedTask);
      
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
  
  // Eliminar tarea
  Future<bool> deleteTask({
    required String userId,
    required TaskModel task,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Eliminar imagen si existe
      if (task.imageUrl.isNotEmpty) {
        await _storageService.deleteImage(task.imageUrl);
      }
      
      // Eliminar documento
      await _firestoreService.deleteTask(userId, task.id);
      
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
  
  // Marcar tarea como completada
  Future<bool> completeTask({
    required String userId,
    required String weekId,
    required TaskModel task,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _firestoreService.completeTask(
        userId,
        weekId,
        task.id,
        task.points,
      );
      
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
  
  // Obtener tarea por ID
  Future<TaskModel?> getTaskById(String userId, String taskId) async {
    state = const AsyncValue.loading();
    try {
      final taskDoc = await _firestoreService.getTaskById(userId, taskId);
      if (taskDoc == null) {
        state = AsyncValue.error('La tarea no existe', StackTrace.current);
        return null;
      }
      
      state = const AsyncValue.data(null);
      return taskDoc;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }
}

// Provider del notifier de tareas
final tasksNotifierProvider = StateNotifierProvider<TasksNotifier, AsyncValue<void>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return TasksNotifier(firestoreService, storageService);
});
