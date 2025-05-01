import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  
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
    required String taskId,
  }) async {
    return uploadImage(
      userId: userId,
      imageFile: imageFile,
      path: 'tasks',
      fileName: 'task_$taskId.jpg',
    );
  }
  
  // Subir imagen para una recompensa
  Future<String?> uploadRewardImage({
    required String userId,
    required File imageFile,
    required String rewardId,
  }) async {
    return uploadImage(
      userId: userId,
      imageFile: imageFile,
      path: 'rewards',
      fileName: 'reward_$rewardId.jpg',
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
