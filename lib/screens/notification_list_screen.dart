import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:safety_app/models/notification_model.dart';
import 'package:safety_app/screens/notification_detail_screen.dart';
import 'package:safety_app/services/notification_service.dart';

class NotificationListScreen extends StatelessWidget {
  const NotificationListScreen({super.key});

  IconData _getIconForType(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle_outline;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Scaffold(
          body: Center(child: Text("Inicia sesión para ver tus notificaciones.")));
    }

    NotificationService().updateBadgeCount();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notificaciones"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .orderBy('receivedDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No tienes notificaciones."));
          }

          final notifications = snapshot.data!.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList();

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                leading: Icon(_getIconForType(notification.type),
                    color: Colors.black54),
                title: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight:
                    notification.isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  DateFormat('d MMM. yyyy', 'es_MX')
                      .format(notification.receivedDate),
                  style: const TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  final docRef = FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('notifications')
                      .doc(notification.id);
                  docRef.update({'isRead': true});

                  NotificationService().updateBadgeCount();

                  // --- LÍNEA CORREGIDA ---
                  // Ahora pasamos 'notificationId' con el 'id' del documento.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationDetailScreen(
                          notificationId: notification.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}