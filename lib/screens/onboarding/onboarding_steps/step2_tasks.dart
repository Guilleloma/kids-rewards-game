import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/task_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/tasks_provider.dart';

class Step2Tasks extends ConsumerStatefulWidget {
  const Step2Tasks({Key? key}) : super(key: key);

  @override
  ConsumerState<Step2Tasks> createState() => _Step2TasksState();
}

class _Step2TasksState extends ConsumerState<Step2Tasks> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  TaskCategory _selectedCategory = TaskCategory.daily;
  int _selectedPoints = 1;
  File? _selectedImage;
  bool _isCreating = false;
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }
  
  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedCategory = TaskCategory.daily;
      _selectedPoints = 1;
      _selectedImage = null;
    });
  }
  
  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;
    
    final userId = ref.read(userIdProvider);
    if (userId == null) return;
    
    setState(() {
      _isCreating = true;
    });
    
    try {
      await ref.read(tasksNotifierProvider.notifier).addTask(
        userId: userId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        points: _selectedPoints,
        image: _selectedImage,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('tasks.taskAdded'.tr())),
      );
      
      _resetForm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(userIdProvider);
    final tasksAsync = userId != null ? ref.watch(tasksProvider(userId)) : const AsyncValue.loading();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // Título
          Text(
            'onboarding.step2Title'.tr(),
            style: Theme.of(context).textTheme.headline5,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Descripción
          Text(
            'onboarding.step2Description'.tr(),
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Formulario para crear tarea
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tarjeta con formulario
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Título de la tarea
                            TextFormField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                labelText: 'tasks.taskName'.tr(),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, introduce un título';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Descripción (opcional)
                            TextFormField(
                              controller: _descriptionController,
                              decoration: InputDecoration(
                                labelText: 'tasks.description'.tr(),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            
                            // Selección de categoría
                            Text('tasks.category'.tr(),
                                style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<TaskCategory>(
                              value: _selectedCategory,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: TaskCategory.values.map((category) {
                                String label;
                                IconData icon;
                                
                                switch (category) {
                                  case TaskCategory.daily:
                                    label = 'tasks.myDailyChallenges'.tr();
                                    icon = Icons.calendar_today;
                                    break;
                                  case TaskCategory.help:
                                    label = 'tasks.specialHelp'.tr();
                                    icon = Icons.handshake;
                                    break;
                                  case TaskCategory.brave:
                                    label = 'tasks.braveMissions'.tr();
                                    icon = Icons.shield;
                                    break;
                                }
                                
                                return DropdownMenuItem(
                                  value: category,
                                  child: Row(
                                    children: [
                                      Icon(icon),
                                      const SizedBox(width: 8),
                                      Text(label),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedCategory = value;
                                    _selectedPoints = value.points;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Selección de puntos
                            Text('tasks.points'.tr(),
                                style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            SegmentedButton<int>(
                              segments: [
                                ButtonSegment(
                                  value: 1,
                                  label: Text('1'),
                                  icon: Icon(Icons.star_border),
                                ),
                                ButtonSegment(
                                  value: 2,
                                  label: Text('2'),
                                  icon: Icon(Icons.star_half),
                                ),
                                ButtonSegment(
                                  value: 3,
                                  label: Text('3'),
                                  icon: Icon(Icons.star),
                                ),
                              ],
                              selected: {_selectedPoints},
                              onSelectionChanged: (newSelection) {
                                setState(() {
                                  _selectedPoints = newSelection.first;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Selección de imagen
                            Text('tasks.image'.tr(),
                                style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _pickImage,
                              child: Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: _selectedImage != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        ),
                                      )
                                    : Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.photo_camera,
                                              color: Colors.grey.shade400,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'tasks.selectImage'.tr(),
                                              style: TextStyle(
                                                color: Colors.grey.shade400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Botón para crear tarea
                            ElevatedButton(
                              onPressed: _isCreating ? null : _createTask,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                              ),
                              child: _isCreating
                                  ? const CircularProgressIndicator()
                                  : Text('tasks.addTask'.tr()),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Lista de tareas creadas
                    tasksAsync.when(
                      data: (tasks) {
                        if (tasks.isEmpty) {
                          return Center(
                            child: Text(
                              'Aún no has creado ninguna misión',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          );
                        }
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Misiones creadas (${tasks.length}):',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            for (final task in tasks)
                              ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(task.category),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${task.points}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(task.title),
                                subtitle: Text(_getCategoryName(task.category)),
                              ),
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, stackTrace) => Center(
                        child: Text('Error: $error'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
