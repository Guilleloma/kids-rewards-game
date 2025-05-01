import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/task_model.dart';
import '../../models/week_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../providers/weeks_provider.dart';
import '../child/child_home.dart';
import 'task_manager_screen.dart';
import 'reward_manager_screen.dart';
import 'settings_screen.dart';

class ParentDashboard extends ConsumerStatefulWidget {
  const ParentDashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends ConsumerState<ParentDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Asegurarnos de que existe una semana actual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureCurrentWeekExists();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _ensureCurrentWeekExists() async {
    final userId = ref.read(userIdProvider);
    if (userId == null) return;
    
    await ref.read(weeksNotifierProvider.notifier).ensureCurrentWeekExists(userId);
  }
  
  void _switchToChildMode() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ChildHome(),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(userIdProvider);
    final userAsync = ref.watch(currentUserProvider);
    final currentWeekAsync = userId != null 
      ? ref.watch(currentWeekProvider(userId))
      : const AsyncValue<WeekModel?>.loading();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('app.title'.tr()),
        actions: [
          // Botón para modo niño
          IconButton(
            icon: const Icon(Icons.child_care),
            tooltip: 'dashboard.childMode'.tr(),
            onPressed: _switchToChildMode,
          ),
          // Menú
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings, size: 20),
                    const SizedBox(width: 8),
                    Text('dashboard.settings'.tr()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    const Icon(Icons.refresh, size: 20),
                    const SizedBox(width: 8),
                    Text('dashboard.resetWeek'.tr()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.exit_to_app, size: 20),
                    const SizedBox(width: 8),
                    const Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'settings') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              } else if (value == 'reset') {
                _showResetWeekConfirmation();
              } else if (value == 'logout') {
                await ref.read(authNotifierProvider.notifier).signOut();
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          tabs: [
            Tab(
              text: 'dashboard.weekProgress'.tr(),
              icon: const Icon(Icons.calendar_today),
              height: 56,
            ),
            Tab(
              text: 'tasks.myDailyChallenges'.tr(),
              icon: const Icon(Icons.task_alt),
              height: 56,
            ),
            Tab(
              text: 'rewards.myRewards'.tr(),
              icon: const Icon(Icons.card_giftcard),
              height: 56,
            ),
          ],
        ),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            // Si no hay usuario, volver a login
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed('/login');
            });
            return const Center(child: CircularProgressIndicator());
          }
          
          final childName = user.childName;
          
          return TabBarView(
            controller: _tabController,
            children: [
              // Pestaña de progreso semanal
              _buildWeeklyProgressTab(userId!, childName, currentWeekAsync),
              
              // Pestaña de gestión de tareas
              TaskManagerScreen(userId: userId),
              
              // Pestaña de gestión de recompensas
              RewardManagerScreen(userId: userId),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
  
  Widget _buildWeeklyProgressTab(
    String userId, 
    String childName, 
    AsyncValue<WeekModel?> currentWeekAsync
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado con nombre del niño
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Theme.of(context).colorScheme.primary,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: const Icon(
                      Icons.child_care,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          childName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        currentWeekAsync.when(
                          data: (week) {
                            if (week == null) return const SizedBox.shrink();
                            
                            final formatter = DateFormat('d MMM');
                            return Text(
                              '${formatter.format(week.startDate)} - ${formatter.format(week.endDate)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            );
                          },
                          loading: () => const Text(
                            'Cargando...',
                            style: TextStyle(color: Colors.white),
                          ),
                          error: (_, __) => const Text(
                            'Error al cargar fecha',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Estadísticas de la semana
          Text(
            'dashboard.weeklyStats'.tr(),
            style: Theme.of(context).textTheme.headline6,
          ),
          const SizedBox(height: 16),
          
          currentWeekAsync.when(
            data: (week) {
              if (week == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('dashboard.noWeekYet'.tr()),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          await ref.read(weeksNotifierProvider.notifier).createNewWeek(userId);
                        },
                        child: Text('dashboard.createNewWeek'.tr()),
                      ),
                    ],
                  ),
                );
              }
              
              return _buildWeekStats(userId, week);
            },
            loading: () => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('dashboard.loading'.tr()),
                ],
              ),
            ),
            error: (error, stackTrace) {
              // Verificar si es un error de índice de Firestore
              if (error.toString().contains('[cloud_firestore/failed-precondition]')) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Se necesita crear un índice en Firestore',
                          style: Theme.of(context).textTheme.headline6,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Firebase necesita crear un índice para esta consulta. Por favor, haz clic en el enlace que aparece en la consola de desarrollador o sigue estas instrucciones:',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('1. Ve a la consola de Firebase'),
                              Text('2. Selecciona tu proyecto'),
                              Text('3. Ve a Firestore Database > Índices'),
                              Text('4. Añade un índice compuesto para:'),
                              Padding(
                                padding: EdgeInsets.only(left: 16.0),
                                child: Text('- Colección: users/{userId}/weeks'),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 16.0),
                                child: Text('- Campo 1: startDate (Ascendente)'),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 16.0),
                                child: Text('- Campo 2: endDate (Ascendente)'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _ensureCurrentWeekExists(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              // Para otros errores
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('errors.database'.tr()),
                    const SizedBox(height: 8),
                    Text(error.toString(), maxLines: 3, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _ensureCurrentWeekExists(),
                      child: Text('common.retry'.tr()),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildWeekStats(String userId, WeekModel week) {
    final tasksAsync = ref.watch(tasksProvider(userId));
    
    return Column(
      children: [
        // Tarjetas de estadísticas
        Row(
          children: [
            // Puntos totales
            Expanded(
              child: _buildStatCard(
                icon: Icons.star,
                color: Colors.amber,
                title: 'Puntos totales',
                value: week.totalPoints.toString(),
              ),
            ),
            const SizedBox(width: 12),
            // Monedas ganadas
            Expanded(
              child: _buildStatCard(
                icon: Icons.monetization_on,
                color: Colors.green,
                title: 'Monedas ganadas',
                value: week.coinsEarned.toString(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Tareas completadas
            Expanded(
              child: _buildStatCard(
                icon: Icons.task_alt,
                color: Colors.blue,
                title: 'Misiones completadas',
                value: '${week.completedTasks.length}',
              ),
            ),
            const SizedBox(width: 12),
            // Recompensas desbloqueadas
            Expanded(
              child: _buildStatCard(
                icon: Icons.card_giftcard,
                color: Colors.purple,
                title: 'Premios desbloqueados',
                value: '${week.rewardsEarned.length}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Lista de tareas completadas
        Text(
          'Misiones completadas esta semana:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        tasksAsync.when(
          data: (allTasks) {
            final completedTasks = allTasks
                .where((task) => week.completedTasks.contains(task.id))
                .toList();
            
            if (completedTasks.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'No hay misiones completadas todavía',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }
            
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: completedTasks.length,
              itemBuilder: (context, index) {
                final task = completedTasks[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getCategoryColor(task.category),
                      child: Text(
                        '${task.points}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(task.title),
                    subtitle: Text(_getCategoryName(task.category)),
                    trailing: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, _) => Center(
            child: Text('Error: $error'),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showResetWeekConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reiniciar semana'),
        content: const Text(
          '¿Estás seguro de que quieres reiniciar la semana actual? '
          'Esto creará una nueva semana y todos los puntos y misiones completadas se reiniciarán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final userId = ref.read(userIdProvider);
              if (userId == null) return;
              
              await ref.read(weeksNotifierProvider.notifier).resetWeek(userId);
              
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Semana reiniciada correctamente')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('common.confirm'.tr()),
          ),
        ],
      ),
    );
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
  
  String _getCategoryName(TaskCategory category) {
    switch (category) {
      case TaskCategory.daily:
        return 'tasks.myDailyChallenges'.tr();
      case TaskCategory.help:
        return 'tasks.specialHelp'.tr();
      case TaskCategory.brave:
        return 'tasks.braveMissions'.tr();
    }
  }
}
