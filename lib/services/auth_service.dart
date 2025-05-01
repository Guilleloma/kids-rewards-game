import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/dev_logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Usuario actual
  User? get currentUser => _auth.currentUser;
  
  // Stream de cambios en el estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Obtener modelo de usuario actual desde Firestore
  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    try {
      devLogger.log("Obteniendo modelo de usuario para: ${user.uid}", level: LogLevel.debug);
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        devLogger.log("Documento de usuario existe en Firestore", level: LogLevel.debug);
        return UserModel.fromJson(doc.data()!, doc.id);
      }
      devLogger.log("Usuario no encontrado en Firestore", level: LogLevel.warning);
      return null;
    } catch (e) {
      devLogger.log("Error al obtener usuario: $e", level: LogLevel.error);
      return null;
    }
  }
  
  // Registro con email y contraseña
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
    required String childName,
  }) async {
    try {
      devLogger.log("Iniciando registro de usuario: $email", level: LogLevel.info);
      
      // Validación básica
      if (email.isEmpty || !email.contains('@')) {
        devLogger.log("Email inválido: $email", level: LogLevel.error);
        throw Exception('Correo electrónico inválido');
      }
      
      if (password.length < 6) {
        devLogger.log("Contraseña demasiado corta", level: LogLevel.error);
        throw Exception('La contraseña debe tener al menos 6 caracteres');
      }
      
      // Crear usuario en Auth
      devLogger.log("Creando usuario en Firebase Auth", level: LogLevel.debug);
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      final user = userCredential.user;
      if (user == null) {
        devLogger.log("Firebase no devolvió un objeto User después del registro", level: LogLevel.error);
        throw Exception('No se pudo crear el usuario');
      }
      
      devLogger.log("Usuario creado en Firebase Auth: ${user.uid}", level: LogLevel.info);
      
      // Crear perfil en Firestore
      final userModel = UserModel(
        id: user.uid,
        name: name,
        email: email,
        childName: childName,
        createdAt: DateTime.now(),
      );
      
      devLogger.log("Guardando perfil de usuario en Firestore...", level: LogLevel.debug);
      try {
        await _firestore.collection('users').doc(user.uid).set(userModel.toJson());
        devLogger.log("Perfil guardado correctamente en Firestore", level: LogLevel.info);
      } catch (firestoreError) {
        devLogger.log("ERROR CRÍTICO: Falló guardado en Firestore: $firestoreError", level: LogLevel.wtf);
        // Intentar eliminar el usuario de Auth ya que no se pudo crear el perfil
        try {
          await user.delete();
          devLogger.log("Usuario eliminado de Auth tras fallo en Firestore", level: LogLevel.info);
        } catch (deleteError) {
          devLogger.log("No se pudo eliminar usuario de Auth: $deleteError", level: LogLevel.error);
        }
        throw Exception('Error al guardar perfil de usuario: $firestoreError');
      }
      
      return userModel;
    } on FirebaseAuthException catch (e) {
      devLogger.log("FirebaseAuthException en registro: ${e.code} - ${e.message}", level: LogLevel.error);
      
      // Traducir errores comunes de Firebase
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception('El correo electrónico ya está en uso');
        case 'invalid-email':
          throw Exception('Correo electrónico inválido');
        case 'weak-password':
          throw Exception('La contraseña es demasiado débil');
        case 'operation-not-allowed':
          throw Exception('El registro con correo y contraseña no está habilitado');
        case 'too-many-requests':
          throw Exception('Demasiados intentos fallidos. Intenta más tarde');
        case 'network-request-failed':
          throw Exception('Error de conexión. Verifica tu internet');
        default:
          throw Exception('Error al registrar usuario: ${e.message}');
      }
    } catch (e) {
      devLogger.log("Error inesperado en registro: $e", level: LogLevel.error);
      throw Exception('Error al registrar usuario: $e');
    }
  }
  
  // Inicio de sesión con email y contraseña
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      devLogger.log("Iniciando sesión de usuario: $email", level: LogLevel.info);
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      final user = userCredential.user;
      if (user == null) {
        devLogger.log("Firebase no devolvió un objeto User después del inicio de sesión", level: LogLevel.error);
        throw Exception('No se pudo autenticar el usuario');
      }
      
      devLogger.log("Usuario autenticado en Firebase Auth: ${user.uid}", level: LogLevel.info);
      
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (userDoc.exists) {
        devLogger.log("Perfil de usuario encontrado en Firestore", level: LogLevel.debug);
        return UserModel.fromJson(userDoc.data()!, userDoc.id);
      }
      devLogger.log("Perfil de usuario no encontrado en Firestore", level: LogLevel.warning);
      throw Exception('Perfil de usuario no encontrado');
    } on FirebaseAuthException catch (e) {
      devLogger.log("FirebaseAuthException en inicio de sesión: ${e.code} - ${e.message}", level: LogLevel.error);
      
      // Traducir errores comunes de Firebase
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
          throw Exception('Credenciales incorrectas');
        case 'invalid-email':
          throw Exception('Correo electrónico inválido');
        case 'user-disabled':
          throw Exception('Usuario deshabilitado');
        case 'too-many-requests':
          throw Exception('Demasiados intentos fallidos. Intenta más tarde');
        case 'network-request-failed':
          throw Exception('Error de conexión. Verifica tu internet');
        default:
          throw Exception('Error al iniciar sesión: ${e.message}');
      }
    } catch (e) {
      devLogger.log("Error inesperado en inicio de sesión: $e", level: LogLevel.error);
      throw Exception('Error al iniciar sesión: $e');
    }
  }
  
  // Cerrar sesión
  Future<void> signOut() async {
    devLogger.log("Cerrando sesión de usuario", level: LogLevel.info);
    await _auth.signOut();
  }
  
  // Actualizar perfil de usuario
  Future<UserModel?> updateUserProfile({
    required String userId,
    String? name,
    String? childName,
    String? profileImage,
  }) async {
    try {
      devLogger.log("Actualizando perfil de usuario: $userId", level: LogLevel.info);
      
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();
      
      if (!userDoc.exists) {
        devLogger.log("Perfil de usuario no encontrado en Firestore", level: LogLevel.warning);
        return null;
      }
      
      final currentUser = UserModel.fromJson(userDoc.data()!, userDoc.id);
      
      final updatedUser = currentUser.copyWith(
        name: name,
        childName: childName,
        profileImage: profileImage,
      );
      
      devLogger.log("Guardando cambios en perfil de usuario...", level: LogLevel.debug);
      await userRef.update({
        if (name != null) 'name': name,
        if (childName != null) 'childName': childName,
        if (profileImage != null) 'profileImage': profileImage,
      });
      
      devLogger.log("Perfil de usuario actualizado correctamente", level: LogLevel.info);
      
      return updatedUser;
    } catch (e) {
      devLogger.log("Error al actualizar perfil de usuario: $e", level: LogLevel.error);
      return null;
    }
  }
}
