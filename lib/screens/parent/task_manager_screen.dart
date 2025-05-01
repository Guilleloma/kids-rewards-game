import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/task_model.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/service_providers.dart';

class TaskManagerScreen extends ConsumerStatefulWidget {
  final String userId;
  
  const TaskManagerScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<TaskManagerScreen> createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends ConsumerState<TaskManagerScreen> {
  TaskCategory _selectedFilter = TaskCategory.daily;
  
  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider(widget.userId));
    
    return Scaffold(
      body: Column(
        children: [
          // Filtros de categoría
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildFilterChip(
                    TaskCategory.daily,
                    'tasks.myDailyChallenges'.tr(),
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    TaskCategory.help,
                    'tasks.specialHelp'.tr(),
                    Icons.handshake,
                    Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    TaskCategory.brave,
                    'tasks.braveMissions'.tr(),
                    Icons.shield,
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ),
          
          // Lista de tareas
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                final filteredTasks = tasks
                    .where((task) => task.category == _selectedFilter)
                    .toList();
                
                if (filteredTasks.isEmpty) {
                  return Center(
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
                          'No hay misiones en esta categoría',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    return _buildTaskCard(task);
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEditTaskDialog();
        },
        child: const Icon(Icons.add),
        tooltip: 'tasks.addTask'.tr(),
      ),
    );
  }
  
  Widget _buildFilterChip(
    TaskCategory category,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedFilter == category;
    
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      avatar: Icon(
        icon,
        color: isSelected ? Colors.white : color,
        size: 18,
      ),
      backgroundColor: Colors.grey.shade100,
      selectedColor: color,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      onSelected: (selected) {
        setState(() {
          _selectedFilter = category;
        });
      },
    );
  }
  
