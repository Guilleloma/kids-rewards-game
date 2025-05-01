import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/week_model.dart';
import '../services/firestore_service.dart';
import 'service_providers.dart';
import 'auth_provider.dart';

// Provider de semanas (lista)
final weeksProvider = StreamProvider.family<List<WeekModel>, String>((ref, userId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getWeeks(userId);
});

// Provider de semana actual
final currentWeekProvider = StreamProvider.family<WeekModel?, String>((ref, userId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getCurrentWeek(userId);
});

// Notifier para manejar las acciones de semanas
class WeeksNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  
  WeeksNotifier(this._firestoreService) : super(const AsyncValue.data(null));
  
  // Crear una nueva semana
  Future<WeekModel?> createNewWeek(String userId) async {
    state = const AsyncValue.loading();
    try {
      final newWeek = await _firestoreService.createNewWeek(userId);
      state = const AsyncValue.data(null);
      return newWeek;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }
  
  // Verificar si existe una semana actual, sino crearla
  Future<WeekModel?> ensureCurrentWeekExists(String userId) async {
    state = const AsyncValue.loading();
    try {
      // Usar el stream del provider de getCurrentWeek para verificar si hay una semana actual
      bool weekExists = false;
      
      // Esperar una actualización del stream
      await for (final week in _firestoreService.getCurrentWeek(userId)) {
        if (week != null) {
          weekExists = true;
          state = const AsyncValue.data(null);
          return week;
        }
        break; // Solo necesitamos verificar una vez
      }
      
      // Si no existe, crear nueva semana
      if (!weekExists) {
        return createNewWeek(userId);
      }
      
      state = const AsyncValue.data(null);
      return null;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }
  
  // Reiniciar la semana (crear una nueva)
  Future<WeekModel?> resetWeek(String userId) async {
    return createNewWeek(userId);
  }
}

// Provider del notifier de semanas
final weeksNotifierProvider = StateNotifierProvider<WeeksNotifier, AsyncValue<void>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return WeeksNotifier(firestoreService);
});

// Provider del notifier de semanas
final weekNotifierProvider = StateNotifierProvider<WeekNotifier, AsyncValue<void>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return WeekNotifier(firestoreService);
});

class WeekNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  
  WeekNotifier(this._firestoreService) : super(const AsyncValue.data(null));
  
  Future<WeekModel?> createNewWeek(String userId) async {
    state = const AsyncValue.loading();
    try {
      final newWeek = await _firestoreService.createNewWeek(userId);
      state = const AsyncValue.data(null);
      return newWeek;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }
  
  Future<bool> completeTask(
    String userId,
    String weekId,
    String taskId,
    int points,
  ) async {
    state = const AsyncValue.loading();
    try {
      await _firestoreService.completeTask(
        userId,
        weekId,
        taskId,
        points,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
  
  Stream<WeekModel?> getWeekById(String userId, String weekId) {
    try {
      return _firestoreService.getWeekById(userId, weekId);
    } catch (e) {
      throw e;
    }
  }
}
