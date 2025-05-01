import 'package:flutter/material.dart';
import '../widgets/dev_log_overlay.dart';

class DevLogNavigator {
  // Navegación con Overlay para desarrollo
  static Route<dynamic> generateRoute(RouteSettings settings, {bool isDevelopment = true}) {
    // Extraer el builder de la ruta original
    final Route<dynamic> originalRoute = MaterialPageRoute(
      settings: settings,
      builder: (context) => _getScreenForRoute(settings),
    );
    
    if (!isDevelopment) {
      return originalRoute;
    }
    
    // Envolver la pantalla original con nuestro overlay
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => DevLogOverlay(
        enabled: true,
        child: _getScreenForRoute(settings),
      ),
    );
  }
  
  // Navigator 2.0 - Para uso con Router
  static Widget wrapWithDevLogOverlay(Widget screen, {bool isDevelopment = true}) {
    if (!isDevelopment) {
      return screen;
    }
    
    return DevLogOverlay(
      enabled: true,
      child: screen,
    );
  }
  
  // Método para obtener la pantalla correspondiente a la ruta
  static Widget _getScreenForRoute(RouteSettings settings) {
    // Este método se utiliza como ejemplo, pero normalmente
    // se reemplazaría por el router real de la aplicación
    switch (settings.name) {
      // Definir rutas específicas aquí
      default:
        // En caso de rutas desconocidas, devolver un error
        return Scaffold(
          body: Center(
            child: Text('Ruta no encontrada: ${settings.name}'),
          ),
        );
    }
  }
}

// Extensión para Navigator para facilitar la navegación con logs
extension DevLogNavigatorExtension on NavigatorState {
  Future<T?> pushDevLogRoute<T extends Object?>(
    String routeName, {
    Object? arguments,
    bool isDevelopment = true,
  }) {
    return this.push<T>(
      DevLogNavigator.generateRoute(
        RouteSettings(name: routeName, arguments: arguments),
        isDevelopment: isDevelopment,
      ),
    );
  }
}
