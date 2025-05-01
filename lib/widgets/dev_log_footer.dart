import 'package:flutter/material.dart';
import '../utils/dev_logger.dart';

class DevLogFooter extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const DevLogFooter({
    Key? key, 
    required this.child,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<DevLogFooter> createState() => _DevLogFooterState();
}

class _DevLogFooterState extends State<DevLogFooter> {
  bool _expanded = false;
  late List<LogEntry> _logs;

  @override
  void initState() {
    super.initState();
    _logs = devLogger.logs;
    // Escuchar cambios en los logs
    devLogger.addListener(_updateLogs);
  }

  @override
  void dispose() {
    devLogger.removeListener(_updateLogs);
    super.dispose();
  }

  void _updateLogs() {
    setState(() {
      _logs = devLogger.logs;
    });
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
    // Si no está habilitado, solo devuelve el child sin el footer
    if (!widget.enabled) {
      return widget.child;
    }

    return Column(
      children: [
        // El contenido principal de la pantalla
        Expanded(child: widget.child),
        
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
                  child: Row(
                    children: [
                      const Text(
                        'Logs',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white, size: 16),
                        onPressed: () {
                          // Copiar todos los logs al portapapeles
                          final String text = _logs.map((e) => e.toString()).join('\n');
                          // Implementar copia al portapapeles
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 30,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white, size: 16),
                        onPressed: () {
                          devLogger.clear();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 30,
                        ),
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
    );
  }
}
