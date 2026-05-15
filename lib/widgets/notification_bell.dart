import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/notifikasi_screen.dart';
import '../services/firebase_notification_service.dart';
import '../theme/app_theme.dart';

class NotificationBell extends StatelessWidget {
  final String? userId;
  final String role;
  final Color iconColor;
  final EdgeInsetsGeometry padding;
  final BoxConstraints? constraints;

  const NotificationBell({
    super.key,
    required this.userId,
    required this.role,
    this.iconColor = AppColors.textSecondary,
    this.padding = EdgeInsets.zero,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final id = userId ?? '';
    if (id.isEmpty) {
      return IconButton(
        onPressed: null,
        icon: Icon(Icons.notifications_outlined, color: iconColor),
        padding: padding,
        constraints: constraints,
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseNotificationService.getUserNotifications(id, role),
      builder: (context, snapshot) {
        var unreadCount = 0;
        if (snapshot.hasData) {
          unreadCount = snapshot.data!.docs
              .where((doc) => (doc.data() as Map<String, dynamic>)['isRead'] == false)
              .length;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NotifikasiScreen(userId: id, role: role),
                  ),
                );
              },
              icon: Icon(Icons.notifications_outlined, color: iconColor),
              padding: padding,
              constraints: constraints,
            ),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: Center(
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
