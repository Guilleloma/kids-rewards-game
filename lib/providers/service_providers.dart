import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

// Provider para el servicio de Firestore
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// Provider para el servicio de Storage
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
