import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/task_model.dart';
import '../../models/week_model.dart';
import '../../models/reward_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../providers/weeks_provider.dart';
import 'reward_catalog_screen.dart';
import 'confetti_animation.dart';
import 'package:collection/collection.dart';

class ChildHome extends ConsumerStatefulWidget {
  const ChildHome({Key? key}) : super(key: key);

  @override
  ConsumerState<ChildHome> createState() => _ChildHomeState();
}

class _ChildHomeState extends ConsumerState<ChildHome> {
  // Control de confeti
  bool _showConfetti = false;
  
  // Día seleccionado para la vista semanal
  DateTime _selectedDay = DateTime.now();
  
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
                    
                    return Column(
                      children: [
                        // Banner con progreso y puntos
                        _buildProgressBanner(childName, week, ref.watch(activeRewardsProvider(userId))),
                        
                        // Selector de días de la semana
                        _buildDaySelector(week, activeTasks!),
                        
                        // Contenido principal
                        Expanded(
                          child: _buildChildContent(
                            context,
                            userId,
                            childName,
                            week,
                            activeTasks,
                          ),
                        ),
                      ],
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
  
  // Selector de días
  Widget _buildDaySelector(WeekModel week, List<TaskModel> activeTasks) {
    // Calcular los 7 días de la semana actual
    final today = DateTime.now();
    final weekStart = DateTime(week.startDate.year, week.startDate.month, week.startDate.day);
    
    // Generar una lista de los 7 días de la semana
    final weekDays = List.generate(7, (index) => 
      weekStart.add(Duration(days: index)));
    
    // Formatear los nombres de los días
    final dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    
    // Creamos un mapa de tareas por ID para acceso rápido
    final Map<String, TaskModel> taskMap = {};
    for (final task in activeTasks) {
      taskMap[task.id] = task;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (index) {
            final day = weekDays[index];
            final isToday = day.day == today.day && 
                           day.month == today.month && 
                           day.year == today.year;
            final dayName = dayNames[day.weekday - 1]; // -1 porque weekday va de 1-7
            
            // Calcular puntos ganados este día
            final pointsEarnedOnDay = week.getPointsEarnedOnDay(day, taskMap);
            
            // Verificar si este día es el seleccionado
            final isSelected = _selectedDay.day == day.day && 
                              _selectedDay.month == day.month && 
                              _selectedDay.year == day.year;
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ChoiceChip(
                label: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dayName,
                      style: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontWeight: isToday ? FontWeight.bold : null,
                      ),
                    ),
                    Text(
                      day.day.toString(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontWeight: isToday ? FontWeight.bold : null,
                      ),
                    ),
                    if (pointsEarnedOnDay > 0)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Colors.white 
                              : Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$pointsEarnedOnDay',
                          style: TextStyle(
                            color: isSelected 
                                ? Theme.of(context).primaryColor 
                                : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                selected: isSelected,
                selectedColor: Theme.of(context).primaryColor,
                backgroundColor: isToday 
                    ? Theme.of(context).primaryColor.withOpacity(0.1) 
                    : null,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedDay = day;
                    });
                  }
                },
              ),
            );
          }),
        ),
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
    // Obtener lista de tareas completadas (ahora filtradas por día)
    List<String> completedTaskIds = [];
    
    // Si estamos viendo el día actual
    final today = DateTime.now();
    final isViewingToday = _selectedDay.day == today.day && 
                         _selectedDay.month == today.month && 
                         _selectedDay.year == today.year;
    
    // Obtener SOLO las tareas completadas en el día seleccionado
    // De esta forma, las tareas solo aparecerán como completadas el día que se completaron
    completedTaskIds = week.getTasksCompletedOnDay(_selectedDay);
    
    // Separar tareas por categoría
    final dailyTasks = activeTasks
        .where((task) => task.category == TaskCategory.daily)
        .toList();
    final helpTasks = activeTasks
        .where((task) => task.category == TaskCategory.help)
        .toList();
    final braveTasks = activeTasks
        .where((task) => task.category == TaskCategory.brave)
        .toList();
    
    // Obtener la lista de recompensas disponibles
    final rewards = ref.watch(activeRewardsProvider(userId));
    
    return Column(
      children: [
        // Lista de tareas
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isViewingToday 
                      ? 'Mis misiones para hoy:' 
                      : 'Misiones para ${DateFormat('EEEE d', 'es').format(_selectedDay)}:',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                
                // Retos diarios
                if (dailyTasks.isNotEmpty) ...[
                  _buildCategoryHeader(
                    context,
                    'tasks.myDailyChallenges'.tr(),
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  _buildTasksGrid(
                    context, 
                    dailyTasks, 
                    week.id, 
                    userId, 
                    completedTaskIds,
                    isViewingToday,
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Ayuda especial
                if (helpTasks.isNotEmpty) ...[
                  _buildCategoryHeader(
                    context,
                    'tasks.specialHelp'.tr(),
                    Icons.handshake,
                    Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _buildTasksGrid(
                    context, 
                    helpTasks, 
                    week.id, 
                    userId, 
                    completedTaskIds,
                    isViewingToday,
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Misiones valientes
                if (braveTasks.isNotEmpty) ...[
                  _buildCategoryHeader(
                    context,
                    'tasks.braveMissions'.tr(),
                    Icons.shield,
                    Colors.orange,
                  ),
                  const SizedBox(height: 8),
                  _buildTasksGrid(
                    context, 
                    braveTasks, 
                    week.id, 
                    userId, 
                    completedTaskIds,
                    isViewingToday,
                  ),
                ],
                
                // Mensaje si no hay tareas
                if (activeTasks.isEmpty)
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt,
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
  
  Widget _buildProgressBanner(String childName, WeekModel week, List<RewardModel> rewards) {
    final coinsEarned = week.coinsEarned;
    final totalPoints = week.totalPoints;
    
    // Ordenar las recompensas por costo (de menor a mayor)
    final sortedRewards = [...rewards];
    sortedRewards.sort((a, b) => a.cost.compareTo(b.cost));
    
    // Determinar el costo máximo para escalar la barra de progreso
    int maxCost = 100; // Valor predeterminado
    if (sortedRewards.isNotEmpty) {
      // Usar el costo del premio más alto + 10 para dar margen
      maxCost = sortedRewards.last.cost + 10;
    }
    
    // Encontrar el próximo premio a desbloquear
    RewardModel? nextReward;
    for (var reward in sortedRewards) {
      if (totalPoints < reward.cost) {
        nextReward = reward;
        break;
      }
    }
    
    // Calcular puntos restantes para el próximo premio
    int remainingPoints = 0;
    if (nextReward != null) {
      remainingPoints = nextReward.cost - totalPoints;
    }
    
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
                    if (nextReward != null)
                      Text(
                        'Faltan $remainingPoints pts para ${nextReward.title}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      )
                    else
                      const Text(
                        '¡Has ganado todos los premios!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Barra visual mejorada con marcadores de premio
                SizedBox(
                  height: 80, // Aumentamos la altura para acomodar elementos por encima y debajo
                  child: Stack(
                    children: [
                      // Agrupar premios por costo para manejar múltiples premios en la misma posición
                      ..._buildGroupedRewardIcons(sortedRewards, totalPoints, maxCost, context),
                      
                      // Barra de progreso en el MEDIO
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 35, // Centrada verticalmente
                        child: SizedBox(
                          height: 15,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: totalPoints / maxCost, // Progreso escalado al costo máximo
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                            ),
                          ),
                        ),
                      ),
                      
                      // Marcadores verticales en la barra para cada punto de costo único
                      ..._getUniqueRewardCosts(sortedRewards).map((cost) {
                        final position = cost / maxCost;
                        return Positioned(
                          left: MediaQuery.of(context).size.width * position * 0.83 - 1, // Ajuste para centrar
                          top: 35, // Alineado con la barra
                          child: Container(
                            width: 2,
                            height: 15,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        );
                      }).toList(),
                      
                      // Números de puntos DEBAJO de la barra (solo para costos únicos)
                      ..._getUniqueRewardCosts(sortedRewards).map((cost) {
                        final position = cost / maxCost;
                        final isUnlocked = totalPoints >= cost;
                        
                        return Positioned(
                          left: MediaQuery.of(context).size.width * position * 0.83 - 15,
                          top: 55, // Debajo de la barra
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isUnlocked 
                                  ? Colors.amber // Color para múltiples premios
                                  : Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '$cost',
                              style: TextStyle(
                                color: isUnlocked 
                                    ? Colors.white 
                                    : Colors.black87,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
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
  
  // Método para construir los encabezados de categoría
  Widget _buildCategoryHeader(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksGrid(
    BuildContext context,
    List<TaskModel> tasks,
    String weekId,
    String userId,
    List<String> completedTaskIds,
    bool isInteractive, // Nuevo parámetro para saber si se permite interacción
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determinar número de columnas según el ancho disponible
        int crossAxisCount = 2; // Predeterminado para pantallas pequeñas
        double childAspectRatio = 0.9; // Más compactas (casi cuadradas)
        
        if (constraints.maxWidth > 900) {
          crossAxisCount = 5; // Pantallas muy grandes (5 columnas)
          childAspectRatio = 0.85;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 4; // Tablets y pantallas medianas
          childAspectRatio = 0.9;
        } else if (constraints.maxWidth > 400) {
          crossAxisCount = 3; // Teléfonos más grandes
        }
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 6, // Espacio reducido
            mainAxisSpacing: 6,  // Espacio reducido
          ),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return _buildTaskCard(
              task: task, 
              weekId: weekId,
              userId: userId,
              isCompleted: completedTaskIds.contains(task.id),
              isInteractive: isInteractive,
            );
          },
        );
      }
    );
  }
  
  Widget _buildTaskCard({
    required TaskModel task,
    required String weekId,
    required String userId,
    required bool isCompleted,
    required bool isInteractive, // Nuevo parámetro para saber si se permite interacción
  }) {
    final color = _getCategoryColor(task.category);
    final lightColor = color.withOpacity(0.15); // Color de fondo claro basado en la categoría
    
    // Colores para tareas completadas
    final completedHeaderColor = Colors.grey;
    final completedBgColor = Colors.grey.shade100;
    
    return Tooltip(
      message: isCompleted && isInteractive ? "Mantén pulsado para desmarcar" : "",
      child: GestureDetector(
        onTap: isInteractive && !isCompleted 
            ? () => _completeTask(task, weekId, userId)
            : null,
        onLongPress: isInteractive && isCompleted 
            ? () => _uncompleteTask(task, weekId, userId)
            : null,
        child: Card(
          elevation: 2,
          margin: const EdgeInsets.all(2), // Margen reducido
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Radio reducido
            side: BorderSide(
              color: isCompleted ? Colors.grey.shade300 : color.withOpacity(0.5),
              width: 1,
            ),
          ),
          color: isCompleted ? completedBgColor : lightColor,
          child: Stack(
            children: [
              // Contenido principal de la tarjeta
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cabecera con puntos y estado
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Padding reducido
                    decoration: BoxDecoration(
                      color: isCompleted ? completedHeaderColor : color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isCompleted ? Icons.calendar_today : _getCategoryIcon(task.category),
                              color: Colors.white,
                              size: 14, // Icono más pequeño
                            ),
                            const SizedBox(width: 2), // Espacio reducido
                            Text(
                              '${task.points} pts',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12, // Texto más pequeño
                              ),
                            ),
                          ],
                        ),
                        if (isCompleted)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 14, // Icono más pequeño
                          ),
                      ],
                    ),
                  ),
                  
                  // Contenido
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0), // Padding reducido
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12, // Texto más pequeño
                                color: isCompleted 
                                    ? Colors.grey.shade600 
                                    : Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          // Botón de completar (solo para tareas no completadas)
                          if (!isCompleted && isInteractive)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 4, // Padding reducido
                                horizontal: 6, // Padding reducido
                              ),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(4), // Radio reducido
                              ),
                              child: const Text(
                                '¡Completar!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10, // Texto más pequeño
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // Overlay con sello de verificación para tareas completadas
              if (isCompleted)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
  
  // Método para desmarcar una tarea como completada (deshacer)
  Future<void> _uncompleteTask(TaskModel task, String weekId, String userId) async {
    try {
      // Mostrar un diálogo de confirmación antes de desmarcar
      final shouldUndo = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Desmarcar tarea'),
          content: Text('¿Estás seguro de que quieres desmarcar la tarea "${task.title}" como completada?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Desmarcar'),
            ),
          ],
        ),
      ) ?? false;
      
      if (!shouldUndo) return;
      
      await ref.read(tasksNotifierProvider.notifier).uncompleteTask(
        userId: userId,
        weekId: weekId,
        task: task,
      );
      
      if (!mounted) return;
      
      // Mostrar mensaje de confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tarea desmarcada: ${task.title}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.orange,
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
  
  List<Widget> _buildGroupedRewardIcons(List<RewardModel> rewards, int totalPoints, int maxCost, BuildContext context) {
    // Agrupar recompensas por costo
    final Map<int, List<RewardModel>> groupedRewards = {};
    for (var reward in rewards) {
      if (!groupedRewards.containsKey(reward.cost)) {
        groupedRewards[reward.cost] = [];
      }
      groupedRewards[reward.cost]!.add(reward);
    }
    
    return groupedRewards.entries.map((entry) {
      final cost = entry.key;
      final rewardsAtCost = entry.value;
      
      final position = cost / maxCost;
      final isUnlocked = totalPoints >= cost;
      
      return Positioned(
        left: MediaQuery.of(context).size.width * position * 0.83 - 15, // Ajuste para centrar
        top: 0, // Posición en la parte superior
        child: Tooltip(
          message: rewardsAtCost.map((reward) => '${reward.title} ($cost puntos)').join('\n'),
          textStyle: const TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
            decoration: BoxDecoration(
              color: isUnlocked 
                  ? Colors.blue.shade700 // Color para múltiples premios
                  : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: rewardsAtCost.map((reward) {
                // Determinar color del icono basado en el tipo de recompensa
                Color iconColor = isUnlocked ? Colors.white : Colors.black87;
                // Si hay múltiples iconos, usa diferentes colores para distinguirlos
                if (rewardsAtCost.length > 1) {
                  iconColor = reward.type == RewardType.premium 
                      ? Colors.orange
                      : reward.type == RewardType.coin
                          ? Colors.amber
                          : Colors.green;
                }
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    reward.type == RewardType.premium
                        ? Icons.emoji_events // Trofeo para Super Premio
                        : reward.type == RewardType.coin
                            ? Icons.monetization_on // Moneda para premio tipo moneda
                            : Icons.card_giftcard, // Regalo para Premio normal
                    color: iconColor,
                    size: 12, // Tamaño reducido para acomodar múltiples iconos
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      );
    }).toList();
  }
  
  List<int> _getUniqueRewardCosts(List<RewardModel> rewards) {
    return rewards.map((reward) => reward.cost).toSet().toList();
  }
}
