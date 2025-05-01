import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/reward_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/rewards_provider.dart';

class Step3Rewards extends ConsumerStatefulWidget {
  const Step3Rewards({Key? key}) : super(key: key);

  @override
  ConsumerState<Step3Rewards> createState() => _Step3RewardsState();
}

class _Step3RewardsState extends ConsumerState<Step3Rewards> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  RewardType _selectedType = RewardType.normal;
  int _selectedCost = 60;
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
      _selectedType = RewardType.normal;
      _selectedCost = 60;
      _selectedImage = null;
    });
  }
  
  Future<void> _createReward() async {
    if (!_formKey.currentState!.validate()) return;
    
    final userId = ref.read(userIdProvider);
    if (userId == null) return;
    
    setState(() {
      _isCreating = true;
    });
    
    try {
      await ref.read(rewardsNotifierProvider.notifier).addReward(
        userId: userId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        cost: _selectedCost,
        image: _selectedImage,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('rewards.rewardAdded'.tr())),
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
    final rewardsAsync = userId != null ? ref.watch(rewardsProvider(userId)) : const AsyncValue.loading();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // Título
          Text(
            'onboarding.step3Title'.tr(),
            style: Theme.of(context).textTheme.headline5,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Descripción
          Text(
            'onboarding.step3Description'.tr(),
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Formulario para crear recompensa
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
                            // Título de la recompensa
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
                            
                            // Descripción (opcional)
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
                            
                            // Selección de tipo
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
                              ],
                              selected: {_selectedType},
                              onSelectionChanged: (newSelection) {
                                setState(() {
                                  _selectedType = newSelection.first;
                                  // Actualizar coste según tipo
                                  _selectedCost = _selectedType == RewardType.normal ? 60 : 70;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Selección de coste
                            Text('rewards.cost'.tr(),
                                style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            Slider(
                              value: _selectedCost.toDouble(),
                              min: 30,
                              max: 100,
                              divisions: 7,
                              label: _selectedCost.toString(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCost = value.toInt();
                                });
                              },
                            ),
                            Text(
                              '${_selectedCost} puntos - ${(_selectedCost / 30).floor()} monedas',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Selección de imagen
                            Text('rewards.image'.tr(),
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
                            const SizedBox(height: 24),
                            
                            // Botón para crear recompensa
                            ElevatedButton(
                              onPressed: _isCreating ? null : _createReward,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                              ),
                              child: _isCreating
                                  ? const CircularProgressIndicator()
                                  : Text('rewards.addReward'.tr()),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Lista de recompensas creadas
                    rewardsAsync.when(
                      data: (rewards) {
                        if (rewards.isEmpty) {
                          return Center(
                            child: Text(
                              'Aún no has creado ningún premio',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          );
                        }
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Premios creados (${rewards.length}):',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            for (final reward in rewards)
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getRewardColor(reward.type),
                                  child: reward.type == RewardType.normal
                                      ? const Icon(Icons.card_giftcard, color: Colors.white)
                                      : const Icon(Icons.workspace_premium, color: Colors.white),
                                ),
                                title: Text(reward.title),
                                subtitle: Text(
                                  '${reward.cost} puntos - ${(reward.cost / 30).floor()} monedas',
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getRewardColor(reward.type).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    reward.type == RewardType.normal
                                        ? 'rewards.myRewards'.tr()
                                        : 'rewards.superRewards'.tr(),
                                    style: TextStyle(
                                      color: _getRewardColor(reward.type),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
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
  
  Color _getRewardColor(RewardType type) {
    switch (type) {
      case RewardType.normal:
        return Colors.purple;
      case RewardType.premium:
        return Colors.amber;
    }
  }
}
