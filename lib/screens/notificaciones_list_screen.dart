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
  // ✅ CAMBIO: Ya no abrimos la caja aquí.
  // final Box<AppNotification> _notificationBox = Hive.box<AppNotification>('notifications'); // <-- LÍNEA ELIMINADA

  // ✅ CAMBIO: Usamos un Future para manejar la apertura de la caja.
  late Future<Box<AppNotification>> _openBoxFuture;
  final Set<String> _selectedIds = {};

  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    // ✅ CAMBIO: Llamamos a la función que abre la caja cuando se construye la pantalla.
    _openBoxFuture = _openNotificationsBox();
  }

  // ✅ CAMBIO: Nueva función para abrir la caja de forma asíncrona.
  // Esta es la operación que antes tardaba 2.45s en el SplashScreen.
  Future<Box<AppNotification>> _openNotificationsBox() async {
    debugPrint("Opening 'notifications' box for ListScreen...");
    final stopwatch = Stopwatch()..start();

    // Si ya se abrió en segundo plano (por NotificationService), esto será rápido.
    if (Hive.isBoxOpen('notifications')) {
      debugPrint("  Box 'notifications' was already open.");
      return Hive.box<AppNotification>('notifications');
    }

    // Si no, la abrimos aquí. El usuario verá un spinner.
    final box = await Hive.openBox<AppNotification>('notifications');
    debugPrint("  ✅ Box 'notifications' opened in: ${stopwatch.elapsedMilliseconds}ms");
    return box;
  }


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
                // Pasamos la caja de Hive a la función
                onConfirm: () => _markSelectedAsRead(Hive.box<AppNotification>('notifications')),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar',
              onPressed: () => _confirmAction(
                title: 'Confirmar Eliminación',
                content: '¿Estás seguro de que deseas eliminar las ${_selectedIds.length} notificaciones seleccionadas? Esta acción no se puede deshacer.',
                // Pasamos la caja de Hive a la función
                onConfirm: () => _deleteSelected(Hive.box<AppNotification>('notifications')),
              ),
            ),
          ]
        ],
      ),
      // ✅ CAMBIO: Envolvemos el cuerpo en un FutureBuilder.
      body: FutureBuilder<Box<AppNotification>>(
        future: _openBoxFuture,
        builder: (context, snapshot) {

          // --- MIENTRAS CARGA (los 2.45s) ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- SI HAY UN ERROR ---
          if (snapshot.hasError) {
            debugPrint("Error opening Hive box: ${snapshot.error}");
            return const Center(
              child: Text('Error al cargar notificaciones.'),
            );
          }

          // --- SI SE ABRIÓ CORRECTAMENTE ---
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No se pudo abrir la caja de notificaciones.'));
          }

          // ¡La caja está abierta!
          final notificationBox = snapshot.data!;

          // A partir de aquí, usamos el ValueListenableBuilder como lo tenías,
          // pero pasándole la 'notificationBox' que acabamos de abrir.
          return ValueListenableBuilder(
            valueListenable: notificationBox.listenable(),
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
                          // Al hacer tap, marcamos como leída
                          NotificationService.markAsReadAndUpdateBadge(notification.id);
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

  // (Tu función de diálogo de confirmación no necesita cambios)
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
                onConfirm();
              },
            ),
          ],
        );
      },
    );
  }

  // ✅ CAMBIO: Ahora recibe la caja como parámetro
  void _markSelectedAsRead(Box<AppNotification> notificationBox) {
    for (final id in _selectedIds) {
      final notification = notificationBox.get(id);
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

  // ✅ CAMBIO: Ahora recibe la caja como parámetro
  Future<void> _deleteSelected(Box<AppNotification> notificationBox) async {
    await notificationBox.deleteAll(_selectedIds.toList());
    setState(() {
      _selectedIds.clear();
    });
    NotificationService.updateGlobalBadge();
  }
}