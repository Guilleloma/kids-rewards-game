import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import '../onboarding/login_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _childNameController = TextEditingController();
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _childNameController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    final user = await ref.read(currentUserProvider.future);
    
    if (user != null) {
      setState(() {
        _nameController.text = user.name;
        _childNameController.text = user.childName;
      });
    }
  }
  
  Future<void> _updateProfile() async {
    final userId = ref.read(userIdProvider);
    if (userId == null) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      await ref.read(authNotifierProvider.notifier).updateProfile(
        userId: userId,
        name: _nameController.text.trim(),
        childName: _childNameController.text.trim(),
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Perfil actualizado correctamente!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  Future<void> _signOut() async {
    try {
      await ref.read(authNotifierProvider.notifier).signOut();
      
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('dashboard.settings'.tr()),
      ),
      body: user.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('No hay usuario'),
            );
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sección de perfil
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Perfil',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        
                        // Email (no editable)
                        TextFormField(
                          initialValue: user.email,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'auth.email'.tr(),
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Nombre del padre/madre
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'auth.name'.tr(),
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Nombre del niño/a
                        TextFormField(
                          controller: _childNameController,
                          decoration: InputDecoration(
                            labelText: 'auth.childName'.tr(),
                            prefixIcon: const Icon(Icons.child_care),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Botón de guardar
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _updateProfile,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: _isSaving
                                ? const CircularProgressIndicator()
                                : Text('common.save'.tr()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Sección de información
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Información',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        
                        // Fecha de creación
                        ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: const Text('Cuenta creada el'),
                          subtitle: Text(
                            DateFormat('dd/MM/yyyy').format(user.createdAt),
                          ),
                        ),
                        
                        const Divider(),
                        
                        // Acerca de
                        const ListTile(
                          leading: Icon(Icons.info),
                          title: Text('Acerca de la aplicación'),
                          subtitle: Text(
                            'Juego de recompensas infantil para fomentar hábitos y autoestima',
                          ),
                        ),
                        
                        const Divider(),
                        
                        // Cerrar sesión
                        ListTile(
                          leading: const Icon(Icons.exit_to_app, color: Colors.red),
                          title: const Text('Cerrar sesión'),
                          subtitle: const Text('Desconectarse de la aplicación'),
                          onTap: _signOut,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Ayuda
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ayuda',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        
                        // Tips para usar mejor la app
                        ExpansionTile(
                          title: const Text('¿Cómo aprovechar al máximo la app?'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildTip(
                                    icon: Icons.tips_and_updates,
                                    title: 'Constancia',
                                    description: 'Revisa las misiones con tu hijo/a todos los días.',
                                  ),
                                  _buildTip(
                                    icon: Icons.photo_camera,
                                    title: 'Personaliza',
                                    description: 'Usa fotos reales del niño realizando la actividad.',
                                  ),
                                  _buildTip(
                                    icon: Icons.balance,
                                    title: 'Equilibrio',
                                    description: 'Combina diferentes tipos de misiones.',
                                  ),
                                  _buildTip(
                                    icon: Icons.celebration,
                                    title: 'Celebra',
                                    description: 'Festeja siempre cada logro, por pequeño que sea.',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        // Preguntas frecuentes
                        ExpansionTile(
                          title: const Text('Preguntas frecuentes'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFAQ(
                                    question: '¿Cómo se reinicia la semana?',
                                    answer: 'La semana se reinicia automáticamente cada lunes, o puedes hacerlo manualmente desde el menú del dashboard principal.',
                                  ),
                                  _buildFAQ(
                                    question: '¿Puedo editar los puntos de una misión?',
                                    answer: 'Sí, puedes modificar los puntos al editar cualquier misión, independientemente de su categoría.',
                                  ),
                                  _buildFAQ(
                                    question: '¿Qué pasa con las monedas sin gastar?',
                                    answer: 'Las monedas no gastadas se pierden al reiniciarse la semana. Puedes animar a tu hijo a usarlas antes.',
                                  ),
                                ],
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
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
  
  Widget _buildTip({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFAQ({
    required String question,
    required String answer,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(answer),
          const Divider(height: 24),
        ],
      ),
    );
  }
}
