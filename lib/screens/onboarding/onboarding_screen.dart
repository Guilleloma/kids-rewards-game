import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import 'onboarding_steps/step1_profile.dart';
import 'onboarding_steps/step2_tasks.dart';
import 'onboarding_steps/step3_rewards.dart';
import 'onboarding_steps/step4_finished.dart';
import '../parent/parent_dashboard.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Última página, ir al dashboard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ParentDashboard()),
      );
    }
  }
  
  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  void _skipToEnd() {
    // Ir directamente al dashboard
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ParentDashboard()),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    
    return Scaffold(
      body: userAsync.when(
        data: (user) {
          final childName = user?.childName ?? '';
          
          return SafeArea(
            child: Column(
              children: [
                // Indicador de progreso
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: LinearProgressIndicator(
                    value: (_currentPage + 1) / _totalPages,
                    backgroundColor: Colors.grey[300],
                    color: Theme.of(context).colorScheme.primary,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                
                // Contenido principal
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    children: [
                      Step1Profile(childName: childName),
                      const Step2Tasks(),
                      const Step3Rewards(),
                      Step4Finished(childName: childName),
                    ],
                  ),
                ),
                
                // Botones de navegación
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botón atrás
                      _currentPage > 0
                          ? TextButton(
                              onPressed: _previousPage,
                              child: Text('onboarding.back'.tr()),
                            )
                          : const SizedBox(width: 80),
                      
                      // Botón saltar (solo en las primeras páginas)
                      _currentPage < _totalPages - 1
                          ? TextButton(
                              onPressed: _skipToEnd,
                              child: Text('onboarding.skip'.tr()),
                            )
                          : const SizedBox(),
                      
                      // Botón siguiente/finalizar
                      ElevatedButton(
                        onPressed: _nextPage,
                        child: Text(
                          _currentPage < _totalPages - 1
                              ? 'onboarding.next'.tr()
                              : 'onboarding.done'.tr(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
