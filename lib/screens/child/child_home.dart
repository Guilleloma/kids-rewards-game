import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/task_model.dart';
import '../../models/week_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/weeks_provider.dart';
import 'reward_catalog_screen.dart';
import 'confetti_animation.dart';

class ChildHome extends ConsumerStatefulWidget {
  const ChildHome({Key? key}) : super(key: key);

  @override
  ConsumerState<ChildHome> createState() => _ChildHomeState();
}

class _ChildHomeState extends ConsumerState<ChildHome> {
  // Control de confeti
  bool _showConfetti = false;
  
  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(userIdProvider);
    final userAsync = ref.watch(currentUserProvider);
    
    if (userId == null) {
      return Scaffold(
        body: Center(
          child: Text('Error: No hay usuario'),
        ),
      );
    }
    
    final currentWeekAsync = ref.watch(currentWeekProvider(userId));
    final activeTasks = ref.watch(activeTasksProvider(userId));
    
    return Scaffold(
      body: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: const Text('Mis Misiones'),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                // Botón de catálogo de premios
                IconButton(
                  icon: const Icon(Icons.card_giftcard),
                  tooltip: 'Ver premios',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RewardCatalogScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: userAsync.when(
              data: (user) {
                if (user == null) {
                  return const Center(
                    child: Text('Error: No se encontró el usuario'),
                  );
                }
                
                final childName = user.childName;
                
                return currentWeekAsync.when(
                  data: (week) {
                    if (week == null) {
                      return const Center(
                        child: Text('No hay una semana activa'),
                      );
                    }
                    
                    return _buildChildContent(
                      context,
                      userId,
                      childName,
                      week,
                      activeTasks,
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, _) => Center(
                    child: Text('Error: $error'),
                  ),
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
  
  Widget _buildChildContent(
    BuildContext context,
    String userId,
    String childName,
    WeekModel week,
    List<TaskModel> activeTasks,
  ) {
    // Ordenar tareas por completadas y no completadas
    final completedTaskIds = week.completedTasks;
    final completedTasks = activeTasks
        .where((task) => completedTaskIds.contains(task.id))
        .toList();
    final pendingTasks = activeTasks
        .where((task) => !completedTaskIds.contains(task.id))
        .toList();
    
    return Column(
      children: [
        // Banner con información del niño y progreso
        _buildProgressBanner(childName, week),
        
        // Lista de misiones
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tareas pendientes
                if (pendingTasks.isNotEmpty) ...[
                  Text(
                    'Mis misiones para hoy:',
                    style: Theme.of(context).textTheme.titleLarge,
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
                    itemCount: pendingTasks.length,
                    itemBuilder: (context, index) {
                      final task = pendingTasks[index];
                      return _buildTaskCard(
                        task: task, 
                        weekId: week.id,
                        userId: userId,
                        isCompleted: false,
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                ],
                
                // Tareas completadas
                if (completedTasks.isNotEmpty) ...[
                  Text(
                    '¡Misiones completadas!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.green,
                    ),
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
                    itemCount: completedTasks.length,
                    itemBuilder: (context, index) {
                      final task = completedTasks[index];
                      return _buildTaskCard(
                        task: task, 
                        weekId: week.id,
                        userId: userId,
                        isCompleted: true,
                      );
                    },
                  ),
                ],
                
                // Mensaje si no hay tareas
                if (activeTasks.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.emoji_events,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay misiones disponibles',
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
  
  Widget _buildProgressBanner(String childName, WeekModel week) {
    final coinsEarned = week.coinsEarned;
    final totalPoints = week.totalPoints;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Puntos y monedas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Puntos
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 24,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$totalPoints puntos',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                
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
                        '$coinsEarned',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Barra de progreso
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '¡Sigue así, $childName!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _getRewardMessage(totalPoints),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Barra visual
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _getProgressValue(totalPoints),
                    minHeight: 10,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTaskCard({
    required TaskModel task,
    required String weekId,
    required String userId,
    required bool isCompleted,
  }) {
    final hasImage = task.imageUrl.isNotEmpty;
    
    return GestureDetector(
      onTap: isCompleted 
          ? null 
          : () => _completeTask(task, weekId, userId),
      child: Card(
        elevation: isCompleted ? 1 : 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: isCompleted 
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
                  // Imagen de la tarea o placehoder
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: hasImage
                        ? Image.network(
                            task.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: _getCategoryColor(task.category).withOpacity(0.2),
                              child: const Center(
                                child: Icon(Icons.broken_image, size: 48),
                              ),
                            ),
                          )
                        : Container(
                            color: _getCategoryColor(task.category).withOpacity(0.2),
                            child: Center(
                              child: Icon(
                                _getCategoryIcon(task.category),
                                size: 48,
                                color: _getCategoryColor(task.category),
                              ),
                            ),
                          ),
                  ),
                  
                  // Overlay para tareas completadas
                  if (isCompleted)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_circle,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  
                  // Puntos en la esquina
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
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${task.points}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Título
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isCompleted 
                          ? Colors.grey.shade600 
                          : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Botón de completar (solo para tareas no completadas)
                  if (!isCompleted) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(task.category),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '¡Completar!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _completeTask(TaskModel task, String weekId, String userId) async {
    try {
      await ref.read(tasksNotifierProvider.notifier).completeTask(
        userId: userId,
        weekId: weekId,
        task: task,
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
            '¡Genial! Has completado: ${task.title}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: _getCategoryColor(task.category),
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
  
  Color _getCategoryColor(TaskCategory category) {
    switch (category) {
      case TaskCategory.daily:
        return Colors.blue;
      case TaskCategory.help:
        return Colors.green;
      case TaskCategory.brave:
        return Colors.orange;
    }
  }
  
  IconData _getCategoryIcon(TaskCategory category) {
    switch (category) {
      case TaskCategory.daily:
        return Icons.calendar_today;
      case TaskCategory.help:
        return Icons.handshake;
      case TaskCategory.brave:
        return Icons.shield;
    }
  }
  
  double _getProgressValue(int points) {
    if (points >= 90) return 1.0;
    if (points >= 80) return 0.9;
    if (points >= 70) return 0.8;
    if (points >= 60) return 0.7;
    if (points >= 50) return 0.6;
    if (points >= 40) return 0.5;
    if (points >= 30) return 0.4;
    if (points >= 20) return 0.3;
    if (points >= 10) return 0.2;
    return 0.1;
  }
  
  String _getRewardMessage(int points) {
    if (points >= 90) return '¡Super premio desbloqueado!';
    if (points >= 80) return '¡Premio desbloqueado!';
    if (points >= 70) return '¡Super premio desbloqueado!';
    if (points >= 60) return '¡Premio desbloqueado!';
    if (points >= 50) return '10 puntos más para premio';
    if (points >= 40) return '20 puntos más para premio';
    if (points >= 30) return '30 puntos más para premio';
    if (points >= 20) return '40 puntos más para premio';
    if (points >= 10) return '50 puntos más para premio';
    return 'Consigue puntos para premios';
  }
}
