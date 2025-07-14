import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:safety_app/models/app_notification.dart';
import 'package:safety_app/services/notification_service.dart';

class NotificationDetailScreen extends StatefulWidget {
  final String notificationId;

  const NotificationDetailScreen({
    super.key,
    required this.notificationId,
  });

  @override
  State<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Llama al método correcto para marcar como leída y actualizar el badge
    NotificationService.markAsReadAndUpdateBadge(widget.notificationId);
  }

  @override
  Widget build(BuildContext context) {
    // Usamos ValueListenableBuilder para que la pantalla se actualice si los datos de Hive cambian
    return ValueListenableBuilder<Box<AppNotification>>(
      valueListenable: Hive.box<AppNotification>('notifications').listenable(),
      builder: (context, box, _) {
        final notification = box.get(widget.notificationId);
        return Scaffold(
          appBar: AppBar(
            title: Text(notification?.title ?? 'Detalle'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: notification == null
                  ? const CircularProgressIndicator()
                  : Text(
                notification.content,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        );
      },
    );
  }
}