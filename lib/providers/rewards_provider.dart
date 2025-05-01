import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reward_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'auth_provider.dart';
import 'service_providers.dart';

// Provider de recompensas (lista)
final rewardsProvider = StreamProvider.family<List<RewardModel>, String>((ref, userId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getRewards(userId);
});

// Provider de recompensas activas
final activeRewardsProvider = Provider.family<List<RewardModel>, String>((ref, userId) {
  final rewardsAsync = ref.watch(rewardsProvider(userId));
  return rewardsAsync.when(
    data: (rewards) => rewards.where((reward) => reward.active).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Provider de recompensas por tipo
final rewardsByTypeProvider = Provider.family<Map<RewardType, List<RewardModel>>, String>((ref, userId) {
  final rewardsAsync = ref.watch(rewardsProvider(userId));
  return rewardsAsync.when(
    data: (rewards) {
      final Map<RewardType, List<RewardModel>> result = {
        RewardType.normal: [],
        RewardType.premium: [],
      };
      
      for (final reward in rewards) {
        result[reward.type]!.add(reward);
      }
      
      return result;
    },
    loading: () => {
      RewardType.normal: [],
      RewardType.premium: [],
    },
    error: (_, __) => {
      RewardType.normal: [],
      RewardType.premium: [],
    },
  );
});

// Notifier para manejar las acciones de recompensas
class RewardsNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  final StorageService _storageService;
  
  RewardsNotifier(this._firestoreService, this._storageService) : super(const AsyncValue.data(null));
  
  // Añadir recompensa
  Future<RewardModel?> addReward({
    required String userId,
    required String title,
    String? description,
    required RewardType type,
    required int cost,
    File? image,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Generar ID temporal para la recompensa
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Subir imagen si se proporciona
      String? imageUrl;
      if (image != null) {
        imageUrl = await _storageService.uploadRewardImage(
          userId: userId,
          imageFile: image,
          rewardId: tempId,
        );
      }
      
      // Crear modelo de recompensa
      final reward = RewardModel(
        id: tempId,
        title: title,
        description: description,
        type: type,
        cost: cost,
        imageUrl: imageUrl,
      );
      
      // Guardar en Firestore
      final addedReward = await _firestoreService.addReward(userId, reward);
      
      state = const AsyncValue.data(null);
      return addedReward;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }
  
  // Actualizar recompensa
  Future<bool> updateReward({
    required String userId,
    required String rewardId,
    String? title,
    String? description,
    RewardType? type,
    int? cost,
    File? newImage,
    bool? active,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Obtener la recompensa actual
      final rewardDoc = await _firestoreService.getRewardById(userId, rewardId);
      
      if (rewardDoc == null) {
        state = AsyncValue.error('La recompensa no existe', StackTrace.current);
        return false;
      }
      
      final currentReward = rewardDoc;
      
      // Procesar imagen si se proporciona
      String? imageUrl = currentReward.imageUrl;
      if (newImage != null) {
        // Eliminar imagen anterior si existe
        if (currentReward.imageUrl != null && currentReward.imageUrl!.isNotEmpty) {
          await _storageService.deleteImage(currentReward.imageUrl!);
        }
        
        // Subir nueva imagen
        imageUrl = await _storageService.uploadRewardImage(
          userId: userId,
          imageFile: newImage,
          rewardId: rewardId,
        );
      }
      
      // Actualizar modelo
      final updatedReward = currentReward.copyWith(
        title: title,
        description: description,
        type: type,
        cost: cost,
        imageUrl: imageUrl,
        active: active,
      );
      
      // Guardar en Firestore
      await _firestoreService.updateReward(userId, updatedReward);
      
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
  
  // Eliminar recompensa
  Future<bool> deleteReward({
    required String userId,
    required RewardModel reward,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Eliminar imagen si existe
      if (reward.imageUrl != null && reward.imageUrl!.isNotEmpty) {
        await _storageService.deleteImage(reward.imageUrl!);
      }
      
      // Eliminar documento
      await _firestoreService.deleteReward(userId, reward.id);
      
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
  
  // Desbloquear recompensa
  Future<bool> unlockReward({
    required String userId,
    required String weekId,
    required String rewardId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _firestoreService.unlockReward(
        userId,
        weekId,
        rewardId,
      );
      
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

// Provider del notifier de recompensas
final rewardsNotifierProvider = StateNotifierProvider<RewardsNotifier, AsyncValue<void>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return RewardsNotifier(firestoreService, storageService);
});
