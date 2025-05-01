import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:js' as js;
import 'package:kids_rewards_game/utils/dev_logger.dart';

/// Clase para manejar problemas CORS en Firebase Storage
class CorsProxy {
  static final DevLogger _logger = DevLogger();
  
  /// Método para procesar URLs de Firebase Storage con JavaScript
  /// Esta solución es específica para web y utiliza el puente JS que añadimos en index.html
  static String processUrlWithJs(String imageUrl) {
    if (!kIsWeb) return imageUrl; // Solo necesario en web
    
    try {
      // Llamar a la función JavaScript que arregla la URL
      return js.context.callMethod('fixFirebaseStorageUrl', [imageUrl]) as String;
    } catch (e) {
      _logger.error('Error al procesar URL con JS: $e');
      return imageUrl; // Devolver la URL original en caso de error
    }
  }
  
  /// Proxy para cargar imágenes y evitar problemas CORS en Web
  /// Retorna bytes de la imagen para poder usar Image.memory()
  /// Esta solución usa solicitudes HTTP directas, pero puede encontrarse con problemas CORS
  static Future<Uint8List?> proxyFirebaseImage(String imageUrl) async {
    if (!kIsWeb) {
      // Solo necesario en Web
      _logger.debug('CorsProxy: Running on mobile, not needed');
      return null;
    }
    
    try {
      _logger.debug('CorsProxy: Intentando cargar imagen: $imageUrl');
      
      // Arreglar la URL usando JavaScript para evitar problemas CORS
      // Este enfoque tiene más probabilidades de éxito que las llamadas HTTP directas
      final processedUrl = processUrlWithJs(imageUrl);
      
      if (imageUrl != processedUrl) {
        _logger.debug('CorsProxy: URL procesada con JS: $processedUrl');
      }
      
      // Intentar cargar con solicitud HTTP directa
      final response = await http.get(
        Uri.parse(processedUrl),
        headers: {
          'Accept': 'image/*',
          'Access-Control-Allow-Origin': '*',
          'Cache-Control': 'no-cache, no-store',
        },
      );
      
      if (response.statusCode == 200) {
        _logger.debug('CorsProxy: Imagen cargada correctamente (${response.contentLength} bytes)');
        return response.bodyBytes;
      } else {
        _logger.error('CorsProxy: Error cargando imagen - HTTP ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.error('CorsProxy: Error en proxy de imagen: $e');
      return null;
    }
  }
}
