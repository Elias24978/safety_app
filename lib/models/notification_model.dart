import 'package:hive/hive.dart';

part 'notification_model.g.dart'; // Este archivo se generará automáticamente

@HiveType(typeId: 1)
class NotificationModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final DateTime receivedDate;

  @HiveField(4)
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.receivedDate,
    this.isRead = false,
  });
}