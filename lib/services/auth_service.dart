import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart'; // 1. Importamos el paquete logger

// 2. Creamos una instancia del logger que usaremos en toda la clase.
final logger = Logger();

// Esta clase manejará toda la lógica de autenticación con Firebase.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> createUser({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      logger.i('Usuario creado exitosamente: $email'); // Log de información (info)
      return null;
    } on FirebaseAuthException catch (e) {
      // 3. Reemplazamos print() por llamadas a logger con el nivel adecuado.
      // 'w' es para warnings (advertencias).
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
    } catch (e, s) { // Atrapamos también el StackTrace (s)
      // 'e' es para errores críticos.
      // Pasamos el error y el stacktrace para un registro más completo.
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
      logger.i('Inicio de sesión exitoso: $email'); // Log de información
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