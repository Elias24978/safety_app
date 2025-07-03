import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime receivedDate;
  bool isRead;
  final String type;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedDate,
    this.isRead = false,
    this.type = 'info',
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? 'Sin Título',
      body: data['body'] ?? 'Sin Contenido',
      receivedDate: (data['receivedDate'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      type: data['type'] ?? 'info',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'receivedDate': Timestamp.fromDate(receivedDate),
      'isRead': isRead,
      'type': type,
    };
  }
}