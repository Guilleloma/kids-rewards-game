import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:kids_rewards_game/utils/dev_logger.dart';
import 'package:kids_rewards_game/utils/cors_proxy.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  
  // Método de utilidad para prevenir problemas CORS con Firebase Storage
  String fixFirebaseStorageUrl(String url) {
    // Verificar si es una URL de Firebase Storage
    if (url.contains('firebasestorage.googleapis.com')) {
      if (kIsWeb) {
        try {
          // En web, usar la función JavaScript para evitar problemas CORS
          return CorsProxy.processUrlWithJs(url);
        } catch (e) {
          // Si falla, usar el enfoque de timestamp directo
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          if (url.contains('?')) {
            return '$url&nocache=$timestamp';
          } else {
            return '$url?nocache=$timestamp';
          }
        }
      } else {
        // En móvil, es suficiente con un timestamp
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        if (url.contains('?')) {
          return '$url&nocache=$timestamp';
        } else {
          return '$url?nocache=$timestamp';
        }
      }
    }
    return url;
  }
  
  // Subir una imagen al Storage
  Future<String?> uploadImage({
    required String userId,
    required File imageFile,
    required String path,
    String? fileName,
  }) async {
    try {
      // Crear nombre de archivo único si no se proporciona uno
      final name = fileName ?? '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'users/$userId/$path/$name';
      
      // Crear referencia al archivo en Storage
      final ref = _storage.ref().child(storagePath);
      
      // Subir la imagen
      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      // Obtener URL de descarga
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error al subir imagen: $e');
      return null;
    }
  }
  
  // Método para subir bytes de imagen para plataforma web
  Future<String?> uploadImageBytes({
    required String userId,
    required Uint8List imageBytes,
    required String path,
    String? fileName,
  }) async {
    try {
      devLogger.debug('Iniciando uploadImageBytes para usuario: $userId, path: $path');
      devLogger.debug('Tamaño de la imagen en bytes: ${imageBytes.length}');
      
      // Crear nombre de archivo único si no se proporciona uno
      final name = fileName ?? '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'users/$userId/$path/$name';
      devLogger.debug('Ruta de almacenamiento: $storagePath');
      
      // Crear referencia al archivo en Storage
      final ref = _storage.ref().child(storagePath);
      
      // Subir la imagen como bytes
      devLogger.debug('Iniciando subida de bytes al Storage');
      final uploadTask = await ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      devLogger.debug('Subida completada, obteniendo URL');
      
      // Obtener URL de descarga
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      devLogger.debug('URL de descarga obtenida: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      devLogger.error('Error al subir imagen como bytes: $e');
      if (e is FirebaseException) {
        devLogger.error('Código: ${e.code}, Mensaje: ${e.message}');
        devLogger.error('Stack trace: ${e.stackTrace}');
      }
      return null;
    }
  }
  
  // Seleccionar una imagen de la galería
  Future<File?> pickImageFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1000,
        maxHeight: 1000,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('Error al seleccionar imagen: $e');
      return null;
    }
  }
  
  // Tomar una foto con la cámara
  Future<File?> takePhoto() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1000,
        maxHeight: 1000,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('Error al tomar foto: $e');
      return null;
    }
  }
  
  // Subir imagen para una tarea
  Future<String?> uploadTaskImage({
    required String userId,
    required File imageFile,
    String? fileName,
  }) async {
    final taskFileName = fileName ?? 'task_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return uploadImage(
      userId: userId,
      imageFile: imageFile,
      path: 'tasks',
      fileName: taskFileName,
    );
  }
  
  // Subir bytes de imagen para una tarea (para web)
  Future<String?> uploadTaskImageBytes({
    required String userId,
    required Uint8List imageBytes,
    String? fileName,
  }) async {
    final taskFileName = fileName ?? 'task_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return uploadImageBytes(
      userId: userId,
      imageBytes: imageBytes,
      path: 'tasks',
      fileName: taskFileName,
    );
  }
  
  // Subir imagen para una recompensa
  Future<String?> uploadRewardImage({
    required String userId,
    required File imageFile,
    String? fileName,
  }) async {
    final rewardFileName = fileName ?? 'reward_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return uploadImage(
      userId: userId,
      imageFile: imageFile,
      path: 'rewards',
      fileName: rewardFileName,
    );
  }
  
  // Subir bytes de imagen para una recompensa (para web)
  Future<String?> uploadRewardImageBytes({
    required String userId,
    required Uint8List imageBytes,
    String? fileName,
  }) async {
    final rewardFileName = fileName ?? 'reward_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return uploadImageBytes(
      userId: userId,
      imageBytes: imageBytes,
      path: 'rewards',
      fileName: rewardFileName,
    );
  }
  
  // Eliminar una imagen
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Convertir URL a referencia de Storage
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Error al eliminar imagen: $e');
    }
  }
}
