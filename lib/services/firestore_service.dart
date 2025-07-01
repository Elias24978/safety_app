// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Guarda o actualiza el token de FCM para un usuario específico.
  Future<void> saveUserToken(String userId, String token) async {
    try {
      // Apuntamos a la colección 'users' y al documento con el ID del usuario.
      final userDocRef = _db.collection('users').doc(userId);

      // Usamos .set() con SetOptions(merge: true) para no sobrescribir
      // otros datos del usuario si el documento ya existe.
      // Esto crea el documento si no existe, o actualiza el campo fcmToken si existe.
      await userDocRef.set(
        {
          'fcmToken': token,
          'lastUpdated': FieldValue.serverTimestamp(), // Guarda la fecha de actualización
        },
        SetOptions(merge: true),
      );
      logger.i('Token FCM guardado para el usuario: $userId');
    } catch (e, s) {
      logger.e('Error al guardar el token FCM', error: e, stackTrace: s);
      // Opcional: podrías re-lanzar el error si quieres manejarlo en la UI.
    }
  }
}