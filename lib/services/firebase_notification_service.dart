import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseNotificationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Buat Notifikasi Baru ──
  static Future<void> createNotification({
    required String userId,
    required String role, // 'pasien' atau 'ahli_gizi'
    required String title,
    required String message,
    required String type, // 'alert', 'log', 'target', 'review', 'info'
    String? relatedId,
  }) async {
    try {
      await _db.collection('notifications').add({
        'userId': userId,
        'role': role,
        'title': title,
        'message': message,
        'type': type,
        'isRead': false,
        'relatedId': relatedId ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // ── Ambil Stream Notifikasi (Realtime) ──
  static Stream<QuerySnapshot> getUserNotifications(String userId, String role) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('role', isEqualTo: role)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ── Tandai Sudah Dibaca ──
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _db.collection('notifications').doc(notificationId).update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // ── Tandai Semua Sudah Dibaca ──
  static Future<void> markAllAsRead(String userId, String role) async {
    try {
      final unreadDocs = await _db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('role', isEqualTo: role)
          .where('isRead', isEqualTo: false)
          .get();
      
      final batch = _db.batch();
      for (var doc in unreadDocs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  // ── Helper: Cek & Buat Auto-Alert Harian untuk Pasien ──
  static Future<void> checkAndCreateDailyAlert(String patientRm, String patientId) async {
    try {
      // Logic untuk mengecek apakah sudah ada alert harian hari ini
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      // 1. Cek apakah log makanan hari ini kosong
      final logsQuery = await _db
          .collection('meal_logs')
          .where('rm', isEqualTo: patientRm)
          .where('date', isEqualTo: startOfDay.toIso8601String().split('T')[0])
          .get();
          
      if (logsQuery.docs.isEmpty) {
        // Cek apakah notifikasi pengingat sudah dibuat hari ini
        final notifQuery = await _db
            .collection('notifications')
            .where('userId', isEqualTo: patientId)
            .where('type', isEqualTo: 'alert_log')
            .get();
            
        bool alreadyNotifiedToday = false;
        for (var doc in notifQuery.docs) {
          final createdAt = (doc['createdAt'] as Timestamp?)?.toDate();
          if (createdAt != null && createdAt.isAfter(startOfDay)) {
            alreadyNotifiedToday = true;
            break;
          }
        }
        
        if (!alreadyNotifiedToday && now.hour >= 18) { // Alert jam 6 sore jika belum isi
          await createNotification(
            userId: patientId,
            role: 'pasien',
            title: 'Pengingat Catatan Makan',
            message: 'Anda belum mengisi catatan makan hari ini. Yuk isi sekarang agar ahli gizi bisa memantau perkembangan Anda!',
            type: 'alert_log',
          );
        }
      }
    } catch (e) {
      print('Error checking daily alert: $e');
    }
  }
}
