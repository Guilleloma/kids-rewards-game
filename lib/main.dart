import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'screens/onboarding/login_screen.dart';
import 'screens/onboarding/register_screen.dart';
import 'screens/parent/parent_dashboard.dart';
import 'providers/auth_provider.dart';
import 'utils/dev_logger.dart';
import 'widgets/dev_log_overlay.dart';

// App principal
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicialización de paquetes
  await EasyLocalization.ensureInitialized();
  
  // Cargar variables de entorno - ASEGURARSE DE QUE ESTO SE COMPLETE
  try {
    await dotenv.load(fileName: ".env");
    
    // Verificar que las variables se cargaron correctamente
    final apiKey = dotenv.env['FIREBASE_API_KEY'];
    devLogger.log("Variables de entorno cargadas correctamente", level: LogLevel.info);
    
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("FIREBASE_API_KEY no está definida en el archivo .env");
    }
    
    // Mostrar las claves para depuración (sólo primeros caracteres por seguridad)
    devLogger.log("FIREBASE_API_KEY: ${apiKey.substring(0, 5)}...", level: LogLevel.debug);
    devLogger.log("FIREBASE_PROJECT_ID: ${dotenv.env['FIREBASE_PROJECT_ID']}", level: LogLevel.debug);
    devLogger.log("FIREBASE_AUTH_DOMAIN: ${dotenv.env['FIREBASE_AUTH_DOMAIN']}", level: LogLevel.debug);
  } catch (e) {
    devLogger.log("Error al cargar variables de entorno: $e", level: LogLevel.error);
  }
  
  // Inicializar Firebase DESPUÉS de cargar variables
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform, 
    );
    devLogger.log('Firebase inicializado correctamente', level: LogLevel.info);
  } catch (e) {
    devLogger.log('Error al inicializar Firebase: $e', level: LogLevel.error);
  }
  
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('es'), Locale('en')],
      path: 'assets/l10n',
      fallbackLocale: const Locale('es'),
      child: const ProviderScope(
        child: KidsRewardsApp(),
      ),
    ),
  );
}

class KidsRewardsApp extends StatelessWidget {
  const KidsRewardsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determinar si estamos en modo desarrollo
    const bool isDevelopment = true; // Cambiar a false para producción
    
    return MaterialApp(
      title: 'Kids Rewards Game',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFFFF9800),
          tertiary: const Color(0xFF2196F3),
          background: const Color(0xFFF5F5F5),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Color(0xFF333333),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4CAF50),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32), // Verde más oscuro para mejor contraste
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            foregroundColor: Colors.white,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF2E7D32), // Verde más oscuro para mejor contraste
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      builder: (context, child) {
        // Este builder se ejecuta para cada pantalla de la aplicación
        return DevLogOverlay(
          enabled: isDevelopment,
          child: child ?? const SizedBox(),
        );
      },
      home: const AuthWrapper(),
    );
  }
}

// Widget que determina qué pantalla mostrar según el estado de autenticación
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    return authState.when(
      data: (user) {
        if (user != null) {
          // Usuario autenticado -> mostrar dashboard
          return const ParentDashboard();
        } else {
          // Usuario no autenticado -> mostrar login
          return const LoginScreen();
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
