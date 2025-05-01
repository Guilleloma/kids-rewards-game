import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/dev_logger.dart';

class DevLogOverlay extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const DevLogOverlay({
    Key? key, 
    required this.child,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<DevLogOverlay> createState() => _DevLogOverlayState();
}

class _DevLogOverlayState extends State<DevLogOverlay> {
  bool _expanded = false;
  late List<LogEntry> _logs;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _logs = List.from(devLogger.logs); // Crear una copia para evitar referencias directas
    // Escuchar cambios en los logs
    devLogger.addListener(_updateLogs);
  }

  @override
  void dispose() {
    devLogger.removeListener(_updateLogs);
    super.dispose();
  }

  void _updateLogs() {
    // Prevenir llamadas a setState durante la construcción
    if (mounted && !_isUpdating) {
      _isUpdating = true;
      // Usar Future.microtask para asegurar que la actualización ocurra después de la construcción
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _logs = List.from(devLogger.logs);
            _isUpdating = false;
          });
        }
      });
    }
  }

  // Copiar logs al portapapeles
  Future<void> _copyLogs() async {
    if (_logs.isEmpty) return;

    final buffer = StringBuffer();
    for (var log in _logs) {
      final timestamp = '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}';
      final level = log.level.toString().split('.').last.toUpperCase();
      buffer.writeln('[$timestamp] [$level] ${log.message}');
    }
    
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    
    // Mostrar confirmación
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logs copiados al portapapeles'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Obtener color según el nivel de log
  Color _getLogColor(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        return Colors.grey;
      case LogLevel.debug:
        return Colors.blue;
      case LogLevel.info:
        return Colors.green;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.wtf:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si no está habilitado, solo devuelve el child sin overlay
    if (!widget.enabled) {
      return widget.child;
    }

    // Usar Stack en lugar de Scaffold para evitar conflictos
    return Stack(
      children: [
        // Contenido principal
        widget.child,
        
        // Footer de logs en la parte inferior
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Footer de desarrollo
              GestureDetector(
                onTap: () {
                  setState(() {
                    _expanded = !_expanded;
                  });
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    border: Border(top: BorderSide(color: Colors.grey[800]!)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Row(
                    children: [
                      Icon(
                        _expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'DEVELOPER LOGS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // Último log como resumen
                      if (_logs.isNotEmpty)
                        Expanded(
                          child: Text(
                            _logs.last.message,
                            style: TextStyle(
                              color: _getLogColor(_logs.last.level),
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(width: 8),
                      // Número de logs
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${_logs.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Panel expandido con los logs
              if (_expanded)
                Container(
                  height: MediaQuery.of(context).size.height * 0.3,
                  width: double.infinity,
                  color: Colors.grey[900],
                  child: Column(
                    children: [
                      // Barra de herramientas
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[800]!),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Filtros (para implementación futura)
                            const Text(
                              'Filtrar:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                            const Spacer(),
                            // Botón de copiar
                            MaterialButton(
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.copy,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Copiar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              onPressed: _copyLogs,
                              padding: EdgeInsets.zero,
                              minWidth: 0,
                              height: 30,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            const SizedBox(width: 8),
                            // Botón de limpiar
                            MaterialButton(
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.delete_outline,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Limpiar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              onPressed: () {
                                setState(() {
                                  devLogger.clear();
                                  _logs = [];
                                });
                              },
                              padding: EdgeInsets.zero,
                              minWidth: 0,
                              height: 30,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                      ),
                      
                      // Lista de logs
                      Expanded(
                        child: _logs.isEmpty
                            ? const Center(
                                child: Text(
                                  'No hay logs registrados',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _logs.length,
                                reverse: true,
                                itemBuilder: (context, index) {
                                  final log = _logs[_logs.length - 1 - index];
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(color: Colors.grey[800]!),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Timestamp
                                        Text(
                                          '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 10,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Nivel de log
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getLogColor(log.level),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            log.level.toString().split('.').last.toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Mensaje
                                        Expanded(
                                          child: Text(
                                            log.message,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
