import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

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
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error al obtener usuario: $e');
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
      // Crear usuario en Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      final user = userCredential.user;
      if (user == null) return null;
      
      // Crear perfil en Firestore
      final userModel = UserModel(
        id: user.uid,
        name: name,
        email: email,
        childName: childName,
        createdAt: DateTime.now(),
      );
      
      await _firestore.collection('users').doc(user.uid).set(userModel.toJson());
      
      return userModel;
    } catch (e) {
      print('Error en registro: $e');
      return null;
    }
  }
  
  // Inicio de sesión con email y contraseña
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      final user = userCredential.user;
      if (user == null) return null;
      
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (userDoc.exists) {
        return UserModel.fromJson(userDoc.data()!, userDoc.id);
      }
      return null;
    } catch (e) {
      print('Error en inicio de sesión: $e');
      return null;
    }
  }
  
  // Cerrar sesión
  Future<void> signOut() async {
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
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();
      
      if (!userDoc.exists) return null;
      
      final currentUser = UserModel.fromJson(userDoc.data()!, userDoc.id);
      
      final updatedUser = currentUser.copyWith(
        name: name,
        childName: childName,
        profileImage: profileImage,
      );
      
      await userRef.update({
        if (name != null) 'name': name,
        if (childName != null) 'childName': childName,
        if (profileImage != null) 'profileImage': profileImage,
      });
      
      return updatedUser;
    } catch (e) {
      print('Error al actualizar perfil: $e');
      return null;
    }
  }
}
