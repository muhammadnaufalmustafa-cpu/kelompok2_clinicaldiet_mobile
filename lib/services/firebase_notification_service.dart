import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseNotificationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Buat Notifikasi Baru ──
  static Future<void> createNotification({
    required String userId,
    required String role, // 'pasien' atau 'ahli_gizi'
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    try {
      if (userId.isEmpty) return;
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
      /* debug log removed */
    }
  }

  // ── Ambil Stream Notifikasi (Realtime) ──
  static Stream<QuerySnapshot> getUserNotifications(String userId, String role) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('role', isEqualTo: role)
        .snapshots();
  }

  // ── Tandai Sudah Dibaca ──
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _db.collection('notifications').doc(notificationId).update({'isRead': true});
    } catch (e) {
      /* debug log removed */
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
      /* debug log removed */
    }
  }

  // ════════════════════════════════════════════
  // ── HELPER: Dapatkan UID Ahli Gizi dari NIP ──
  // ════════════════════════════════════════════
  static Future<String?> _getAhliGiziUidByNip(String nip) async {
    try {
      final snap = await _db
          .collection('users')
          .where('nip', isEqualTo: nip)
          .where('role', isEqualTo: 'ahli_gizi')
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) return snap.docs.first.data()['uid'] as String?;
    } catch (_) {}
    return null;
  }

  // ════════════════════════════════════════════════
  // ── NOTIFIKASI 1: Rating dikirim pasien ──
  // ════════════════════════════════════════════════
  static Future<void> notifyRatingReceived({
    required String ahliGiziNip,
    required String pasienName,
    required String pasienRm,
    required int rating,
  }) async {
    final uid = await _getAhliGiziUidByNip(ahliGiziNip);
    if (uid == null) return;
    final stars = '⭐' * rating;
    await createNotification(
      userId: uid,
      role: 'ahli_gizi',
      title: '⭐ Rating Baru dari Pasien',
      message: 'Pasien $pasienName (RM: $pasienRm) memberikan rating $stars untuk Anda.',
      type: 'rating',
      relatedId: pasienRm,
    );
  }

  // ════════════════════════════════════════════════
  // ── NOTIFIKASI 2: Pasien baru bergabung ──
  // ════════════════════════════════════════════════
  static Future<void> notifyNewPatientJoined({
    required String ahliGiziNip,
    required String pasienName,
    required String pasienRm,
  }) async {
    final uid = await _getAhliGiziUidByNip(ahliGiziNip);
    if (uid == null) return;
    await createNotification(
      userId: uid,
      role: 'ahli_gizi',
      title: '👤 Pasien Baru Bergabung',
      message: 'Pasien baru $pasienName (RM: $pasienRm) telah memilih Anda sebagai ahli gizi pendampingnya.',
      type: 'new_patient',
      relatedId: pasienRm,
    );
  }

  // ══════════════════════════════════════════════════════
  // ── NOTIFIKASI 3: Ahli Gizi ubah status pasien ──
  // ══════════════════════════════════════════════════════
  static Future<void> notifyStatusChanged({
    required String patientId,
    required String newStatus,
    required String ahliGiziName,
  }) async {
    if (patientId.isEmpty) return;
    final statusLabel = {
      'aktif': 'Aktif',
      'berhasil': 'Berhasil / Sembuh',
      'meninggal': 'Meninggal',
      'dropout': 'Dropout',
    }[newStatus] ?? newStatus;
    await createNotification(
      userId: patientId,
      role: 'pasien',
      title: '📋 Status Anda Diperbarui',
      message: 'Ahli Gizi $ahliGiziName telah mengubah status Anda menjadi: "$statusLabel".',
      type: 'status_change',
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ── NOTIFIKASI 4: Ahli Gizi simpan data (diagnosis / catatan) ──
  // ══════════════════════════════════════════════════════════════
  static Future<void> notifyDataSaved({
    required String patientId,
    required String ahliGiziName,
  }) async {
    if (patientId.isEmpty) return;
    await createNotification(
      userId: patientId,
      role: 'pasien',
      title: '📝 Data Klinis Diperbarui',
      message: 'Ahli Gizi $ahliGiziName telah memperbarui data klinis (diagnosis / catatan gizi) Anda.',
      type: 'data_update',
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ── NOTIFIKASI 5: Pasien update BB/TB ──
  // ══════════════════════════════════════════════════════════════
  static Future<void> notifyBBTBUpdated({
    required String ahliGiziNip,
    required String pasienName,
    required String pasienRm,
    required double weight,
    required double height,
  }) async {
    final uid = await _getAhliGiziUidByNip(ahliGiziNip);
    if (uid == null) return;
    await createNotification(
      userId: uid,
      role: 'ahli_gizi',
      title: '⚖️ Pasien Perbarui BB/TB',
      message: 'Pasien $pasienName (RM: $pasienRm) memperbarui data fisik: BB ${weight.toStringAsFixed(1)} kg | TB ${height.toStringAsFixed(0)} cm.',
      type: 'bbtb_update',
      relatedId: pasienRm,
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ── NOTIFIKASI 6: Pasien pilih/ubah jenis diet ──
  // ══════════════════════════════════════════════════════════════
  static Future<void> notifyDietChanged({
    required String ahliGiziNip,
    required String pasienName,
    required String pasienRm,
    required String dietName,
  }) async {
    final uid = await _getAhliGiziUidByNip(ahliGiziNip);
    if (uid == null) return;
    await createNotification(
      userId: uid,
      role: 'ahli_gizi',
      title: '🥗 Pasien Ubah Pilihan Diet',
      message: 'Pasien $pasienName (RM: $pasienRm) menambahkan program diet: "$dietName".',
      type: 'diet_change',
      relatedId: pasienRm,
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // ── ALERT 7: Cek log pasien hari ini & kemarin (saat buka app) ──
  // ══════════════════════════════════════════════════════════════════
  static Future<void> checkAndCreateDailyAlert(String patientRm, String patientId) async {
    try {
      if (patientId.isEmpty || patientRm.isEmpty) return;
      
      final userDoc = await _db.collection('users').doc(patientId).get();
      if (!userDoc.exists) return;
      
      final createdAtTs = userDoc.data()?['createdAt'] as Timestamp?;
      final userCreatedAt = createdAtTs?.toDate() ?? DateTime(2000);

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfYesterday = startOfDay.subtract(const Duration(days: 1));

      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final yesterdayStr = '${startOfYesterday.year}-${startOfYesterday.month.toString().padLeft(2, '0')}-${startOfYesterday.day.toString().padLeft(2, '0')}';

      // Cek log hari ini
      final todayLogs = await _db
          .collection('meal_logs')
          .where('rm', isEqualTo: patientRm)
          .where('date', isEqualTo: todayStr)
          .limit(1)
          .get();

      // Cek notifikasi yang sudah ada (hanya fetch alert)
      final notifQuery = await _db
          .collection('notifications')
          .where('userId', isEqualTo: patientId)
          .where('type', whereIn: ['alert_log', 'alert_log_2days'])
          .get();

      bool alreadyNotifiedToday = notifQuery.docs.any((doc) {
        final t = (doc['type'] as String?) ?? '';
        final createdAt = (doc['createdAt'] as Timestamp?)?.toDate();
        return t == 'alert_log' && createdAt != null && createdAt.isAfter(startOfDay);
      });

      // Notif untuk pasien (jam >= 18.00)
      if (!alreadyNotifiedToday) {
        // Jangan kirim alert_log jika user baru daftar hari ini
        if (userCreatedAt.isBefore(startOfDay)) {
          if (todayLogs.docs.isEmpty && now.hour >= 18) {
            await createNotification(
              userId: patientId,
              role: 'pasien',
              title: '🍽️ Pengingat Catatan Makan',
              message: 'Anda belum mengisi catatan makan hari ini. Yuk isi sekarang agar ahli gizi bisa memantau perkembangan Anda!',
              type: 'alert_log',
            );
          }
        }
      }

      // Cek log kemarin – jika kosong, kirim alert tambahan ke pasien
      if (todayLogs.docs.isEmpty) {
        // Jangan kirim alert_log_2days jika user baru daftar hari ini atau kemarin
        if (userCreatedAt.isBefore(startOfYesterday)) {
          final yesterdayLogs = await _db
              .collection('meal_logs')
              .where('rm', isEqualTo: patientRm)
              .where('date', isEqualTo: yesterdayStr)
              .limit(1)
              .get();

          if (yesterdayLogs.docs.isEmpty) {
            // Cek apakah sudah ada notif "2 hari tidak isi" hari ini
            final missedNotif = notifQuery.docs.any((doc) {
              final t = (doc['type'] as String?) ?? '';
              final createdAt = (doc['createdAt'] as Timestamp?)?.toDate();
              return t == 'alert_log_2days' &&
                  createdAt != null &&
                  createdAt.isAfter(startOfDay);
            });

            if (!missedNotif) {
              await createNotification(
                userId: patientId,
                role: 'pasien',
                title: '⚠️ Catatan Makan Terlewat',
                message: 'Anda belum mengisi catatan makan selama 2 hari. Segera isi agar ahli gizi dapat memantau kondisi Anda dengan baik.',
                type: 'alert_log_2days',
              );
            }
          }
        }
      }
    } catch (e) {
      /* debug log removed */
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // ── ALERT 8: Ahli Gizi cek apakah pasien tidak isi log (buka detail) ──
  // ════════════════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> checkPatientMissedLogs({
    required String patientRm,
    required String patientId,
    required String patientName,
    required String ahliGiziId,
    required String ahliGiziName,
    int daysToCheck = 3,
  }) async {
    try {
      final now = DateTime.now();
      List<String> missedDays = [];

      for (int i = 1; i <= daysToCheck; i++) {
        final d = now.subtract(Duration(days: i));
        final dateStr = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        final logs = await _db
            .collection('meal_logs')
            .where('rm', isEqualTo: patientRm)
            .where('date', isEqualTo: dateStr)
            .limit(1)
            .get();
        if (logs.docs.isEmpty) missedDays.add(dateStr);
      }

      // Jika pasien tidak isi >= 1 hari, kirim notif ke Ahli Gizi (max 1x per hari)
      if (missedDays.isNotEmpty && ahliGiziId.isNotEmpty) {
        final startOfDay = DateTime(now.year, now.month, now.day);
        final existingNotif = await _db
            .collection('notifications')
            .where('userId', isEqualTo: ahliGiziId)
            .where('relatedId', isEqualTo: patientRm)
            .where('type', isEqualTo: 'alert_patient_log')
            .get();

        final alreadySentToday = existingNotif.docs.any((doc) {
          final createdAt = (doc['createdAt'] as Timestamp?)?.toDate();
          return createdAt != null && createdAt.isAfter(startOfDay);
        });

        if (!alreadySentToday) {
          await createNotification(
            userId: ahliGiziId,
            role: 'ahli_gizi',
            title: '⚠️ Pasien Tidak Mengisi Log',
            message: 'Pasien $patientName (RM: $patientRm) tidak mengisi catatan makan selama ${missedDays.length} hari terakhir.',
            type: 'alert_patient_log',
            relatedId: patientRm,
          );
        }
      }

      return {
        'missedDays': missedDays.length,
        'hasMissed': missedDays.isNotEmpty,
      };
    } catch (e) {
      /* debug log removed */
      return {'missedDays': 0, 'hasMissed': false};
    }
  }
}
