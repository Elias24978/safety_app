// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:safety_app/services/firestore_service.dart';
import 'package:safety_app/services/notification_service.dart';

final logger = Logger();

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Instancias de nuestros otros servicios para poder usarlos.
  final NotificationService _notificationService = NotificationService();
  final FirestoreService _firestoreService = FirestoreService();

  /// Orquesta el flujo completo de post-autenticación.
  Future<void> _handlePostAuth(User user) async {
    // 1. Obtenemos el token FCM del dispositivo.
    final String? token = await _notificationService.getFCMToken();

    if (token != null) {
      // 2. Guardamos el token en Firestore asociado al ID del usuario.
      await _firestoreService.saveUserToken(user.uid, token);
    }
  }

  Future<String?> createUser({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ¡NUEVO! Si el usuario se crea, manejamos el token.
      if (userCredential.user != null) {
        await _handlePostAuth(userCredential.user!);
        logger.i('Usuario creado y token guardado: $email');
        return null;
      }
      return 'No se pudo crear el usuario.';
    } on FirebaseAuthException catch (e) {
      logger.w('Error de Firebase Auth (Registro): ${e.code}');
      if (e.code == 'weak-password') {
        return 'La contraseña es demasiado débil.';
      } else if (e.code == 'email-already-in-use') {
        return 'Este correo electrónico ya está registrado.';
      } else if (e.code == 'invalid-email') {
        return 'El formato del correo electrónico no es válido.';
      }
      return 'Ocurrió un error de autenticación.';
    } catch (e, s) {
      logger.e('Error inesperado (Registro)', error: e, stackTrace: s);
      return 'Ocurrió un error inesperado.';
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ¡NUEVO! Si el usuario inicia sesión, manejamos el token.
      if (userCredential.user != null) {
        await _handlePostAuth(userCredential.user!);
        logger.i('Inicio de sesión y token actualizado: $email');
        return null;
      }
      return 'No se pudo iniciar sesión.';
    } on FirebaseAuthException catch (e) {
      logger.w('Error de Firebase Auth (Login): ${e.code}');
      if (e.code == 'invalid-credential' || e.code == 'user-not-found' || e.code == 'wrong-password') {
        return 'Correo o contraseña incorrectos.';
      }
      return 'Ocurrió un error de autenticación.';
    } catch (e, s) {
      logger.e('Error inesperado (Login)', error: e, stackTrace: s);
      return 'Ocurrió un error inesperado.';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    logger.i('Sesión cerrada.');
  }
}