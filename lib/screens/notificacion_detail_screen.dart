import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:safety_app/models/notification_model.dart';
import 'package:safety_app/services/notification_service.dart'; // Importa tu servicio
import 'package:intl/intl.dart';

class NotificationDetailScreen extends StatefulWidget {
  final String notificationId;
  const NotificationDetailScreen({super.key, required this.notificationId});

  @override
  State<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  final Box<NotificationModel> _notificationBox = Hive.box<NotificationModel>('notifications');
  NotificationModel? _notification;

  @override
  void initState() {
    super.initState();
    _loadAndMarkAsRead();
  }

  void _loadAndMarkAsRead() {
    final notification = _notificationBox.get(widget.notificationId);
    if (notification != null && !notification.isRead) {
      notification.isRead = true;
      _notificationBox.put(notification.id, notification);
      // Actualizar el contador del ícono
      NotificationService().updateBadgeCount();
    }
    setState(() {
      _notification = notification;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_notification == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Notificación no encontrada.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_notification!.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _notification!.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Recibido: ${DateFormat('dd MMM yyyy, hh:mm a').format(_notification!.receivedDate)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(height: 32),
            Text(
              _notification!.content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}