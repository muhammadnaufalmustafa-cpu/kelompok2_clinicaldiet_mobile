import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/firebase_notification_service.dart';

class NotifikasiScreen extends StatelessWidget {
  final String userId;
  final String role; // 'pasien' atau 'ahli_gizi'

  const NotifikasiScreen({super.key, required this.userId, required this.role});

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dt = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays > 0) {
      return '${diff.inDays} hari yang lalu';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} jam yang lalu';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'alert_log':
      case 'alert':
        return Icons.warning_amber_rounded;
      case 'target':
        return Icons.track_changes;
      case 'log':
        return Icons.edit_note;
      case 'review':
        return Icons.star_border;
      case 'info':
      default:
        return Icons.info_outline;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'alert_log':
      case 'alert':
        return Colors.orange;
      case 'target':
        return Colors.blue;
      case 'log':
        return Colors.green;
      case 'review':
        return Colors.amber;
      case 'info':
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Kotak Notifikasi', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        actions: [
          TextButton(
            onPressed: () => FirebaseNotificationService.markAllAsRead(userId, role),
            child: Text('Tandai Dibaca', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseNotificationService.getUserNotifications(userId, role),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan', style: GoogleFonts.manrope()));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text('Belum ada notifikasi', style: GoogleFonts.manrope(fontSize: 16, color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final isRead = data['isRead'] ?? true;
              final type = data['type'] ?? 'info';

              return GestureDetector(
                onTap: () {
                  if (!isRead) {
                    FirebaseNotificationService.markAsRead(doc.id);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isRead ? Colors.white : AppColors.primaryLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isRead ? AppColors.divider : AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getColorForType(type).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_getIconForType(type), color: _getColorForType(type), size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    data['title'] ?? '',
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatTime(data['createdAt'] as Timestamp?),
                                  style: GoogleFonts.manrope(fontSize: 10, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              data['message'] ?? '',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: isRead ? AppColors.textSecondary : AppColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isRead) ...[
                        const SizedBox(width: 8),
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
