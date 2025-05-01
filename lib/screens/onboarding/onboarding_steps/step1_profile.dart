import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../providers/auth_provider.dart';

class Step1Profile extends ConsumerStatefulWidget {
  final String childName;
  
  const Step1Profile({Key? key, required this.childName}) : super(key: key);

  @override
  ConsumerState<Step1Profile> createState() => _Step1ProfileState();
}

class _Step1ProfileState extends ConsumerState<Step1Profile> {
  late final TextEditingController _childNameController;
  
  @override
  void initState() {
    super.initState();
    _childNameController = TextEditingController(text: widget.childName);
  }
  
  @override
  void dispose() {
    _childNameController.dispose();
    super.dispose();
  }
  
  Future<void> _updateProfile() async {
    final userId = ref.read(userIdProvider);
    if (userId == null) return;
    
    final newChildName = _childNameController.text.trim();
    if (newChildName.isEmpty || newChildName == widget.childName) return;
    
    try {
      await ref.read(authNotifierProvider.notifier).updateProfile(
        userId: userId,
        childName: newChildName,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡Perfil actualizado!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Título
          Text(
            'onboarding.step1Title'.tr(),
            style: Theme.of(context).textTheme.headline5,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Descripción
          Text(
            'onboarding.step1Description'.tr(),
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          
          // Imagen o ilustración
          CircleAvatar(
            radius: 60,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            child: Icon(
              Icons.child_care,
              size: 60,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 48),
          
          // Campo para editar el nombre del niño
          TextFormField(
            controller: _childNameController,
            decoration: InputDecoration(
              labelText: 'auth.childName'.tr(),
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.check),
                onPressed: _updateProfile,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Texto explicativo
          Text(
            'Durante el juego, las misiones serán presentadas a ${widget.childName} de forma divertida y motivadora. Puedes actualizar su nombre en cualquier momento.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
