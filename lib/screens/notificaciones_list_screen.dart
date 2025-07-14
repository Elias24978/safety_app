import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:safety_app/models/app_notification.dart';
import 'package:intl/intl.dart'; // Añade el paquete intl a tu pubspec.yaml para formatear fechas

class NotificationsListScreen extends StatefulWidget {
  const NotificationsListScreen({super.key});

  @override
  State<NotificationsListScreen> createState() => _NotificationsListScreenState();
}

class _NotificationsListScreenState extends State<NotificationsListScreen> {
  final Box<AppNotification> _notificationBox = Hive.box<AppNotification>('notifications');
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (_selectedIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelected,
            ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: _notificationBox.listenable(),
        builder: (context, Box<AppNotification> box, _) {
          final notifications = box.values.toList()..sort((a, b) => b.receivedDate.compareTo(a.receivedDate));
          if (notifications.isEmpty) {
            return const Center(child: Text('No tienes notificaciones.'));
          }
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final isSelected = _selectedIds.contains(notification.id);
              return Container(
                color: isSelected ? Colors.blue.shade100 : null,
                child: ListTile(
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(notification.receivedDate),
                    style: const TextStyle(color: Colors.blue),
                  ),
                  onTap: () {
                    if (_selectedIds.isNotEmpty) {
                      _toggleSelection(notification.id);
                    } else {
                      // Navegar a la pantalla de detalle
                      // Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationDetailScreen(notificationId: notification.id)));
                    }
                  },
                  onLongPress: () {
                    _toggleSelection(notification.id);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _deleteSelected() {
    _notificationBox.deleteAll(_selectedIds);
    setState(() {
      _selectedIds.clear();
    });
    // Llama a updateBadgeCount si es necesario
  }
}