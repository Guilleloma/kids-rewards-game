import 'dart:collection';

// Singleton para gestionar los logs de desarrollo
class DevLogger {
  // Instancia singleton
  static final DevLogger _instance = DevLogger._internal();
  
  factory DevLogger() => _instance;
  
  DevLogger._internal();
  
  // Cola de mensajes con un máximo de entradas para no saturar la memoria
  final Queue<LogEntry> _logs = Queue<LogEntry>();
  final int _maxLogs = 100;
  
  // Listeners para notificar cambios en los logs
  final List<Function()> _listeners = [];
  
  // Método para agregar un mensaje de log
  void log(String message, {LogLevel level = LogLevel.info}) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      message: message,
      level: level,
    );
    
    _logs.add(entry);
    
    // Mantener la cola por debajo del límite
    if (_logs.length > _maxLogs) {
      _logs.removeFirst();
    }
    
    // Notificar a los listeners
    _notifyListeners();
    
    // Imprimir en consola para desarrollo
    final formattedTimestamp = '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}';
    print('[$formattedTimestamp] [${level.toString().split('.').last.toUpperCase()}] $message');
  }
  
  // Método de conveniencia para debug
  void debug(String message) {
    log(message, level: LogLevel.debug);
  }
  
  // Método de conveniencia para info
  void info(String message) {
    log(message, level: LogLevel.info);
  }
  
  // Método de conveniencia para warning
  void warning(String message) {
    log(message, level: LogLevel.warning);
  }
  
  // Método de conveniencia para error
  void error(String message) {
    log(message, level: LogLevel.error);
  }
  
  // Método para limpiar los logs
  void clear() {
    _logs.clear();
    _notifyListeners();
  }
  
  // Obtener todos los logs
  List<LogEntry> get logs => List.unmodifiable(_logs);
  
  // Añadir listener
  void addListener(Function() listener) {
    _listeners.add(listener);
  }
  
  // Eliminar listener
  void removeListener(Function() listener) {
    _listeners.remove(listener);
  }
  
  // Notificar a todos los listeners
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }
}

// Niveles de log
enum LogLevel {
  verbose,  // Información detallada
  debug,    // Información para depuración
  info,     // Información general
  warning,  // Advertencias
  error,    // Errores
  wtf       // Errores graves/catastróficos
}

// Estructura de una entrada de log
class LogEntry {
  final DateTime timestamp;
  final String message;
  final LogLevel level;
  
  LogEntry({
    required this.timestamp,
    required this.message,
    required this.level,
  });
  
  @override
  String toString() {
    final levelString = level.toString().split('.').last.toUpperCase();
    return '${timestamp.toIso8601String()} [$levelString] $message';
  }
}

// Acceso global al logger
final devLogger = DevLogger();
