import 'package:hive/hive.dart';

part 'app_notification.g.dart';

@HiveType(typeId: 1)
class AppNotification extends HiveObject {
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

  AppNotification({
    required this.id,
    required this.title,
    required this.content,
    required this.receivedDate,
    this.isRead = false,
  });
}