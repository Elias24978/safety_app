import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safety_app/utils/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // GETTER AÑADIDO PARA SOLUCIONAR EL ERROR DE main.dart
  String? get currentUserId => _auth.currentUser?.uid;

  Future<String?> createUser({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'createdAt': Timestamp.now(),
        });
      }

      logger.i('Usuario creado exitosamente: $email');
      // AÑADIDO: Retorno nulo en caso de éxito
      return null;
    } on FirebaseAuthException catch (e) {
      logger.w('Error de Firebase Auth (Registro): ${e.code}');
      if (e.code == 'weak-password') {
        return 'La contraseña es demasiado débil.';
      } else if (e.code == 'email-already-in-use') {
        return 'Este correo electrónico ya está registrado.';
      } else if (e.code == 'invalid-email') {
        return 'El formato del correo electrónico no es válido.';
      } else {
        return 'Ocurrió un error de autenticación. Inténtalo de nuevo.';
      }
    } catch (e, s) {
      logger.e('Error inesperado (Registro)', error: e, stackTrace: s);
      return 'Ocurrió un error inesperado. Revisa tu conexión a internet.';
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      logger.i('Inicio de sesión exitoso: $email');
      // AÑADIDO: Retorno nulo en caso de éxito
      return null;
    } on FirebaseAuthException catch (e) {
      logger.w('Error de Firebase Auth (Login): ${e.code}');
      if (e.code == 'invalid-credential' || e.code == 'user-not-found' || e.code == 'wrong-password') {
        return 'Correo o contraseña incorrectos.';
      } else {
        return 'Ocurrió un error de autenticación. Inténtalo de nuevo.';
      }
    } catch (e, s) {
      logger.e('Error inesperado (Login)', error: e, stackTrace: s);
      return 'Ocurrió un error inesperado. Revisa tu conexión a internet.';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    logger.i('Sesión cerrada.');
  }
}