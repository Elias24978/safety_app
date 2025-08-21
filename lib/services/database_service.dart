// lib/services/database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Actualiza el estado premium del usuario actual
  Future<void> updateUserPremiumStatus(bool isPremium) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).set(
        {'isPremium': isPremium},
        SetOptions(merge: true), // 'merge: true' para no sobreescribir otros datos del usuario
      );
    }
  }

  // Obtiene el estado premium del usuario actual
  Stream<bool> get isUserPremiumStream {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(false);
    }
    return _db.collection('users').doc(user.uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data()!.containsKey('isPremium')) {
        return snapshot.data()!['isPremium'] as bool;
      }
      return false;
    });
  }
}