  Widget _buildTaskCard(TaskModel task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: task.active ? Colors.transparent : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen de la tarea (si tiene)
          if (task.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                width: double.infinity,
                height: 120,
                child: Image.network(
                  task.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 48),
                    ),
                  ),
                ),
              ),
            ),
          
          // Contenido de la tarea
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Puntos
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(task.category).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${task.points} pts',
                        style: TextStyle(
                          color: _getCategoryColor(task.category),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Título y descripción
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: task.active 
                                  ? Colors.black87
                                  : Colors.grey.shade500,
                            ),
                          ),
                          if (task.description != null && task.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                task.description!,
                                style: TextStyle(
                                  color: task.active 
                                      ? Colors.black54
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Categoría y acciones
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Categoría
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getCategoryIcon(task.category),
                            size: 16,
                            color: _getCategoryColor(task.category),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getCategoryName(task.category),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getCategoryColor(task.category),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Botones de acción
                    Row(
                      children: [
                        // Cambiar estado activo
                        IconButton(
                          icon: Icon(
                            task.active 
                                ? Icons.visibility 
                                : Icons.visibility_off,
                            color: task.active
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          onPressed: () {
                            _toggleTaskActive(task);
                          },
                          tooltip: task.active
                              ? 'Desactivar'
                              : 'Activar',
                        ),
                        // Editar
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.amber),
                          onPressed: () {
                            _showAddEditTaskDialog(task: task);
                          },
                          tooltip: 'tasks.editTask'.tr(),
                        ),
                        // Eliminar
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _showDeleteTaskConfirmation(task);
                          },
                          tooltip: 'tasks.deleteTask'.tr(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _toggleTaskActive(TaskModel task) async {
    try {
      await ref.read(tasksNotifierProvider.notifier).updateTask(
        userId: widget.userId,
        taskId: task.id,
        active: !task.active,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            task.active
                ? 'Misión desactivada'
                : 'Misión activada',
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
  
  void _showAddEditTaskDialog({TaskModel? task}) {
    showDialog(
      context: context,
      builder: (context) => TaskFormDialog(
        userId: widget.userId,
        task: task,
        initialCategory: task?.category ?? _selectedFilter,
      ),
    );
  }
  
  void _showDeleteTaskConfirmation(TaskModel task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('tasks.deleteTask'.tr()),
        content: Text('¿Estás seguro de que quieres eliminar la misión "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              try {
                await ref.read(tasksNotifierProvider.notifier).deleteTask(
                  userId: widget.userId,
                  task: task,
                );
                
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('tasks.taskDeleted'.tr())),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Eliminar'),
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

class TaskFormDialog extends ConsumerStatefulWidget {
  final String userId;
  final TaskModel? task;
  final TaskCategory initialCategory;
  
  const TaskFormDialog({
    Key? key,
    required this.userId,
    this.task,
    required this.initialCategory,
  }) : super(key: key);

  @override
  ConsumerState<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends ConsumerState<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  
  late TaskCategory _selectedCategory;
  File? _selectedImage;
  Uint8List? _selectedImageBytes; // Para compatibilidad con web
  bool _isWeb = kIsWeb; // Detectar si estamos en web
  
  String? _existingImageUrl;
  late int _selectedPoints;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar con datos de la tarea si existe
    if (widget.task != null) {
      _titleController = TextEditingController(text: widget.task!.title);
      _descriptionController = TextEditingController(text: widget.task!.description ?? '');
      _selectedCategory = widget.task!.category;
      _selectedPoints = widget.task!.points;
      _existingImageUrl = widget.task!.imageUrl;
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _selectedCategory = widget.initialCategory;
      _selectedPoints = widget.initialCategory.points;
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        setState(() {
          if (_isWeb) {
            // Para web, guardar como bytes
            pickedFile.readAsBytes().then((value) {
              setState(() {
                _selectedImageBytes = value;
                _selectedImage = null; // No usamos File en web
              });
            });
          } else {
            // Para móvil, mantener compatibilidad con File
            _selectedImage = File(pickedFile.path);
            _selectedImageBytes = null;
          }
        });
      }
    } catch (e) {
      // Mostrar mensaje amigable según los principios de Nielsen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo cargar la imagen. Por favor, intenta con otra.'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Entendido',
            onPressed: () {},
          ),
        ),
      );
    }
  }
  
  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final title = _titleController.text.trim();
        final description = _descriptionController.text.trim();
        
        // Subir imagen si existe
        String? imageUrl;
        if (_selectedImage != null || _selectedImageBytes != null) {
          // Crear un nombre único para la imagen usando timestamp
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final imageName = 'task_$timestamp.jpg';
          
          if (_isWeb && _selectedImageBytes != null) {
            // Para web, subir los bytes
            imageUrl = await ref.read(storageServiceProvider).uploadTaskImageBytes(
              userId: widget.userId,
              fileName: imageName,
              imageBytes: _selectedImageBytes!,
            );
          } else if (_selectedImage != null) {
            // Para móvil, subir el archivo
            imageUrl = await ref.read(storageServiceProvider).uploadTaskImage(
              userId: widget.userId,
              fileName: imageName,
              imageFile: _selectedImage!,
            );
          }
        } else if (_existingImageUrl != null) {
          // Mantener la imagen existente
          imageUrl = _existingImageUrl;
        }
        
        if (widget.task == null) {
          // Crear nueva tarea
          await ref.read(tasksNotifierProvider.notifier).addTask(
            userId: widget.userId,
            title: title,
            description: description,
            category: _selectedCategory,
            points: _selectedPoints,
            image: _isWeb ? null : _selectedImage,
            imageBytes: _isWeb ? _selectedImageBytes : null,
            imageUrl: imageUrl,
          );
        } else {
          // Actualizar tarea existente
          await ref.read(tasksNotifierProvider.notifier).updateTask(
            userId: widget.userId,
            taskId: widget.task!.id,
            title: title,
            description: description,
            category: _selectedCategory,
            points: _selectedPoints,
            newImage: _isWeb ? null : _selectedImage,
            newImageBytes: _isWeb ? _selectedImageBytes : null,
            newImageUrl: imageUrl,
          );
        }
        
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.task == null
                  ? 'tasks.taskAdded'.tr()
                  : 'tasks.taskUpdated'.tr(),
            ),
          ),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.task == null
            ? 'tasks.addTask'.tr()
            : 'tasks.editTask'.tr(),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Nombre de la misión',
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
              
              // Descripción
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descripción (opcional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              
              // Categoría
              Text('Categoría',
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
                      // Actualizar puntos según categoría si no fueron modificados manualmente
                      if (_selectedPoints == widget.initialCategory.points) {
                        _selectedPoints = value.points;
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Puntos
              Text('Puntos',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: [
                  ButtonSegment(
                    value: 1,
                    label: const Text('1'),
                    icon: const Icon(Icons.star_border),
                  ),
                  ButtonSegment(
                    value: 2,
                    label: const Text('2'),
                    icon: const Icon(Icons.star_half),
                  ),
                  ButtonSegment(
                    value: 3,
                    label: const Text('3'),
                    icon: const Icon(Icons.star),
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
              
              // Imagen
              Text('Imagen',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _selectedImageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _selectedImageBytes!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : _existingImageUrl != null && _existingImageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _existingImageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Error al cargar imagen',
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
                                    'Seleccionar imagen',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading 
              ? null 
              : () => Navigator.of(context).pop(),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveTask,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text('Guardar'),
        ),
      ],
    );
  }
}
