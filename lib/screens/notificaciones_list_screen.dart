// Archivo: lib/screens/notificaciones_list_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:safety_app/models/app_notification.dart';
import 'package:intl/intl.dart';
import 'package:safety_app/screens/notificacion_detail_screen.dart';
import 'package:safety_app/services/notification_service.dart';

class NotificationsListScreen extends StatefulWidget {
  const NotificationsListScreen({super.key});

  @override
  State<NotificationsListScreen> createState() => _NotificationsListScreenState();
}

class _NotificationsListScreenState extends State<NotificationsListScreen> {
  final Box<AppNotification> _notificationBox = Hive.box<AppNotification>('notifications');
  final Set<String> _selectedIds = {};

  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? '${_selectedIds.length} seleccionada(s)' : 'Notificaciones'),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.mark_chat_read_outlined),
              tooltip: 'Marcar como leído',
              onPressed: () => _confirmAction(
                title: 'Marcar como Leído',
                content: '¿Estás seguro de que deseas marcar como leídas las ${_selectedIds.length} notificaciones seleccionadas?',
                onConfirm: _markSelectedAsRead,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar',
              onPressed: () => _confirmAction(
                title: 'Confirmar Eliminación',
                content: '¿Estás seguro de que deseas eliminar las ${_selectedIds.length} notificaciones seleccionadas? Esta acción no se puede deshacer.',
                onConfirm: _deleteSelected,
              ),
            ),
          ]
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
                color: isSelected ? Theme.of(context).primaryColor.withAlpha(40) : null,
                child: ListTile(
                  leading: _isSelectionMode
                      ? Icon(isSelected ? Icons.check_box : Icons.check_box_outline_blank)
                      : Icon(
                    notification.isRead ? Icons.mark_email_read_outlined : Icons.mark_email_unread,
                    color: notification.isRead ? Colors.grey : Theme.of(context).primaryColor,
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(notification.receivedDate.toLocal()),
                  ),
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggleSelection(notification.id);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NotificationDetailScreen(notificationId: notification.id),
                        ),
                      );
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

  // ✅ NUEVA FUNCIÓN REUTILIZABLE PARA MOSTRAR DIÁLOGO
  Future<void> _confirmAction({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(content),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Confirmar'),
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm(); // Ejecuta la acción (borrar o marcar)
              },
            ),
          ],
        );
      },
    );
  }

  void _markSelectedAsRead() {
    for (final id in _selectedIds) {
      final notification = _notificationBox.get(id);
      if (notification != null && !notification.isRead) {
        notification.isRead = true;
        notification.save();
      }
    }
    setState(() {
      _selectedIds.clear();
    });
    NotificationService.updateGlobalBadge();
  }

  Future<void> _deleteSelected() async {
    await _notificationBox.deleteAll(_selectedIds.toList());
    setState(() {
      _selectedIds.clear();
    });
    NotificationService.updateGlobalBadge();
  }
}