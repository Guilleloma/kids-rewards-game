import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/reward_model.dart';
import '../../providers/rewards_provider.dart';

class RewardManagerScreen extends ConsumerStatefulWidget {
  final String userId;
  
  const RewardManagerScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<RewardManagerScreen> createState() => _RewardManagerScreenState();
}

class _RewardManagerScreenState extends ConsumerState<RewardManagerScreen> {
  RewardType _selectedFilter = RewardType.normal;
  
  @override
  Widget build(BuildContext context) {
    final rewardsAsync = ref.watch(rewardsProvider(widget.userId));
    
    return Scaffold(
      body: Column(
        children: [
          // Filtros de tipo
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildFilterChip(
                    RewardType.normal,
                    'rewards.myRewards'.tr(),
                    Icons.card_giftcard,
                    Colors.purple,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    RewardType.premium,
                    'rewards.superRewards'.tr(),
                    Icons.workspace_premium,
                    Colors.amber,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    RewardType.coin,
                    'Monedas',
                    Icons.monetization_on,
                    Colors.green,
                  ),
                ],
              ),
            ),
          ),
          
          // Lista de recompensas
          Expanded(
            child: rewardsAsync.when(
              data: (rewards) {
                final filteredRewards = rewards
                    .where((reward) => reward.type == _selectedFilter)
                    .toList();
                
                if (filteredRewards.isEmpty) {
                  return Center(
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
                          'No hay premios en esta categoría',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredRewards.length,
                  itemBuilder: (context, index) {
                    final reward = filteredRewards[index];
                    return _buildRewardCard(reward);
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
          _showAddEditRewardDialog();
        },
        child: const Icon(Icons.add),
        tooltip: 'rewards.addReward'.tr(),
      ),
    );
  }
  
  Widget _buildFilterChip(
    RewardType type,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedFilter == type;
    
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
          _selectedFilter = type;
        });
      },
    );
  }
  
  Widget _buildRewardCard(RewardModel reward) {
    final color = _getRewardColor(reward.type);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: reward.active ? Colors.transparent : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen de la recompensa (si tiene)
          if (reward.imageUrl != null && reward.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                width: double.infinity,
                height: 120,
                child: Image.network(
                  reward.imageUrl!,
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
          
          // Contenido de la recompensa
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Coste
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.star, color: color, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${reward.cost}',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Título y descripción
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reward.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: reward.active 
                                  ? Colors.black87
                                  : Colors.grey.shade500,
                            ),
                          ),
                          if (reward.description != null && reward.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                reward.description!,
                                style: TextStyle(
                                  color: reward.active 
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
                
                // Tipo y acciones
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tipo de recompensa
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
                            _getRewardIcon(reward.type),
                            size: 16,
                            color: color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getRewardTypeName(reward.type),
                            style: TextStyle(
                              fontSize: 12,
                              color: color,
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
                            reward.active 
                                ? Icons.visibility 
                                : Icons.visibility_off,
                            color: reward.active
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          onPressed: () {
                            _toggleRewardActive(reward);
                          },
                          tooltip: reward.active
                              ? 'Desactivar'
                              : 'Activar',
                        ),
                        // Editar
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.amber),
                          onPressed: () {
                            _showAddEditRewardDialog(reward: reward);
                          },
                          tooltip: 'rewards.editReward'.tr(),
                        ),
                        // Eliminar
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _showDeleteRewardConfirmation(reward);
                          },
                          tooltip: 'rewards.deleteReward'.tr(),
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
  
  Future<void> _toggleRewardActive(RewardModel reward) async {
    try {
      await ref.read(rewardsNotifierProvider.notifier).updateReward(
        userId: widget.userId,
        rewardId: reward.id,
        active: !reward.active,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reward.active
                ? 'Premio desactivado'
                : 'Premio activado',
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
  
  void _showAddEditRewardDialog({RewardModel? reward}) {
    showDialog(
      context: context,
      builder: (context) => RewardFormDialog(
        userId: widget.userId,
        reward: reward,
        initialType: reward?.type ?? _selectedFilter,
      ),
    );
  }
  
  void _showDeleteRewardConfirmation(RewardModel reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('rewards.deleteReward'.tr()),
        content: Text('¿Estás seguro de que quieres eliminar el premio "${reward.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              try {
                await ref.read(rewardsNotifierProvider.notifier).deleteReward(
                  userId: widget.userId,
                  reward: reward,
                );
                
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('rewards.rewardDeleted'.tr())),
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
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }
  
  Color _getRewardColor(RewardType type) {
    switch (type) {
      case RewardType.normal:
        return Colors.blue;
      case RewardType.premium:
        return Colors.amber;
      case RewardType.coin:
        return Colors.green;
      default:
        return Colors.blue; // Valor por defecto
    }
  }
  
  IconData _getRewardIcon(RewardType type) {
    switch (type) {
      case RewardType.normal:
        return Icons.card_giftcard;
      case RewardType.premium:
        return Icons.workspace_premium;
      case RewardType.coin:
        return Icons.monetization_on;
      default:
        return Icons.card_giftcard; // Valor por defecto
    }
  }
  
  String _getRewardTypeName(RewardType type) {
    switch (type) {
      case RewardType.normal:
        return 'rewards.myRewards'.tr();
      case RewardType.premium:
        return 'rewards.superRewards'.tr();
      case RewardType.coin:
        return 'Monedas';
      default:
        return 'rewards.myRewards'.tr(); // Valor por defecto
    }
  }
}

class RewardFormDialog extends ConsumerStatefulWidget {
  final String userId;
  final RewardModel? reward;
  final RewardType initialType;
  
  const RewardFormDialog({
    Key? key,
    required this.userId,
    this.reward,
    required this.initialType,
  }) : super(key: key);

  @override
  ConsumerState<RewardFormDialog> createState() => _RewardFormDialogState();
}

class _RewardFormDialogState extends ConsumerState<RewardFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  late RewardType _selectedType;
  late int _selectedCost;
  File? _selectedImage;
  String? _existingImageUrl;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar con datos de la recompensa si existe
    if (widget.reward != null) {
      _titleController.text = widget.reward!.title;
      _descriptionController.text = widget.reward!.description ?? '';
      _selectedType = widget.reward!.type;
      _selectedCost = widget.reward!.cost;
      _existingImageUrl = widget.reward!.imageUrl;
    } else {
      _selectedType = widget.initialType;
      _selectedCost = widget.initialType == RewardType.normal ? 60 : widget.initialType == RewardType.premium ? 70 : 30;
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
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }
  
  Future<void> _saveReward() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (widget.reward == null) {
        // Crear nueva recompensa
        await ref.read(rewardsNotifierProvider.notifier).addReward(
          userId: widget.userId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          type: _selectedType,
          cost: _selectedCost,
          image: _selectedImage,
        );
      } else {
        // Actualizar recompensa existente
        await ref.read(rewardsNotifierProvider.notifier).updateReward(
          userId: widget.userId,
          rewardId: widget.reward!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          type: _selectedType,
          cost: _selectedCost,
          newImage: _selectedImage,
        );
      }
      
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.reward == null
                ? 'rewards.rewardAdded'.tr()
                : 'rewards.rewardUpdated'.tr(),
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
  
  @override
  Widget build(BuildContext context) {
    final color = _selectedType == RewardType.normal ? Colors.purple : _selectedType == RewardType.premium ? Colors.amber : Colors.green;
    
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.reward == null
                ? 'rewards.addReward'.tr()
                : 'rewards.editReward'.tr(),
          ),
          // Indicador visual de puntos (reemplaza al $ de moneda)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: color,
                ),
                const SizedBox(width: 2),
                Text(
                  '$_selectedCost',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                  labelText: 'rewards.rewardName'.tr(),
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
                  labelText: 'rewards.description'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              
              // Tipo
              Text('rewards.type'.tr(),
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<RewardType>(
                segments: [
                  ButtonSegment(
                    value: RewardType.normal,
                    label: Text('rewards.myRewards'.tr()),
                    icon: const Icon(Icons.card_giftcard),
                  ),
                  ButtonSegment(
                    value: RewardType.premium,
                    label: Text('rewards.superRewards'.tr()),
                    icon: const Icon(Icons.workspace_premium),
                  ),
                  ButtonSegment(
                    value: RewardType.coin,
                    label: Text('Monedas'),
                    icon: const Icon(Icons.monetization_on),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                    
                    // Ajustar coste sugerido según tipo
                    if (_selectedType == RewardType.normal && _selectedCost < 60) {
                      _selectedCost = 60;
                    } else if (_selectedType == RewardType.premium && _selectedCost < 70) {
                      _selectedCost = 70;
                    } else if (_selectedType == RewardType.coin && _selectedCost < 30) {
                      _selectedCost = 30;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Coste
              Text(
                'rewards.cost'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_selectedCost',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Slider(
                value: _selectedCost.toDouble(),
                min: 30,
                max: 100,
                divisions: 7,
                label: _selectedCost.toString(),
                activeColor: color,
                onChanged: (value) {
                  setState(() {
                    _selectedCost = value.toInt();
                  });
                },
              ),
              Text(
                '$_selectedCost puntos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              
              // Imagen
              Text('rewards.image'.tr(),
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
                  child: _selectedImage != null
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
                                    'rewards.selectImage'.tr(),
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
          child: Text('common.cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveReward,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Theme.of(context).primaryColor,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text('common.save'.tr()),
        ),
      ],
    );
  }
}
