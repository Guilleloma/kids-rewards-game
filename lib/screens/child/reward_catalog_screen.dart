import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/reward_model.dart';
import '../../models/week_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../providers/weeks_provider.dart';
import 'confetti_animation.dart';

class RewardCatalogScreen extends ConsumerStatefulWidget {
  const RewardCatalogScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RewardCatalogScreen> createState() => _RewardCatalogScreenState();
}

class _RewardCatalogScreenState extends ConsumerState<RewardCatalogScreen> {
  bool _showConfetti = false;
  
  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(userIdProvider);
    
    if (userId == null) {
      return Scaffold(
        body: Center(
          child: Text('Error: No hay usuario'),
        ),
      );
    }
    
    final currentWeekAsync = ref.watch(currentWeekProvider(userId));
    final activeRewards = ref.watch(activeRewardsProvider(userId));
    
    return Scaffold(
      body: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: const Text('Mis Premios'),
              centerTitle: true,
            ),
            body: currentWeekAsync.when(
              data: (week) {
                if (week == null) {
                  return const Center(
                    child: Text('No hay una semana activa'),
                  );
                }
                
                return _buildCatalogContent(
                  context,
                  userId,
                  week,
                  activeRewards,
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
          
          // Animación de confeti
          if (_showConfetti) ConfettiAnimation(
            onComplete: () {
              setState(() {
                _showConfetti = false;
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildCatalogContent(
    BuildContext context,
    String userId,
    WeekModel week,
    List<RewardModel> activeRewards,
  ) {
    // Filtrar las monedas, ya que estas se obtienen automáticamente y no se canjean
    final canjeableRewards = activeRewards
        .where((reward) => reward.type != RewardType.coin)
        .toList();
    
    // Separar recompensas por tipo
    final normalRewards = canjeableRewards
        .where((reward) => reward.type == RewardType.normal)
        .toList();
    final superRewards = canjeableRewards
        .where((reward) => reward.type == RewardType.premium)
        .toList();
    
    // Obtener lista de recompensas ya desbloqueadas
    final unlockedRewardIds = week.rewardsEarned;
    
    return Column(
      children: [
        // Banner con puntos y monedas
        _buildPointsBanner(week),
        
        // Lista de recompensas
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Premios normales
                if (normalRewards.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.card_giftcard, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'rewards.myRewards'.tr(),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: normalRewards.length,
                    itemBuilder: (context, index) {
                      final reward = normalRewards[index];
                      final isUnlocked = unlockedRewardIds.contains(reward.id);
                      final canUnlock = week.totalPoints >= reward.cost && !isUnlocked;
                      
                      return _buildRewardCard(
                        reward: reward,
                        weekId: week.id,
                        userId: userId,
                        isUnlocked: isUnlocked,
                        canUnlock: canUnlock,
                        currentPoints: week.totalPoints,
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                ],
                
                // Super premios
                if (superRewards.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.workspace_premium, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        'Super rewards',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: superRewards.length,
                    itemBuilder: (context, index) {
                      final reward = superRewards[index];
                      final isUnlocked = unlockedRewardIds.contains(reward.id);
                      final canUnlock = week.totalPoints >= reward.cost && !isUnlocked;
                      
                      return _buildRewardCard(
                        reward: reward,
                        weekId: week.id,
                        userId: userId,
                        isUnlocked: isUnlocked,
                        canUnlock: canUnlock,
                        currentPoints: week.totalPoints,
                      );
                    },
                  ),
                ],
                
                // Mensaje si no hay recompensas
                if (canjeableRewards.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.card_giftcard,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay premios disponibles',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPointsBanner(WeekModel week) {
    final totalPoints = week.totalPoints;
    final coinsEarned = week.coinsEarned;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple,
            Colors.deepPurple,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Titulo
            const Text(
              'Mi catálogo de premios',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Puntos y monedas
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Puntos
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$totalPoints puntos',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Monedas
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$coinsEarned monedas',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRewardCard({
    required RewardModel reward,
    required String weekId,
    required String userId,
    required bool isUnlocked,
    required bool canUnlock,
    required int currentPoints,
  }) {
    final color = reward.type == RewardType.normal 
        ? Colors.blue
        : reward.type == RewardType.premium
            ? Colors.amber
            : Colors.green;
    final hasImage = reward.imageUrl != null && reward.imageUrl!.isNotEmpty;
    final pointsNeeded = reward.cost - currentPoints;
    
    return Card(
      elevation: isUnlocked ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isUnlocked 
          ? Colors.grey.shade100 
          : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Imagen
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Imagen de la recompensa o placehoder
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: hasImage
                      ? Image.network(
                          reward.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: color.withOpacity(0.2),
                            child: const Center(
                              child: Icon(Icons.broken_image, size: 48),
                            ),
                          ),
                        )
                      : Container(
                          color: color.withOpacity(0.2),
                          child: Center(
                            child: Icon(
                              reward.type == RewardType.normal
                                  ? Icons.card_giftcard
                                  : reward.type == RewardType.premium
                                      ? Icons.workspace_premium
                                      : Icons.monetization_on,
                              size: 48,
                              color: color,
                            ),
                          ),
                        ),
                ),
                
                // Overlay para recompensas desbloqueadas
                if (isUnlocked)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            size: 48,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '¡DESBLOQUEADO!',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Overlay para recompensas bloqueadas
                if (!isUnlocked && !canUnlock)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.lock,
                            size: 48,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Faltan $pointsNeeded puntos',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Coste en la esquina
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${reward.cost}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Título y botón
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isUnlocked 
                        ? Colors.grey.shade600 
                        : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Descripción (si tiene)
                if (reward.description != null && reward.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      reward.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isUnlocked 
                            ? Colors.grey.shade500 
                            : Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                
                // Botón de desbloquear (solo si puede desbloquear)
                if (canUnlock) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _unlockReward(reward, weekId, userId),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.lock_open,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '¡Desbloquear!',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _unlockReward(RewardModel reward, String weekId, String userId) async {
    try {
      await ref.read(rewardsNotifierProvider.notifier).unlockReward(
        userId: userId,
        weekId: weekId,
        rewardId: reward.id,
      );
      
      // Mostrar confeti
      setState(() {
        _showConfetti = true;
      });
      
      if (!mounted) return;
      
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Has desbloqueado: ${reward.title}!',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: reward.type == RewardType.normal
              ? Colors.blue
              : reward.type == RewardType.premium
                  ? Colors.amber
                  : Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
