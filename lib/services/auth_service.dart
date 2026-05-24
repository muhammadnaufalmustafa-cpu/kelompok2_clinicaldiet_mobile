import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static const String _usersKey = 'registered_users';
  static const String _loggedInUserKey = 'logged_in_user';

  // ------------------------------------------------------------------------------------ REGISTRASI PASIEN ------------------------------------------------------------------------------------

  static Future<Map<String, dynamic>> register({
    required String name,
    required String rm,
    required String email,
    required String weight,
    required String height,
    required String password,
    required String gender,
    required String birthdate,
    required String phone,
    String? username,
    String? alamat,
    String? pendidikan,
    String? pekerjaan,
    String? nik,
    String? agama,
  }) async {
    try {
      final usersRef = FirebaseFirestore.instance.collection('users');

      // 1. Cek duplikasi RM di Firestore
      final rmCheck = await usersRef
          .where('rm', isEqualTo: rm)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw 'Koneksi lambat (Timeout) saat mengecek RM. Periksa internet Anda.',
          );
      if (rmCheck.docs.isNotEmpty) {
        return {'success': false, 'message': 'Nomor RM sudah terdaftar!'};
      }

      // 2. Cek duplikasi Username di Firestore
      if (username != null && username.isNotEmpty) {
        final usernameCheck = await usersRef
            .where('username', isEqualTo: username)
            .get()
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () =>
                  throw 'Koneksi lambat (Timeout) saat mengecek Username. Periksa internet Anda.',
            );
        if (usernameCheck.docs.isNotEmpty) {
          return {'success': false, 'message': 'Username sudah digunakan!'};
        }
      }

      // 3. Buat akun di Firebase Auth
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw 'Koneksi lambat (Timeout) saat membuat akun di Firebase Auth.',
          );

      final uid = userCredential.user!.uid;

      // 4. Simpan profil pasien ke Firestore
      final newUser = {
        'uid': uid,
        'role': 'pasien',
        'name': name,
        'rm': rm,
        'email': email,
        'weight': double.tryParse(weight) ?? 0.0,
        'height': double.tryParse(height) ?? 0.0,
        'gender': gender,
        'birthdate': birthdate,
        'phone': phone,
        'diet_type': '',
        'status': 'aktif',
        'username': username,
        'alamat': alamat,
        'pendidikan': pendidikan,
        'pekerjaan': pekerjaan,
        'nik': nik,
        'agama': agama,
        'created_at': FieldValue.serverTimestamp(),
      };

      await usersRef
          .doc(uid)
          .set(newUser)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw 'Koneksi lambat (Timeout) saat menyimpan data profil.',
          );

      return {'success': true, 'message': 'Registrasi berhasil!'};
    } on FirebaseAuthException catch (e) {
      String msg = 'Terjadi kesalahan saat registrasi.';
      if (e.code == 'weak-password') {
        msg = 'Kata sandi minimal 6 karakter.';
      } else if (e.code == 'email-already-in-use') {
        msg = 'Email sudah terdaftar.';
      }
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ------------------------------------------------------------------------------------ REGISTRASI AHLI GIZI ---------------------------------------------------------------------------

    static Future<Map<String, dynamic>> registerAdmin({
    required String name,
    required String username,
    required String email,
    required String phone,
    required String password,
    required String nip,
  }) async {
    try {
      final usersRef = FirebaseFirestore.instance.collection('users');

      // 1. Cek duplikasi Username
      final usernameCheck = await usersRef
          .where('username', isEqualTo: username)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw 'Koneksi lambat (Timeout) saat mengecek Username.',
          );
      if (usernameCheck.docs.isNotEmpty) {
        return {'success': false, 'message': 'Username sudah digunakan!'};
      }

      // 2. Buat akun di Firebase Auth
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw 'Koneksi lambat (Timeout) saat membuat akun di Firebase Auth.',
          );

      final uid = userCredential.user!.uid;

      // 3. Simpan data Admin
      final newAdmin = {
        'uid': uid,
        'role': 'admin',
        'name': name,
        'username': username,
        'email': email,
        'phone': phone,
        'nip': nip,
        'created_at': FieldValue.serverTimestamp(),
      };

      await usersRef
          .doc(uid)
          .set(newAdmin)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw 'Koneksi lambat (Timeout) saat menyimpan data Admin.',
          );

      return {'success': true, 'message': 'Registrasi Admin berhasil!'};
    } on FirebaseAuthException catch (e) {
      String msg = 'Terjadi kesalahan saat registrasi.';
      if (e.code == 'weak-password') {
        msg = 'Kata sandi minimal 6 karakter.';
      } else if (e.code == 'email-already-in-use') {
        msg = 'Email sudah terdaftar.';
      }
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

static Future<Map<String, dynamic>> registerAhliGizi({
    required String name,
    required String nip,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final usersRef = FirebaseFirestore.instance.collection('users');

      // 1. Cek duplikasi NIP
      final nipCheck = await usersRef
          .where('nip', isEqualTo: nip)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw 'Koneksi lambat (Timeout) saat mengecek NIP.',
          );
      if (nipCheck.docs.isNotEmpty) {
        return {'success': false, 'message': 'NIP sudah terdaftar!'};
      }

      // 2. Buat akun di Firebase Auth
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw 'Koneksi lambat (Timeout) saat membuat akun di Firebase Auth.',
          );

      final uid = userCredential.user!.uid;

      // 3. Simpan data Ahli Gizi
      final newAhliGizi = {
        'uid': uid,
        'role': 'ahli_gizi',
        'name': name,
        'nip': nip,
        'email': email,
        'phone': phone,
        'specialization': '',
        'rating': 0.0,
        'rating_count': 0,
        'reviews': [],
        'status_akun': 'pending', // Menunggu verifikasi admin
        'created_at': FieldValue.serverTimestamp(),
      };

      await usersRef
          .doc(uid)
          .set(newAhliGizi)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw 'Koneksi lambat (Timeout) saat menyimpan data Ahli Gizi.',
          );

      // Kirim notifikasi ke admin bahwa ada pendaftar baru
      try {
        final adminSnap = await usersRef
            .where('role', isEqualTo: 'admin')
            .limit(1)
            .get();
        if (adminSnap.docs.isNotEmpty) {
          final adminUid = adminSnap.docs.first.data()['uid'] as String? ?? '';
          if (adminUid.isNotEmpty) {
            await FirebaseFirestore.instance.collection('notifications').add({
              'userId': adminUid,
              'role': 'admin',
              'title': '🔔 Pendaftaran Ahli Gizi Baru',
              'message':
                  '$name (NIP: $nip) mendaftar dan menunggu verifikasi Anda.',
              'type': 'new_ahligizi_request',
              'isRead': false,
              'relatedId': uid,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        }
      } catch (_) {}

      return {
        'success': true,
        'message':
            'Pendaftaran berhasil! Akun Anda sedang menunggu verifikasi dari Admin.',
      };
    } on FirebaseAuthException catch (e) {
      String msg = 'Terjadi kesalahan saat registrasi.';
      if (e.code == 'weak-password') {
        msg = 'Kata sandi minimal 6 karakter.';
      } else if (e.code == 'email-already-in-use') {
        msg = 'Email sudah terdaftar.';
      }
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ------------------------------------------------------------------------------------ AMBIL SEMUA AHLI GIZI ------------------------------------------------------------------------

  static Future<List<Map<String, dynamic>>> getAllAhliGizi() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'ahli_gizi')
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      return [];
    }
  }

  // ------------------------------------------------------------------------------------ RATING AHLI GIZI ---------------------------------------------------------------------------------------

  static Future<void> submitRatingAhliGizi(
    String nip,
    double newRating, {
    String ulasan = '',
    String pasienName = 'Pasien',
    String pasienRm = '',
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('nip', isEqualTo: nip)
          .where('role', isEqualTo: 'ahli_gizi')
          .get();
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final ag = doc.data();

        final currentRating = (ag['rating'] as num?)?.toDouble() ?? 0.0;
        final currentCount = (ag['rating_count'] as num?)?.toInt() ?? 0;

        // Remove old rating from this patient if exists
        List reviews = ag['reviews'] ?? [];
        double ratingDiff = newRating;
        int countDiff = 1;

        if (pasienRm.isNotEmpty) {
          final existingIndex = reviews.indexWhere(
            (r) => r['pasienRm'] == pasienRm,
          );
          if (existingIndex != -1) {
            final oldRating =
                (reviews[existingIndex]['rating'] as num?)?.toDouble() ?? 0.0;
            ratingDiff = newRating - oldRating;
            countDiff = 0; // Already rated, just updating
            reviews.removeAt(existingIndex);
          }
        }

        final newCount = currentCount + countDiff;
        final updatedRating = newCount > 0
            ? ((currentRating * currentCount) + ratingDiff) / newCount
            : newRating;

        reviews.insert(0, {
          'pasienRm': pasienRm,
          'pasienName': pasienName,
          'rating': newRating,
          'ulasan': ulasan,
          'tanggal': DateTime.now().toIso8601String(),
        });

        await doc.reference.update({
          'rating': updatedRating,
          'rating_count': newCount,
          'reviews': reviews,
        });
      }
    } catch (e) {
      // Ignore error for now
    }
  }

  // ------------------------------------------------------------------------------------ LOGIN (PASIEN & AHLI GIZI) ---------------------------------------------------------
  // --------- LOGIN UNIVERSAL (SATU PINTU TANPA PILIH ROLE) ---------
  static Future<Map<String, dynamic>> loginUniversal({
    required String identifier, // bisa rm, nip, username, atau email
    required String password,
  }) async {
    try {
      /* debug log removed */
      final usersRef = FirebaseFirestore.instance.collection('users');
      String loginEmail = identifier;

      // 1. Jika bukan format email, cari emailnya di Firestore berdasarkan RM, Username, atau NIP
      if (!identifier.contains('@')) {
        /* debug log removed */
        var check = await usersRef.where('rm', isEqualTo: identifier).get();
        if (check.docs.isEmpty) {
          check = await usersRef.where('username', isEqualTo: identifier).get();
        }
        if (check.docs.isEmpty) {
          check = await usersRef.where('nip', isEqualTo: identifier).get();
        }

        if (check.docs.isNotEmpty) {
          loginEmail = check.docs.first.data()['email'] ?? '';
        } else {
          return {
            'success': false,
            'message': 'Username / RM / NIP tidak terdaftar.',
          };
        }
      }

      /* debug log removed */
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: loginEmail, password: password);

      final uid = userCredential.user!.uid;

      /* debug log removed */
      final userDoc = await usersRef
          .doc(uid)
          .get()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw 'Timeout saat mengambil profil pengguna.',
          );

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();
        return {
          'success': false,
          'message': 'Data akun tidak ditemukan di database.',
        };
      }

      final userData = userDoc.data()!;
      final userRole = userData['role'] as String? ?? 'pasien';

      if (userRole == 'ahli_gizi') {
        final statusAkun = userData['status_akun'] as String? ?? 'approved';
        if (statusAkun == 'pending') {
          await FirebaseAuth.instance.signOut();
          return {'success': false, 'message': 'PENDING', 'user': userData};
        }
        if (statusAkun == 'rejected') {
          await FirebaseAuth.instance.signOut();
          final reason =
              userData['rejection_reason'] as String? ??
              'Tidak ada keterangan.';
          return {
            'success': false,
            'message': 'REJECTED',
            'rejection_reason': reason,
            'user': userData,
          };
        }
      }

      // Backup session ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      userData['password'] = password;
      await prefs.setString(
        _loggedInUserKey,
        jsonEncode(_makeEncodable(userData)),
      );

      // Poin 9: Cleanup orphaned meal_logs saat login pasien
      // (data dari RM yang sama tapi UID berbeda = warisan user yang sudah dihapus)
      if (userRole == 'pasien') {
        final rm = userData['rm'] as String? ?? '';
        if (rm.isNotEmpty) {
          // Jalankan di background, tidak menunggu
          cleanupOrphanedMealLogs(rm: rm, currentUid: uid).ignore();
        }
      }

      /* debug log removed */
      return {'success': true, 'user': userData, 'role': userRole};
    } on FirebaseAuthException {
      /* debug log removed */
      return {
        'success': false,
        'message': 'Data login (Email/Username/RM/NIP atau Kata Sandi) yang dimasukkan salah, silakan coba lagi.',
      };
    } catch (e) {
      /* debug log removed */
      return {'success': false, 'message': 'Koneksi bermasalah atau server sibuk. Silakan periksa internet Anda dan coba lagi.'};
    }
  }

  // ------------------------------------------------------------------------------------------------------------------------------------------------------------
  // --------- ADMIN: Ambil semua Ahli Gizi untuk verifikasi ---------
  // ------------------------------------------------------------------------------------------------------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> getAllAhliGiziForAdmin({
    String filter = 'all',
  }) async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'ahli_gizi');
      if (filter == 'pending') {
        query = query.where('status_akun', isEqualTo: 'pending');
      } else if (filter == 'approved') {
        query = query.where('status_akun', isEqualTo: 'approved');
      } else if (filter == 'rejected') {
        query = query.where('status_akun', isEqualTo: 'rejected');
      }
      final snap = await query.get();
      return snap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> approveAhliGizi(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'status_akun': 'approved',
        'rejection_reason': '',
        'approved_at': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': uid,
        'role': 'ahli_gizi',
        'title': '🎉 Akun Anda Disetujui!',
        'message':
            'Selamat! Akun Anda telah diverifikasi. Anda sekarang bisa login.',
        'type': 'account_approved',
        'isRead': false,
        'relatedId': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> rejectAhliGizi(
    String uid, {
    required String reason,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'status_akun': 'rejected',
        'rejection_reason': reason,
      });
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': uid,
        'role': 'ahli_gizi',
        'title': '----™ Pendaftaran Ditolak',
        'message': 'Maaf, pendaftaran Anda ditolak. Alasan: $reason',
        'type': 'account_rejected',
        'isRead': false,
        'relatedId': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    static Future<bool> promoteToAdmin(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'role': 'admin',
        'promoted_to_admin_at': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': uid,
        'role': 'admin',
        'title': '👑 Akun Anda Dipromosikan!',
        'message': 'Selamat! Akun Anda telah dipromosikan menjadi Admin.',
        'type': 'role_promoted',
        'isRead': false,
        'relatedId': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
  }) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Link reset kata sandi telah dikirim ke email Anda.',
      };
    } on FirebaseAuthException catch (e) {
      String msg = 'Gagal mengirim email reset.';
      if (e.code == 'user-not-found') msg = 'Email tidak terdaftar.';
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ------------------------------------------------------------------------------------ PROFIL AHLI GIZI ---------------------------------------------------------------------------------------

  static Future<bool> updateAhliGiziProfile({
    required String nip,
    required String name,
    required String phone,
    required String email,
    required String pendidikan,
    required String instansi,
    required String tahunLulus,
    required String pengalamanKerja,
    required String noStr,
    required String spesialisasi,
    String? birthdate, // Opsional: edit tanggal lahir
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final updateData = <String, dynamic>{
        'name': name,
        'phone': phone,
        'email': email,
        'pendidikan': pendidikan,
        'instansi': instansi,
        'tahunLulus': tahunLulus,
        'pengalamanKerja': pengalamanKerja,
        'noStr': noStr,
        'spesialisasi': spesialisasi,
      };
      if (birthdate != null && birthdate.isNotEmpty) {
        updateData['birthdate'] = birthdate;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);

      final prefs = await SharedPreferences.getInstance();
      final freshData =
          (await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get())
              .data();
      if (freshData != null) {
        await prefs.setString(
          _loggedInUserKey,
          jsonEncode(_makeEncodable(freshData)),
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateAhliGiziEmailPassword({
    required String nip,
    required String email,
    String? password,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      if (email.isNotEmpty && email != user.email) {
        await user.verifyBeforeUpdateEmail(email);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'email': email});
      }

      if (password != null && password.isNotEmpty) {
        await user.updatePassword(password);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // ------------------------------------------------------------------------------------ PROFIL PASIEN ------------------------------------------------------------------------------------------------

  static Future<bool> updatePasienProfile({
    required String rm,
    required String name,
    required String username,
    required String phone,
    required String email,
    required String nik,
    required String agama,
    required String alamat,
    required String pendidikan,
    required String pekerjaan,
    String? birthdate, // Opsional: edit tanggal lahir
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final updateData = {
        'name': name,
        'username': username,
        'phone': phone,
        'email': email,
        'nik': nik,
        'agama': agama,
        'alamat': alamat,
        'pendidikan': pendidikan,
        'pekerjaan': pekerjaan,
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (birthdate != null && birthdate.isNotEmpty) {
        updateData['birthdate'] = birthdate;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);

      // Update session local
      final prefs = await SharedPreferences.getInstance();
      final freshData =
          (await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get())
              .data();
      if (freshData != null) {
        await prefs.setString(
          _loggedInUserKey,
          jsonEncode(_makeEncodable(freshData)),
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updatePasienEmailPassword({
    required String rm,
    required String email,
    String? password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) return false;

    final decoded = jsonDecode(usersJson) as List;
    final users = decoded.cast<Map<String, dynamic>>();

    final idx = users.indexWhere((u) => u['rm'] == rm && u['role'] == 'pasien');
    if (idx == -1) return false;

    // Check email unique if changed
    if (email.isNotEmpty && email != users[idx]['email']) {
      final emailExists = users.any((u) => u['email'] == email);
      if (emailExists) return false;
    }

    if (email.isNotEmpty) users[idx]['email'] = email;
    if (password != null && password.isNotEmpty) {
      users[idx]['password'] = password;
    }

    await prefs.setString(_usersKey, jsonEncode(_makeEncodable(users)));

    // Update session if it's the logged in user
    final loggedIn = await getLoggedInUser();
    if (loggedIn != null && loggedIn['rm'] == rm) {
      await prefs.setString(
        _loggedInUserKey,
        jsonEncode(_makeEncodable(users[idx])),
      );
    }
    return true;
  }

  static Future<String?> updateProfilePhoto(
    String id,
    String photoPath,
    bool isPasien,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 'Pengguna tidak terautentikasi';

      final file = File(photoPath);
      if (!file.existsSync()) {
        return 'File gambar tidak ditemukan di perangkat.';
      }

      // 1. Baca file dan ubah ke Base64
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      
      // Pastikan ukuran tidak lebih dari ~800KB (batas Firestore 1MB)
      if (base64String.length > 800000) {
         return 'Ukuran gambar terlalu besar. Silakan pilih gambar yang lebih kecil.';
      }

      // 2. Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'profile_photo_base64': base64String});

      // 3. Update SharedPreferences Session
      final prefs = await SharedPreferences.getInstance();
      
      final freshData =
          (await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get())
              .data();
              
      if (freshData != null) {
        await prefs.setString(
          _loggedInUserKey,
          jsonEncode(_makeEncodable(freshData)),
        );
      }
      
      return null;
    } catch (e) {
      if (e.toString().contains('unauthorized')) {
        return 'Gagal: Akses Firebase Storage ditolak. Pastikan aturan keamanan (Security Rules) Storage Anda mengizinkan upload.';
      }
      return 'Terjadi kesalahan sistem: $e';
    }
  }

  static Future<String?> removeProfilePhoto(bool isPasien) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 'Pengguna tidak terautentikasi';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'profile_photo_base64': FieldValue.delete(),
            'profile_photo_path': FieldValue.delete(),
          });

      final prefs = await SharedPreferences.getInstance();
      
      final freshData =
          (await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get())
              .data();
              
      if (freshData != null) {
        await prefs.setString(
          _loggedInUserKey,
          jsonEncode(_makeEncodable(freshData)),
        );
      }
      
      return null;
    } catch (e) {
      return 'Gagal menghapus foto: $e';
    }
  }

  static Future<void> updatePasienStatus(String rm, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) return;

    final decoded = jsonDecode(usersJson) as List;
    final users = decoded.cast<Map<String, dynamic>>();

    final idx = users.indexWhere(
      (u) => u['rm'].toString().toLowerCase() == rm.toLowerCase(),
    );
    if (idx != -1) {
      users[idx]['status'] = status;
      await prefs.setString(_usersKey, jsonEncode(_makeEncodable(users)));

      final loggedIn = await getLoggedInUser();
      if (loggedIn != null &&
          loggedIn['rm'].toString().toLowerCase() == rm.toLowerCase()) {
        await prefs.setString(
          _loggedInUserKey,
          jsonEncode(_makeEncodable(users[idx])),
        );
      }
    }
  }

  static Future<List<Map<String, dynamic>>> getAllPasien() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'pasien')
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getPasienByAhliGiziNip(
    String nip,
  ) async {
    try {
      if (nip.isEmpty) return [];
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'pasien')
          .where('selected_ahli_gizi_nip', isEqualTo: nip)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getPasienByRm(String rm) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('rm', isEqualTo: rm)
          .where('role', isEqualTo: 'pasien')
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ------------------------------------------------------------------------------------ UPDATE PASIEN BB/TB ---------------------------------------------------------------------------------

  static Future<bool> updatePasienBBTB(
    String rm,
    double weight,
    double height,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final updateData = {
        'weight': weight,
        'height': height,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);

      // Update session local
      final prefs = await SharedPreferences.getInstance();
      final freshData =
          (await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get())
              .data();
      if (freshData != null) {
        await prefs.setString(
          _loggedInUserKey,
          jsonEncode(_makeEncodable(freshData)),
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // ------------------------------------------------------------------------------ PILIH AHLI GIZI & DIET ---------------------------------------------------------------------------------

  static Future<bool> selectAhliGizi(
    String rmPasien,
    String nipAhliGizi,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('rm', isEqualTo: rmPasien)
          .where('role', isEqualTo: 'pasien')
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          'ahli_gizi_nip': nipAhliGizi,
          'selected_ahli_gizi_nip': nipAhliGizi,
        });

        // Update local session
        final prefs = await SharedPreferences.getInstance();
        final user = await getLoggedInUser();
        if (user != null &&
            user['rm'].toString().toLowerCase() == rmPasien.toLowerCase()) {
          user['ahli_gizi_nip'] = nipAhliGizi;
          user['selected_ahli_gizi_nip'] = nipAhliGizi;
          await prefs.setString(
            _loggedInUserKey,
            jsonEncode(_makeEncodable(user)),
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateDietType(String rmPasien, String dietType) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('rm', isEqualTo: rmPasien)
          .where('role', isEqualTo: 'pasien')
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          'diet_type': dietType,
          'diet_types': [dietType],
        });

        // Update local session
        final prefs = await SharedPreferences.getInstance();
        final user = await getLoggedInUser();
        if (user != null &&
            user['rm'].toString().toLowerCase() == rmPasien.toLowerCase()) {
          user['diet_type'] = dietType;
          user['diet_types'] = [dietType];
          await prefs.setString(
            _loggedInUserKey,
            jsonEncode(_makeEncodable(user)),
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getSelectedAhliGizi(
    String rmPasien,
  ) async {
    final pasien = await getPasienByRm(rmPasien);
    if (pasien == null) return null;

    final nipAhliGizi = pasien['selected_ahli_gizi_nip'];
    if (nipAhliGizi == null) return null;

    final allAhliGizi = await getAllAhliGizi();
    try {
      return allAhliGizi.firstWhere((ag) => ag['nip'] == nipAhliGizi);
    } catch (_) {
      return null;
    }
  }

  // ------------------------------------------------------------------------------------ MEAL LOGS ------------------------------------------------------------------------------------------------------------

  static const String _mealLogsKey = 'meal_logs';

  static Future<Map<String, dynamic>?> getMealLogForDate(
    String rmPasien,
    DateTime date,
  ) async {
    try {
      final dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final docId = '${rmPasien}_$dateString';

      final doc = await FirebaseFirestore.instance
          .collection('meal_logs')
          .doc(docId)
          .get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getMealLogsForPasien(
    String rmPasien, {
    int days = 30,
    String? ownerUid, // Poin 9: filter by owner UID untuk skip orphaned data
  }) async {
    try {
      // Query HANYA by rm_pasien (single-field index, always available)
      // Filter tanggal dilakukan di Dart untuk menghindari composite index
      final snapshot = await FirebaseFirestore.instance
          .collection('meal_logs')
          .where('rm_pasien', isEqualTo: rmPasien)
          .limit(90) // ambil max 90 log terakhir
          .get()
          .timeout(const Duration(seconds: 10));

      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final result = snapshot.docs.map((doc) => doc.data()).where((log) {
        final dateStr = log['date'] as String? ?? '';
        if (dateStr.isEmpty) return true; // sertakan jika tidak ada tanggal
        final logDate = DateTime.tryParse(dateStr);
        if (logDate == null || !logDate.isAfter(cutoffDate)) return false;
        // Poin 9: Jika ownerUid diberikan, skip log yang user_id-nya berbeda
        if (ownerUid != null) {
          final logUid = log['user_id'] as String? ?? log['uid'] as String? ?? '';
          if (logUid.isNotEmpty && logUid != ownerUid) return false;
        }
        return true;
      }).toList();

      result.sort(
        (a, b) =>
            (b['date'] as String? ?? '').compareTo(a['date'] as String? ?? ''),
      );
      return result;
    } catch (e) {
      return [];
    }
  }

  /// Poin 9: Cleanup orphaned meal_logs dari RM yang sama tapi UID berbeda
  /// Dipanggil saat user pertama kali login agar tidak mewarisi data user lama
  static Future<void> cleanupOrphanedMealLogs({
    required String rm,
    required String currentUid,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('meal_logs')
          .where('rm_pasien', isEqualTo: rm)
          .limit(100)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      int deleteCount = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final logUid = data['user_id'] as String? ?? data['uid'] as String? ?? '';
        // Hapus log yang UID-nya berbeda dari user saat ini
        if (logUid.isNotEmpty && logUid != currentUid) {
          batch.delete(doc.reference);
          deleteCount++;
        }
      }
      if (deleteCount > 0) {
        await batch.commit();
      }
    } catch (_) {
      // Gagal cleanup tidak menghalangi proses login
    }
  }

  // ------------------------------------------------------------------------------------ SESSION ------------------------------------------------------------------------------------------------------------------

  static Future<Map<String, dynamic>?> getLoggedInUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();

    // Jika di Firebase tidak ada user, pastikan session lokal juga kosong
    if (firebaseUser == null) {
      await prefs.remove(_loggedInUserKey);
      return null;
    }

    final userJson = prefs.getString(_loggedInUserKey);
    if (userJson == null) {
      // Jika di Firebase ada tapi di lokal kosong, ambil ulang dari Firestore
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .get()
            .timeout(const Duration(seconds: 10));
        if (doc.exists) {
          final userData = doc.data()!;
          await prefs.setString(
            _loggedInUserKey,
            jsonEncode(_makeEncodable(userData)),
          );
          return userData;
        }
      } catch (e) {
        /* debug log removed */
      }
      return null;
    }

    final localUser = jsonDecode(userJson) as Map<String, dynamic>;
    // Pastikan UID lokal sama dengan UID Firebase
    if (localUser['uid'] != firebaseUser.uid) {
      await prefs.remove(_loggedInUserKey);
      return null;
    }

    return localUser;
  }

  static Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInUserKey);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_loggedInUserKey);
  }

  static Future<String?> getRole() async {
    final user = await getLoggedInUser();
    return user?['role'] as String?;
  }

  static Future<bool> saveTargetDietPasien({
    required String rm,
    required String targetDiet,
    required String catatanEvaluasi,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('rm', isEqualTo: rm)
          .where('role', isEqualTo: 'pasien')
          .get();
      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          'target_diet': targetDiet,
          'catatan_evaluasi': catatanEvaluasi,
        });

        // Update session lokal jika sedang login dengan akun tersebut
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final prefs = await SharedPreferences.getInstance();
          final loggedInJson = prefs.getString(_loggedInUserKey);
          if (loggedInJson != null) {
            final loggedIn = jsonDecode(loggedInJson);
            if (loggedIn['rm'].toString().toLowerCase() == rm.toLowerCase()) {
              loggedIn['target_diet'] = targetDiet;
              loggedIn['catatan_evaluasi'] = catatanEvaluasi;
              await prefs.setString(
                _loggedInUserKey,
                jsonEncode(_makeEncodable(loggedIn)),
              );
            }
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ------------------------------------------------------------------------------------ MULTI-DIET ---------------------------------------------------------------------------------------------------------

  static Future<bool> updateDietTypes(
    String rmPasien,
    List<String> dietTypes,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('rm', isEqualTo: rmPasien)
          .where('role', isEqualTo: 'pasien')
          .get();
      if (snapshot.docs.isNotEmpty) {
        final dietTypeString = dietTypes.isNotEmpty ? dietTypes.join(', ') : '';
        await snapshot.docs.first.reference.update({
          'diet_types': dietTypes,
          'diet_type': dietTypeString,
        });

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final prefs = await SharedPreferences.getInstance();
          final loggedInJson = prefs.getString(_loggedInUserKey);
          if (loggedInJson != null) {
            final loggedIn = jsonDecode(loggedInJson);
            if (loggedIn['rm'].toString().toLowerCase() ==
                rmPasien.toLowerCase()) {
              loggedIn['diet_types'] = dietTypes;
              loggedIn['diet_type'] = dietTypeString;
              await prefs.setString(
                _loggedInUserKey,
                jsonEncode(_makeEncodable(loggedIn)),
              );
            }
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static List<String> getDietTypesList(Map<String, dynamic> pasien) {
    final raw = pasien['diet_types'];
    if (raw is List) return raw.cast<String>();
    final single = pasien['diet_type'] as String? ?? '';
    return single.isEmpty ? [] : [single];
  }

  // ------------------------------------------------------------------------------------ INFORM CONSENT ---------------------------------------------------------------------------------------------

  static Future<bool> saveInformConsent(
    String rm,
    String signaturePath, {
    String? signatureBase64,
    String? consentDocBase64,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('rm', isEqualTo: rm)
          .where('role', isEqualTo: 'pasien')
          .get();
      if (snapshot.docs.isNotEmpty) {
        final updateData = <String, dynamic>{
          'inform_consent_signed': true,
          'consent_signature_path': signaturePath,
          'consent_signed_at': DateTime.now().toIso8601String(),
        };

        if (signatureBase64 != null && signatureBase64.isNotEmpty) {
          updateData['consent_signature_base64'] = signatureBase64;
        }
        if (consentDocBase64 != null && consentDocBase64.isNotEmpty) {
          updateData['consent_doc_base64'] = consentDocBase64;
        }

        await snapshot.docs.first.reference.update(updateData);

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final prefs = await SharedPreferences.getInstance();
          final loggedInJson = prefs.getString(_loggedInUserKey);
          if (loggedInJson != null) {
            final loggedIn = jsonDecode(loggedInJson);
            if (loggedIn['rm'].toString().toLowerCase() == rm.toLowerCase()) {
              loggedIn.addAll(updateData);
              await prefs.setString(
                _loggedInUserKey,
                jsonEncode(_makeEncodable(loggedIn)),
              );
            }
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static bool isConsentSigned(Map<String, dynamic>? user) {
    return user?['inform_consent_signed'] == true;
  }

  // ------------------------------------------------------------------------------------ BB/TB HISTORY ------------------------------------------------------------------------------------------------

  static Future<bool> updateBBTBWithHistory(
    String rm,
    double weight,
    double height,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('rm', isEqualTo: rm)
          .where('role', isEqualTo: 'pasien')
          .get();
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();

        final history = (data['bb_history'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        history.insert(0, {
          'weight': weight,
          'height': height,
          'recorded_at': DateTime.now().toIso8601String(),
        });
        final updatedHistory = history.take(30).toList();

        await doc.reference.update({
          'weight': weight,
          'height': height,
          'bb_history': updatedHistory,
        });

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final prefs = await SharedPreferences.getInstance();
          final loggedInJson = prefs.getString(_loggedInUserKey);
          if (loggedInJson != null) {
            final loggedIn = jsonDecode(loggedInJson);
            if (loggedIn['rm'].toString().toLowerCase() == rm.toLowerCase()) {
              loggedIn['weight'] = weight;
              loggedIn['height'] = height;
              loggedIn['bb_history'] = updatedHistory;
              await prefs.setString(_loggedInUserKey, jsonEncode(loggedIn));
            }
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static List<Map<String, dynamic>> getBBTBHistory(
    Map<String, dynamic> pasien,
  ) {
    final raw = pasien['bb_history'];
    if (raw is List) return raw.cast<Map<String, dynamic>>();
    return [];
  }

  // ------------------------------------------------------------------------------------ NUTRISI (6 KOMPONEN) ---------------------------------------------------------------------------

  // ------------ Nutrisi per Jenis Diet (NEW) ---------------------------------------------------------------------------------------------------------------------------

  static Future<bool> saveNutrisiPerDiet({
    required String rmPasien,
    required String dietType,
    required Map<String, dynamic> targetNutrients,
    Map<String, dynamic>? aktualNutrients,
    String catatan = '',
    String evaluasiAhliGizi = '',
  }) async {
    try {
      final docId = '${rmPasien}_${dietType.replaceAll(' ', '_')}';

      Map<String, dynamic> cleanTargets = {};
      targetNutrients.forEach((key, value) {
        final targetVal = (value['target'] as num?)?.toDouble() ?? 0.0;
        final aktualVal = aktualNutrients != null
            ? (aktualNutrients[key] as num?)?.toDouble() ?? 0.0
            : (value['aktual'] as num?)?.toDouble() ?? 0.0;
        cleanTargets[key] = {'target': targetVal, 'aktual': aktualVal};
      });

      final data = {
        'rm_pasien': rmPasien,
        'diet_type': dietType,
        'target_nutrients': cleanTargets,
        'catatan': catatan,
        'evaluasi_ahli_gizi': evaluasiAhliGizi,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance
          .collection('nutrition_plans')
          .doc(docId)
          .set(data);

      // Save to history too
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final historyId = '${rmPasien}_${dietType.replaceAll(' ', '_')}_$dateKey';

      final historyData = Map<String, dynamic>.from(data);
      historyData['date'] = dateKey;

      await FirebaseFirestore.instance
          .collection('nutrition_history')
          .doc(historyId)
          .set(historyData);

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getNutrisiHistoryForDate(
    String rmPasien,
    String dietType,
    String dateKey,
  ) async {
    try {
      final historyId = '${rmPasien}_${dietType.replaceAll(' ', '_')}_$dateKey';
      final doc = await FirebaseFirestore.instance
          .collection('nutrition_history')
          .doc(historyId)
          .get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getNutrisiHistoryForMonth(
    String rmPasien,
    int month,
    int year,
  ) async {
    try {
      // Query hanya by rm_pasien, filter tanggal di Dart
      final snapshot = await FirebaseFirestore.instance
          .collection('nutrition_history')
          .where('rm_pasien', isEqualTo: rmPasien)
          .limit(60)
          .get();

      final prefix = '$year-${month.toString().padLeft(2, '0')}';
      return snapshot.docs
          .map((doc) => doc.data())
          .where((d) => (d['date'] as String? ?? '').startsWith(prefix))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getLatestNutritionPlan(String rm) async {
    final all = await getAllNutrisiPasien(rm);
    if (all.isEmpty) return null;

    // Sort by updated_at descending
    all.sort((a, b) {
      final dateA = DateTime.tryParse(a['updated_at'] ?? '') ?? DateTime(2000);
      final dateB = DateTime.tryParse(b['updated_at'] ?? '') ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

    return all.first;
  }

  static Future<List<Map<String, dynamic>>> getAllNutrisiPasien(
    String rmPasien,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('nutrition_plans')
          .where('rm_pasien', isEqualTo: rmPasien)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getNutrisiPasienPerDiet(
    String rmPasien,
    String dietType,
  ) async {
    final all = await getAllNutrisiPasien(rmPasien);
    try {
      return all.firstWhere((n) => n['diet_type'] == dietType);
    } catch (_) {
      return null;
    }
  }

  // ------------ Nutrisi global (legacy, backward compat) ------------------------------------------------------------------------------------------

  static Future<bool> updateClinicalData({
    required String rm,
    required String diagnosis,
    required String catatanKlinis,
    String? terapiDiet,
  }) async {
    try {
      // 1. Update in Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('rm', isEqualTo: rm)
          .where('role', isEqualTo: 'pasien')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final docRef = snapshot.docs.first.reference;
        final Map<String, dynamic> updateData = {
          'diagnosis': diagnosis,
          'catatan_klinis': catatanKlinis,
          'updated_at': FieldValue.serverTimestamp(),
        };
        if (terapiDiet != null) {
          updateData['diet_type'] = terapiDiet;
        }
        await docRef.update(updateData);
      }

      // 2. Update locally in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_usersKey);
      if (json != null) {
        final decoded = jsonDecode(json) as List;
        final list = decoded.cast<Map<String, dynamic>>();
        final idx = list.indexWhere(
          (u) => u['role'] == 'pasien' && u['rm'] == rm,
        );

        if (idx != -1) {
          list[idx]['diagnosis'] = diagnosis;
          list[idx]['catatan_klinis'] = catatanKlinis;
          if (terapiDiet != null) {
            list[idx]['diet_type'] = terapiDiet;
          }
          await prefs.setString(_usersKey, jsonEncode(_makeEncodable(list)));
        }
      }

      final current = await getLoggedInUser();
      if (current != null && current['rm'] == rm) {
        current['diagnosis'] = diagnosis;
        current['catatan_klinis'] = catatanKlinis;
        if (terapiDiet != null) current['diet_type'] = terapiDiet;
        await prefs.setString(
          _loggedInUserKey,
          jsonEncode(_makeEncodable(current)),
        );
      }
      return true;
    } catch (e) {
      /* debug log removed */
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getNutrisiPasien(String rmPasien) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('nutrition_plans')
          .where('rm_pasien', isEqualTo: rmPasien)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ------------------------------------------------------------------------------------ DROPOUT DETECTION ------------------------------------------------------------------------------------

  static Future<List<Map<String, dynamic>>> getDropoutPasien() async {
    final allPasien = await getAllPasien();
    final prefs = await SharedPreferences.getInstance();
    final logsJson = prefs.getString(_mealLogsKey);
    List<Map<String, dynamic>> logs = [];
    if (logsJson != null) {
      logs = (jsonDecode(logsJson) as List).cast<Map<String, dynamic>>();
    }
    final dropouts = <Map<String, dynamic>>[];
    final now = DateTime.now();
    for (final pasien in allPasien) {
      final rm = pasien['rm'] as String? ?? '';
      if ((pasien['status'] ?? 'aktif') != 'aktif') continue;
      final pasienLogs = logs.where((l) => l['rm_pasien'] == rm).toList();
      if (pasienLogs.isEmpty) {
        // Check if registered more than 3 days ago
        continue;
      }
      int consecutive = 0;
      for (int i = 1; i <= 3; i++) {
        final checkDate = now.subtract(Duration(days: i));
        final dateStr = '${checkDate.year}-${checkDate.month}-${checkDate.day}';
        final hasLog = pasienLogs.any(
          (l) => l['date'].toString().startsWith(dateStr),
        );
        if (!hasLog) {
          consecutive++;
        } else {
          break;
        }
      }
      if (consecutive >= 3) {
        dropouts.add({...pasien, 'consecutive_missed': consecutive});
      }
    }
    return dropouts;
  }

  // ------------------------------------------------------------------------------------ HASIL LAB ------------------------------------------------------------------------------------------------------------

  static const String _labKey = 'hasil_lab';

  static Future<bool> saveHasilLab({
    required String rmPasien,
    required Map<String, dynamic> labData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_labKey);
    List<Map<String, dynamic>> list = [];
    if (json != null) {
      final decoded = jsonDecode(json) as List;
      list = decoded.cast<Map<String, dynamic>>();
    }
    list.removeWhere((l) => l['rm_pasien'] == rmPasien);
    list.add({
      'rm_pasien': rmPasien,
      ...labData,
      'updated_at': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_labKey, jsonEncode(list));
    return true;
  }

  static Future<Map<String, dynamic>?> getHasilLab(String rmPasien) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_labKey);
    if (json == null) return null;
    final decoded = jsonDecode(json) as List;
    final list = decoded.cast<Map<String, dynamic>>();
    try {
      return list.firstWhere((l) => l['rm_pasien'] == rmPasien);
    } catch (_) {
      return null;
    }
  }

  // ------------------------------------------------------------------------------------ MEAL LOG (dengan JAM) ------------------------------------------------------------------------

  static Future<bool> saveMealLog({
    required String rmPasien,
    required String mealPagi,
    required String selinganPagi,
    required String mealSiang,
    required String selinganSore,
    required String mealMalam,
    String? dietType,
    double? beratBadan,
    double? tinggiBadan,
    String? jamPagi,
    String? jamSelinganPagi,
    String? jamSiang,
    String? jamSelinganSore,
    String? jamMalam,
    String? date,
    String? patientProgramId,
  }) async {
    try {
      final today = date != null ? DateTime.parse(date) : DateTime.now();
      final dateString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final docId = '${rmPasien}_$dateString';

      final logData = {
        'id': docId,
        'rm_pasien': rmPasien,
        'date': today.toIso8601String(),
        'meal_pagi': mealPagi,
        'selingan_pagi': selinganPagi,
        'meal_siang': mealSiang,
        'selingan_sore': selinganSore,
        'meal_malam': mealMalam,
        'jam_pagi': jamPagi ?? '',
        'jam_selingan_pagi': jamSelinganPagi ?? '',
        'jam_siang': jamSiang ?? '',
        'jam_selingan_sore': jamSelinganSore ?? '',
        'jam_malam': jamMalam ?? '',
        'diet_type': dietType ?? '',
        'berat_badan': beratBadan,
        'tinggi_badan': tinggiBadan,
        'patientProgramId': patientProgramId ?? '',
        'created_at': today.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance
          .collection('meal_logs')
          .doc(docId)
          .set(logData, SetOptions(merge: true));
      return true;
    } catch (e) {
      return false;
    }
  }

  // ------------------------------------------------------------------------------------ KELOLA JENIS DIET (FIRESTORE) ------------------------------------------------------

  static Future<List<Map<String, dynamic>>> getDietTypes() async {
    try {
      /* debug log removed */
      final snapshot = await FirebaseFirestore.instance
          .collection('diet_reference')
          .get();

      /* debug log removed */
      return snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      /* debug log removed */
      return [];
    }
  }

  static Stream<List<Map<String, dynamic>>> streamDietTypes() {
    return FirebaseFirestore.instance
        .collection('diet_reference')
        .orderBy('title')
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  static Future<bool> addDietType({
    required String title,
    required String pdfUrl,
    int? iconCodePoint,
    int? colorValue,
  }) async {
    try {
      final docId = title
          .toLowerCase()
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[^a-z0-9_]'), '');
      await FirebaseFirestore.instance
          .collection('diet_reference')
          .doc(docId)
          .set({
            'title': title,
            'pdfUrl': pdfUrl,
            'iconCodePoint': iconCodePoint ?? Icons.article_outlined.codePoint,
            'colorValue': colorValue ?? 0xFFDBEAFE,
            'created_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> deleteDietType(String title) async {
    try {
      // Cek apakah sedang dipakai pasien di Firestore
      final usedCheck = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'pasien')
          .where('diet_types', arrayContains: title)
          .get();
      if (usedCheck.docs.isNotEmpty) {
        return {
          'success': false,
          'message':
              'Program terapi diet ini sedang digunakan oleh pasien dan tidak dapat dihapus.',
        };
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('diet_reference')
          .where('title', isEqualTo: title)
          .get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      return {
        'success': true,
        'message': 'Program terapi diet berhasil dihapus.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ------------------------------------------------------------------------------------ KELOLA LEAFLET (FIRESTORE) ---------------------------------------------------------------

  static Future<List<Map<String, dynamic>>> getLeaflets() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('leaflets')
          .orderBy('title')
          .get();
      return snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      return [];
    }
  }

  static Stream<List<Map<String, dynamic>>> streamLeaflets() {
    return FirebaseFirestore.instance
        .collection('leaflets')
        .orderBy('title')
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  static Future<bool> addLeaflet(Map<String, dynamic> leaflet) async {
    try {
      final title = leaflet['title'] as String? ?? '';
      final docId = title
          .toLowerCase()
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[^a-z0-9_]'), '');
      await FirebaseFirestore.instance
          .collection('leaflet_reference')
          .doc(docId)
          .set({
            ...leaflet,
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteLeaflet(String title) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('leaflet_reference')
          .where('title', isEqualTo: title)
          .get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // ------------ KELOLA PROGRAM TERAPI DIET & LEAFLET (KYOKU) ------------

  static Future<List<Map<String, dynamic>>> getTherapyPrograms() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('therapy_programs')
          .orderBy('name')
          .get();
      return snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (_) {
      return [];
    }
  }

  static Stream<List<Map<String, dynamic>>> streamTherapyPrograms() {
    return FirebaseFirestore.instance
        .collection('therapy_programs')
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  static Future<List<Map<String, dynamic>>> getNewLeaflets() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('leaflets')
          .orderBy('title')
          .get();
      return snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (_) {
      return [];
    }
  }

  static Stream<List<Map<String, dynamic>>> streamNewLeaflets() {
    return FirebaseFirestore.instance
        .collection('leaflets')
        .orderBy('title')
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  static Future<List<Map<String, dynamic>>> getArticles() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('articles')
          .orderBy('created_at', descending: true)
          .get();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> addArticle({
    required String title,
    required String category,
    required String content,
  }) async {
    try {
      final articleId = title
          .toLowerCase()
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[^a-z0-9_]'), '');
          
      int colorVal = 0xFFDBEAFE;
      int iconCode = Icons.article.codePoint;
      
      switch (category.toLowerCase()) {
        case 'nutrisi':
          colorVal = 0xFFD1FAE5;
          iconCode = Icons.restaurant.codePoint;
          break;
        case 'olahraga':
          colorVal = 0xFFDBEAFE;
          iconCode = Icons.fitness_center.codePoint;
          break;
        case 'psikologi':
          colorVal = 0xFFFCE7F3;
          iconCode = Icons.self_improvement.codePoint;
          break;
      }

      await FirebaseFirestore.instance.collection('articles').doc(articleId).set({
        'title': title,
        'category': category,
        'content': content,
        'colorVal': colorVal,
        'iconCode': iconCode,
        'created_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> updateArticle(
    String id, {
    required String title,
    required String category,
    required String content,
  }) async {
    try {
      int colorVal = 0xFFDBEAFE;
      int iconCode = Icons.article.codePoint;
      
      switch (category.toLowerCase()) {
        case 'nutrisi':
          colorVal = 0xFFD1FAE5;
          iconCode = Icons.restaurant.codePoint;
          break;
        case 'olahraga':
          colorVal = 0xFFDBEAFE;
          iconCode = Icons.fitness_center.codePoint;
          break;
        case 'psikologi':
          colorVal = 0xFFFCE7F3;
          iconCode = Icons.self_improvement.codePoint;
          break;
      }

      await FirebaseFirestore.instance.collection('articles').doc(id).update({
        'title': title,
        'category': category,
        'content': content,
        'colorVal': colorVal,
        'iconCode': iconCode,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteArticle(String id) async {
    try {
      await FirebaseFirestore.instance.collection('articles').doc(id).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> addTherapyProgramAndLeaflet({
    required String programName,
    required String programDesc,
    required String programPurpose,
    required String programNotes,
    required String leafletTitle,
    required String leafletContent,
    String? leafletUrl,
  }) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // 1. Cek duplikasi nama program
      final existing = await FirebaseFirestore.instance
          .collection('therapy_programs')
          .where('name', isEqualTo: programName)
          .get();
      if (existing.docs.isNotEmpty) return false;

      final programId = programName
          .toLowerCase()
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[^a-z0-9_]'), '');
      final programRef = FirebaseFirestore.instance
          .collection('therapy_programs')
          .doc(programId);

      batch.set(programRef, {
        'name': programName,
        'description': programDesc,
        'purpose': programPurpose,
        'notes': programNotes,
        'pdfUrl': leafletUrl ?? '',
        'iconCode': Icons.restaurant_menu_outlined.codePoint,
        'colorVal': 0xFFDBEAFE,
        'created_at': FieldValue.serverTimestamp(),
      });

      // 2. Simpan Leaflet
      final leafletId = leafletTitle
          .toLowerCase()
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[^a-z0-9_]'), '');
      final leafletRef = FirebaseFirestore.instance
          .collection('leaflets')
          .doc(leafletId);

      batch.set(leafletRef, {
        'programId': programId,
        'programName': programName,
        'title': leafletTitle,
        'content': leafletContent,
        'url': leafletUrl ?? '',
        'created_at': FieldValue.serverTimestamp(),
        // Mapping compatibility for old views
        'desc': leafletContent.length > 50
            ? '${leafletContent.substring(0, 50)}...'
            : leafletContent,
        'category': 'Terapi Diet',
        'iconCode': Icons.article_outlined.codePoint,
        'colorVal': 0xFFDBEAFE,
      });

      await batch.commit();
      return true;
    } catch (e) {
      /* debug log removed */
      return false;
    }
  }

  static Future<bool> deleteTherapyProgram(String programId) async {
    try {
      // 1. Delete program
      await FirebaseFirestore.instance
          .collection('therapy_programs')
          .doc(programId)
          .delete();

      // 2. Delete associated leaflets
      final leaflets = await FirebaseFirestore.instance
          .collection('leaflets')
          .where('programId', isEqualTo: programId)
          .get();
      final chunks = <List<QueryDocumentSnapshot>>[];
      var i = 0;
      while (i < leaflets.docs.length) {
        chunks.add(leaflets.docs.sublist(
            i,
            i + 500 > leaflets.docs.length
                ? leaflets.docs.length
                : i + 500));
        i += 500;
      }
      
      for (var chunk in chunks) {
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in chunk) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // ------------------------------------------------------------------------------------ INISIALISASI DATA AWAL ---------------------------------------------------------------------

  static Future<String?> forceUpdateAppData() async {
    try {
      /* debug log removed */
      final batch = FirebaseFirestore.instance.batch();
      final dietRef = FirebaseFirestore.instance.collection('diet_reference');
      final leafletRef = FirebaseFirestore.instance.collection(
        'leaflet_reference',
      );

      /* debug log removed */

      final List<Map<String, dynamic>> initialDiets = [
        {
          'title': 'Makanan Sehat Ibu Hamil',
          'pdfUrl':
              'https://drive.google.com/file/d/1DtEIRBLioGTeehUTETRn2dlWY8QjWNoO/view?usp=sharing',
          'iconCodePoint': Icons.pregnant_woman_outlined.codePoint,
          'colorValue': 0xFFFCE7F3,
        },
        {
          'title': 'Makanan Sehat Ibu Menyusui',
          'pdfUrl':
              'https://drive.google.com/file/d/16Uesv76NVgnZ5DPtjAJOkAFpFPxtgb8V/view?usp=sharing',
          'iconCodePoint': Icons.favorite_border.codePoint,
          'colorValue': 0xFFFCE7F3,
        },
        {
          'title': 'Makanan Sehat Bayi',
          'pdfUrl':
              'https://drive.google.com/file/d/1u1EYyFS-gOVI-aiHTcz8VWbgs-qzdheX/view?usp=sharing',
          'iconCodePoint': Icons.child_care_outlined.codePoint,
          'colorValue': 0xFFD1FAE5,
        },
        {
          'title': 'Makanan Sehat Anak Balita',
          'pdfUrl':
              'https://drive.google.com/file/d/1Fl9rdfVJFzf3G-kChGXHHVcx0XQ3Z67y/view?usp=sharing',
          'iconCodePoint': Icons.child_friendly_outlined.codePoint,
          'colorValue': 0xFFD1FAE5,
        },
        {
          'title': 'Makanan Sehat Lansia',
          'pdfUrl':
              'https://drive.google.com/file/d/13yRFdbNbAT6X-e6cvG1xdmGzFqej1BQo/view?usp=sharing',
          'iconCodePoint': Icons.elderly_outlined.codePoint,
          'colorValue': 0xFFFEF3C7,
        },
        {
          'title': 'Makanan Sehat Jemaah Haji',
          'pdfUrl':
              'https://drive.google.com/file/d/1SdpV1JQwBQw58c2WyUIPzcbqCtgKRX5X/view?usp=sharing',
          'iconCodePoint': Icons.mosque_outlined.codePoint,
          'colorValue': 0xFFFEF3C7,
        },
        {
          'title': 'Diet Hati',
          'pdfUrl':
              'https://drive.google.com/file/d/1AWJyvHUsXiTSaXB4vJWRV8DuVueeg-11/view?usp=sharing',
          'iconCodePoint': Icons.monitor_heart_outlined.codePoint,
          'colorValue': 0xFFDBEAFE,
        },
        {
          'title': 'Diet Lambung',
          'pdfUrl':
              'https://drive.google.com/file/d/1gTHCfYnHRpMWlzDg2Fpn174_amfBPB78/view?usp=sharing',
          'iconCodePoint': Icons.medical_services_outlined.codePoint,
          'colorValue': 0xFFDBEAFE,
        },
        {
          'title': 'Diet Jantung',
          'pdfUrl':
              'https://drive.google.com/file/d/1AMmx0UVPXAi-rWn5MdANHgVCz3AjnfE9/view?usp=sharing',
          'iconCodePoint': Icons.favorite_outlined.codePoint,
          'colorValue': 0xFFFCE7F3,
        },
        {
          'title': 'Diet Penyakit Ginjal Kronik',
          'pdfUrl':
              'https://drive.google.com/file/d/1ULJ2xjXQVqhIL-uwzgyYMbPxGXSJdVbg/view?usp=sharing',
          'iconCodePoint': Icons.water_drop_outlined.codePoint,
          'colorValue': 0xFFDBEAFE,
        },
        {
          'title': 'Diet Garam Rendah',
          'pdfUrl':
              'https://drive.google.com/file/d/1ILDn0y04uS0pbgugZyKKGiQ5pXUQY6ET/view?usp=sharing',
          'iconCodePoint': Icons.no_meals_outlined.codePoint,
          'colorValue': 0xFFDBEAFE,
        },
        {
          'title': 'Diet Diabetes Melitus',
          'pdfUrl':
              'https://drive.google.com/file/d/1rPTX_FR46-CaYOZN-lT-2GwE-ExiKpxY/view?usp=sharing',
          'iconCodePoint': Icons.bloodtype_outlined.codePoint,
          'colorValue': 0xFFFEF3C7,
        },
        {
          'title': 'Diet Diabetes Melitus Saat Puasa',
          'pdfUrl':
              'https://drive.google.com/file/d/1WU8gTXow_V4wuPQEjSFZhZ95BA5A4m0h/view?usp=sharing',
          'iconCodePoint': Icons.no_food_outlined.codePoint,
          'colorValue': 0xFFFEF3C7,
        },
        {
          'title': 'Diet Energi Rendah',
          'pdfUrl':
              'https://drive.google.com/file/d/16aiV08zXHsS_275djT5MXlo6n8aopqVy/view?usp=sharing',
          'iconCodePoint': Icons.local_fire_department_outlined.codePoint,
          'colorValue': 0xFFFEF3C7,
        },
        {
          'title': 'Diet Purin Rendah',
          'pdfUrl':
              'https://drive.google.com/file/d/1D_dhoFxw8ZoK8sYBcCaKrMZsr_k0R2ZL/view?usp=sharing',
          'iconCodePoint': Icons.science_outlined.codePoint,
          'colorValue': 0xFFFEF3C7,
        },
        {
          'title': 'Diet Protein Rendah',
          'pdfUrl':
              'https://drive.google.com/file/d/1pUfHw-KGuJGi64ujMwzAHwtZyBi-WXUK/view?usp=sharing',
          'iconCodePoint': Icons.egg_outlined.codePoint,
          'colorValue': 0xFFEDE9FE,
        },
        {
          'title': 'Diet Lemak Rendah',
          'pdfUrl':
              'https://drive.google.com/file/d/1QREic6oki2pyC2xFQ5Qvulx0-UvTXCm-/view?usp=sharing',
          'iconCodePoint': Icons.oil_barrel_outlined.codePoint,
          'colorValue': 0xFFEDE9FE,
        },
        {
          'title': 'Diet Kekebalan Tubuh Menurun',
          'pdfUrl':
              'https://drive.google.com/file/d/1oDCEedQNVE-FRyhAXIvky7cHmIWuTnhZ/view?usp=sharing',
          'iconCodePoint': Icons.shield_outlined.codePoint,
          'colorValue': 0xFFEDE9FE,
        },
      ];

      final List<Map<String, dynamic>> initialLeaflets = [
        {
          'title': 'Makanan Sehat Ibu Hamil',
          'desc':
              'Panduan nutrisi lengkap untuk ibu hamil demi kesehatan ibu dan janin',
          'category': 'Ibu & Anak',
          'url':
              'https://drive.google.com/file/d/1DtEIRBLioGTeehUTETRn2dlWY8QjWNoO/view?usp=sharing',
          'iconCode': Icons.pregnant_woman_outlined.codePoint,
          'colorVal': 0xFFFCE7F3,
        },
        {
          'title': 'Makanan Sehat Ibu Menyusui',
          'desc':
              'Kebutuhan gizi ibu menyusui untuk mendukung produksi ASI berkualitas',
          'category': 'Ibu & Anak',
          'url':
              'https://drive.google.com/file/d/16Uesv76NVgnZ5DPtjAJOkAFpFPxtgb8V/view?usp=sharing',
          'iconCode': Icons.favorite_border.codePoint,
          'colorVal': 0xFFFCE7F3,
        },
        {
          'title': 'Makanan Sehat Bayi',
          'desc':
              'Pemberian MPASI yang tepat untuk tumbuh kembang bayi optimal',
          'category': 'Ibu & Anak',
          'url':
              'https://drive.google.com/file/d/1u1EYyFS-gOVI-aiHTcz8VWbgs-qzdheX/view?usp=sharing',
          'iconCode': Icons.child_care_outlined.codePoint,
          'colorVal': 0xFFD1FAE5,
        },
        {
          'title': 'Makanan Sehat Anak Balita',
          'desc':
              'Panduan gizi untuk anak usia 1-5 tahun agar tumbuh sehat dan cerdas',
          'category': 'Ibu & Anak',
          'url':
              'https://drive.google.com/file/d/1Fl9rdfVJFzf3G-kChGXHHVcx0XQ3Z67y/view?usp=sharing',
          'iconCode': Icons.child_friendly_outlined.codePoint,
          'colorVal': 0xFFD1FAE5,
        },
        {
          'title': 'Makanan Sehat Lansia',
          'desc':
              'Kebutuhan nutrisi khusus untuk menjaga kualitas hidup di usia lanjut',
          'category': 'Gizi Khusus',
          'url':
              'https://drive.google.com/file/d/13yRFdbNbAT6X-e6cvG1xdmGzFqej1BQo/view?usp=sharing',
          'iconCode': Icons.elderly_outlined.codePoint,
          'colorVal': 0xFFFEF3C7,
        },
        {
          'title': 'Makanan Sehat Jemaah Haji',
          'desc': 'Panduan menjaga asupan gizi selama menjalankan ibadah haji',
          'category': 'Gizi Khusus',
          'url':
              'https://drive.google.com/file/d/1SdpV1JQwBQw58c2WyUIPzcbqCtgKRX5X/view?usp=sharing',
          'iconCode': Icons.mosque_outlined.codePoint,
          'colorVal': 0xFFFEF3C7,
        },
        {
          'title': 'Diet Hati',
          'desc':
              'Pengaturan makan untuk pasien dengan gangguan fungsi hati / liver',
          'category': 'Penyakit Organ',
          'url':
              'https://drive.google.com/file/d/1AWJyvHUsXiTSaXB4vJWRV8DuVueeg-11/view?usp=sharing',
          'iconCode': Icons.monitor_heart_outlined.codePoint,
          'colorVal': 0xFFDBEAFE,
        },
        {
          'title': 'Diet Lambung',
          'desc': 'Diet khusus untuk penderita gastritis dan gangguan lambung',
          'category': 'Penyakit Organ',
          'url':
              'https://drive.google.com/file/d/1gTHCfYnHRpMWlzDg2Fpn174_amfBPB78/view?usp=sharing',
          'iconCode': Icons.medical_services_outlined.codePoint,
          'colorVal': 0xFFDBEAFE,
        },
        {
          'title': 'Diet Jantung',
          'desc': 'Panduan diet rendah lemak jenuh untuk pasien kardiovaskular',
          'category': 'Kardiovaskular',
          'url':
              'https://drive.google.com/file/d/1AMmx0UVPXAi-rWn5MdANHgVCz3AjnfE9/view?usp=sharing',
          'iconCode': Icons.favorite_outlined.codePoint,
          'colorVal': 0xFFFCE7F3,
        },
        {
          'title': 'Diet Penyakit Ginjal Kronik',
          'desc':
              'Pembatasan protein dan mineral untuk pasien gagal ginjal kronik',
          'category': 'Kardiovaskular',
          'url':
              'https://drive.google.com/file/d/1ULJ2xjXQVqhIL-uwzgyYMbPxGXSJdVbg/view?usp=sharing',
          'iconCode': Icons.water_drop_outlined.codePoint,
          'colorVal': 0xFFDBEAFE,
        },
        {
          'title': 'Diet Garam Rendah',
          'desc':
              'Pembatasan natrium untuk pasien hipertensi dan retensi cairan',
          'category': 'Kardiovaskular',
          'url':
              'https://drive.google.com/file/d/1ILDn0y04uS0pbgugZyKKGiQ5pXUQY6ET/view?usp=sharing',
          'iconCode': Icons.no_meals_outlined.codePoint,
          'colorVal': 0xFFDBEAFE,
        },
        {
          'title': 'Diet Diabetes Melitus',
          'desc':
              'Pengaturan karbohidrat dan indeks glikemik untuk pasien DM tipe 1 & 2',
          'category': 'Metabolik',
          'url':
              'https://drive.google.com/file/d/1rPTX_FR46-CaYOZN-lT-2GwE-ExiKpxY/view?usp=sharing',
          'iconCode': Icons.bloodtype_outlined.codePoint,
          'colorVal': 0xFFFEF3C7,
        },
        {
          'title': 'Diet Diabetes Melitus Saat Puasa',
          'desc':
              'Panduan khusus pengaturan makan bagi penderita DM yang berpuasa',
          'category': 'Metabolik',
          'url':
              'https://drive.google.com/file/d/1WU8gTXow_V4wuPQEjSFZhZ95BA5A4m0h/view?usp=sharing',
          'iconCode': Icons.no_food_outlined.codePoint,
          'colorVal': 0xFFFEF3C7,
        },
        {
          'title': 'Diet Energi Rendah',
          'desc': 'Program diet kalori terkontrol untuk manajemen berat badan',
          'category': 'Metabolik',
          'url':
              'https://drive.google.com/file/d/16aiV08zXHsS_275djT5MXlo6n8aopqVy/view?usp=sharing',
          'iconCode': Icons.local_fire_department_outlined.codePoint,
          'colorVal': 0xFFFEF3C7,
        },
        {
          'title': 'Diet Purin Rendah',
          'desc':
              'Pembatasan purin untuk mencegah dan menangani penyakit asam urat',
          'category': 'Metabolik',
          'url':
              'https://drive.google.com/file/d/1D_dhoFxw8ZoK8sYBcCaKrMZsr_k0R2ZL/view?usp=sharing',
          'iconCode': Icons.science_outlined.codePoint,
          'colorVal': 0xFFFEF3C7,
        },
        {
          'title': 'Diet Protein Rendah',
          'desc':
              'Pengurangan asupan protein untuk perlindungan fungsi ginjal dan hati',
          'category': 'Diet Khusus',
          'url':
              'https://drive.google.com/file/d/1pUfHw-KGuJGi64ujMwzAHwtZyBi-WXUK/view?usp=sharing',
          'iconCode': Icons.egg_outlined.codePoint,
          'colorVal': 0xFFEDE9FE,
        },
        {
          'title': 'Diet Lemak Rendah',
          'desc':
              'Pembatasan lemak total dan lemak jenuh untuk kesehatan kardiovaskular',
          'category': 'Diet Khusus',
          'url':
              'https://drive.google.com/file/d/1QREic6oki2pyC2xFQ5Qvulx0-UvTXCm-/view?usp=sharing',
          'iconCode': Icons.oil_barrel_outlined.codePoint,
          'colorVal': 0xFFEDE9FE,
        },
        {
          'title': 'Diet Kekebalan Tubuh Menurun',
          'desc':
              'Panduan gizi untuk pasien dengan kondisi imunokompromais / daya tahan tubuh rendah',
          'category': 'Diet Khusus',
          'url':
              'https://drive.google.com/file/d/1oDCEedQNVE-FRyhAXIvky7cHmIWuTnhZ/view?usp=sharing',
          'iconCode': Icons.shield_outlined.codePoint,
          'colorVal': 0xFFEDE9FE,
        },
      ];

      /* debug log removed */

      // 1. Koleksi Lama (Backwards Compatibility)
      for (final diet in initialDiets) {
        final docId = (diet['title'] as String? ?? '')
            .toLowerCase()
            .replaceAll(' ', '_')
            .replaceAll(RegExp(r'[^a-z0-9_]'), '');
        batch.set(dietRef.doc(docId), diet, SetOptions(merge: true));
      }
      for (final leaflet in initialLeaflets) {
        final docId = (leaflet['title'] as String? ?? '')
            .toLowerCase()
            .replaceAll(' ', '_')
            .replaceAll(RegExp(r'[^a-z0-9_]'), '');
        batch.set(leafletRef.doc(docId), leaflet, SetOptions(merge: true));
      }

      // 2. Koleksi Baru (KYOKU Unified)
      final therapyRef = FirebaseFirestore.instance.collection(
        'therapy_programs',
      );
      final newLeafletRef = FirebaseFirestore.instance.collection('leaflets');

      for (final diet in initialDiets) {
        final name = diet['title'] as String? ?? '';
        final docId = name
            .toLowerCase()
            .replaceAll(' ', '_')
            .replaceAll(RegExp(r'[^a-z0-9_]'), '');
        batch.set(therapyRef.doc(docId), {
          'name': name,
          'description': 'Program diet standar untuk $name',
          'purpose': 'Membantu pengaturan pola makan yang tepat.',
          'notes': '-',
          'pdfUrl': diet['pdfUrl'] ?? '',
          'iconCode':
              diet['iconCodePoint'] ?? Icons.restaurant_menu_outlined.codePoint,
          'colorVal': diet['colorValue'] ?? 0xFFDBEAFE,
          'created_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      for (final leaflet in initialLeaflets) {
        final title = leaflet['title'] as String? ?? '';
        final docId = title
            .toLowerCase()
            .replaceAll(' ', '_')
            .replaceAll(RegExp(r'[^a-z0-9_]'), '');
        batch.set(newLeafletRef.doc(docId), {
          ...leaflet,
          'programId': docId, // Link to the therapy program
          'programName': title,
          'content': leaflet['desc'] ?? '', // Initial content from desc
          'created_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      /* debug log removed */
      await batch.commit();
      /* debug log removed */
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  static Future<void> initializeAppDataIfNeeded() async {
    try {
      // Cek apakah data referensi sudah ada di Firestore
      final dietCheck = await FirebaseFirestore.instance
          .collection('diet_reference')
          .limit(1)
          .get()
          .timeout(
            const Duration(seconds: 7),
          ); // Timeout singkat untuk init data

      if (dietCheck.docs.isEmpty) {
        await forceUpdateAppData();
      }
    } catch (e) {
      /* debug log removed */
      // Tidak gagal aplikasi jika seed gagal
    }
  }

  // ------------ PATIENT THERAPY PROGRAMS ------------------------------------------------------------------------------------------------------------------------------------------

  static Future<Map<String, dynamic>> addPatientTherapyProgram({
    required String patientId,
    required String patientRm,
    required String therapyProgramId,
    required String therapyProgramName,
    required String createdBy,
    String notes = '',
    String? startDate,
  }) async {
    try {
      // Cek duplikat program aktif
      final existing = await FirebaseFirestore.instance
          .collection('patientTherapyPrograms')
          .where('patientRm', isEqualTo: patientRm)
          .where('therapyProgramName', isEqualTo: therapyProgramName)
          .where('status', isEqualTo: 'active')
          .get()
          .timeout(const Duration(seconds: 10));

      if (existing.docs.isNotEmpty) {
        return {
          'success': false,
          'message':
              'Program "$therapyProgramName" sudah aktif untuk pasien ini.',
        };
      }

      final now = DateTime.now();
      final patientProgramId =
          '${patientRm}_${therapyProgramId}_${now.millisecondsSinceEpoch}';

      final newProgramData = {
        'patientProgramId': patientProgramId,
        'patientId': patientId,
        'patientRm': patientRm,
        'therapyProgramId': therapyProgramId,
        'therapyProgramName': therapyProgramName,
        'status': 'active',
        'startDate': startDate ?? now.toIso8601String(),
        'endDate': null,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy,
      };

      await FirebaseFirestore.instance
          .collection('patientTherapyPrograms')
          .doc(patientProgramId)
          .set(newProgramData);

      // Return the new program data so UI can use it immediately without fetching again
      return {
        'success': true, 
        'patientProgramId': patientProgramId,
        ...newProgramData,
        'createdAt': now.toIso8601String(), // replace timestamp for local use
        'updatedAt': now.toIso8601String(),
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Menyimpan diagnosis dan catatan klinis ke dokumen patientTherapyPrograms (per program)
  static Future<void> updateProgramClinicalData({
    required String patientProgramId,
    required String diagnosis,
    required String catatanKlinis,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('patientTherapyPrograms')
          .doc(patientProgramId)
          .update({
            'diagnosis': diagnosis,
            'catatan_klinis': catatanKlinis,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      /* debug log removed */
    }
  }

  static Future<void> updateProgramDiagnosis({
    required String patientProgramId,
    required String diagnosis,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('patientTherapyPrograms')
          .doc(patientProgramId)
          .update({
        'diagnosis': diagnosis,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      /* ignore */
    }
  }

  static Future<List<Map<String, dynamic>>> getPatientTherapyPrograms(
    String patientId,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('patientTherapyPrograms')
          .where('patientId', isEqualTo: patientId)
          .get()
          .timeout(const Duration(seconds: 10));

      final docs = snapshot.docs
          .map((d) => {'patientProgramId': d.id, ...d.data()})
          .toList();
      // Sort locally to avoid Firebase composite index requirement
      docs.sort((a, b) {
        final dateA =
            (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final dateB =
            (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return dateB.compareTo(dateA); // Descending
      });
      return docs;
    } catch (e) {
      /* debug log removed */
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getPatientTherapyProgramsByRm(
    String patientRm,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('patientTherapyPrograms')
          .where('patientRm', isEqualTo: patientRm)
          .get()
          .timeout(const Duration(seconds: 10));

      final docs = snapshot.docs
          .map((d) => {'patientProgramId': d.id, ...d.data()})
          .toList();
      // Sort locally to avoid Firebase composite index requirement
      docs.sort((a, b) {
        final dateA =
            (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final dateB =
            (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return dateB.compareTo(dateA); // Descending
      });
      return docs;
    } catch (e) {
      /* debug log removed */
      return [];
    }
  }

  static Future<bool> updatePatientProgramStatus(
    String patientProgramId,
    String status,
  ) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (status == 'completed' || status == 'inactive') {
        updateData['endDate'] = DateTime.now().toIso8601String();
      }
      await FirebaseFirestore.instance
          .collection('patientTherapyPrograms')
          .doc(patientProgramId)
          .update(updateData);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updatePatientProgramPeriod({
    required String patientProgramId,
    required String startDate,
    String? endDate,
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'startDate': startDate,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (endDate != null) {
        updateData['endDate'] = endDate;
      }
      if (notes != null) {
        updateData['notes'] = notes;
      }

      await FirebaseFirestore.instance
          .collection('patientTherapyPrograms')
          .doc(patientProgramId)
          .update(updateData);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ------------ NUTRITION TARGETS (per patientProgram) ------------------------------------------------------------------------------------------------

  static Future<bool> saveNutritionTarget({
    required String patientProgramId,
    required String patientId,
    required String patientRm,
    required String therapyProgramId,
    required Map<String, dynamic> nutrientItems,
    String catatan = '',
    String createdBy = '',
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('nutritionTargets')
          .doc(patientProgramId)
          .set({
            'patientProgramId': patientProgramId,
            'patientId': patientId,
            'patientRm': patientRm,
            'therapyProgramId': therapyProgramId,
            'nutrientItems': nutrientItems,
            'catatan': catatan,
            'updatedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': createdBy,
          }, SetOptions(merge: true));
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getNutritionTarget(
    String patientProgramId,
  ) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('nutritionTargets')
          .doc(patientProgramId)
          .get()
          .timeout(const Duration(seconds: 10));
      if (doc.exists) return doc.data();
      return null;
    } catch (e) {
      return null;
    }
  }

  // ------------ NUTRITION ACTUALIZATIONS (per patientProgram per date) ---------------------------------------------

  static Future<bool> saveNutritionActualization({
    required String patientProgramId,
    required String patientId,
    required String date,
    required Map<String, dynamic> nutrientItems,
    String createdBy = '',
  }) async {
    try {
      final actualizationId = '${patientProgramId}_$date';
      await FirebaseFirestore.instance
          .collection('nutritionActualizations')
          .doc(actualizationId)
          .set({
            'actualizationId': actualizationId,
            'patientProgramId': patientProgramId,
            'patientId': patientId,
            'date': date,
            'nutrientItems': nutrientItems,
            'updatedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': createdBy,
          }, SetOptions(merge: true));
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getNutritionActualization(
    String patientProgramId,
    String date,
  ) async {
    try {
      final actualizationId = '${patientProgramId}_$date';
      final doc = await FirebaseFirestore.instance
          .collection('nutritionActualizations')
          .doc(actualizationId)
          .get()
          .timeout(const Duration(seconds: 10));
      if (doc.exists) return doc.data();
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getMealLogsForProgram(
    String patientProgramId, {
    int days = 30,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('meal_logs')
          .where('patientProgramId', isEqualTo: patientProgramId)
          .limit(90)
          .get()
          .timeout(const Duration(seconds: 10));
      final since = DateTime.now().subtract(Duration(days: days));
      final result = snapshot.docs.map((d) => d.data()).where((log) {
        final dateStr = log['date'] as String? ?? '';
        if (dateStr.isEmpty) return true;
        final logDate = DateTime.tryParse(dateStr);
        return logDate != null && logDate.isAfter(since);
      }).toList();
      result.sort(
        (a, b) =>
            (b['date'] as String? ?? '').compareTo(a['date'] as String? ?? ''),
      );
      return result;
    } catch (e) {
      return [];
    }
  }

  static dynamic _makeEncodable(dynamic data) {
    if (data is Timestamp) {
      return data.toDate().toIso8601String();
    } else if (data is Map) {
      return data.map((key, value) => MapEntry(key, _makeEncodable(value)));
    } else if (data is List) {
      return data.map(_makeEncodable).toList();
    }
    return data;
  }

  // ------------ REVIEWS ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

  static Future<bool> saveReview({
    required String patientProgramId,
    required String patientId,
    required String patientName,
    required String ahliGiziNip,
    required double rating,
    required String ulasan,
  }) async {
    try {
      // Simpan review di koleksi reviews
      await FirebaseFirestore.instance.collection('reviews').add({
        'patientProgramId': patientProgramId,
        'patientId': patientId,
        'patientName': patientName,
        'ahliGiziNip': ahliGiziNip,
        'rating': rating,
        'ulasan': ulasan,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getReviewsByAhliGizi(
    String nip,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('ahliGiziNip', isEqualTo: nip)
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 10));

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        final rawTs = data['createdAt'];
        if (rawTs is Timestamp) {
          data['createdAt'] = rawTs.toDate().toIso8601String();
        }
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ------------ CATATAN EVALUASI PASIEN (oleh Ahli Gizi) --------------------------------------------------------------------------

  /// Simpan catatan evaluasi baru dari ahli gizi untuk pasien tertentu
  /// Collection path: users/{pasienUid}/evaluasiCatatan/{auto-id}
  /// Juga update field 'catatan_evaluasi_terakhir' di dokumen pasien untuk akses cepat
  static Future<bool> saveCatatanEvaluasi({
    required String rmPasien,
    required String catatan,
    required String agName,
    String agNip = '',
  }) async {
    try {
      // Cari UID pasien dari RM
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('rm', isEqualTo: rmPasien)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return false;

      final pasienUid = snap.docs.first.id;
      final now = DateTime.now();

      // Simpan ke subcollection evaluasiCatatan
      await FirebaseFirestore.instance
          .collection('users')
          .doc(pasienUid)
          .collection('evaluasiCatatan')
          .add({
        'catatan': catatan,
        'agName': agName,
        'agNip': agNip,
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtStr': now.toIso8601String(),
      });

      // Update field snapshot di dokumen utama untuk akses cepat
      await FirebaseFirestore.instance
          .collection('users')
          .doc(pasienUid)
          .update({
        'catatan_evaluasi_terakhir': catatan,
        'catatan_evaluasi_ag': agName,
        'catatan_evaluasi_at': now.toIso8601String(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Ambil semua catatan evaluasi pasien (descending by createdAt)
  static Future<List<Map<String, dynamic>>> getCatatanEvaluasiList(
    String rmPasien,
  ) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('rm', isEqualTo: rmPasien)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return [];

      final pasienUid = snap.docs.first.id;
      final evalSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(pasienUid)
          .collection('evaluasiCatatan')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return evalSnap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        final rawTs = data['createdAt'];
        if (rawTs is Timestamp) {
          data['createdAt'] = rawTs.toDate().toIso8601String();
          data['createdAtStr'] = rawTs.toDate().toIso8601String();
        }
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Ambil catatan evaluasi terakhir (snapshot cepat dari field dokumen pasien)
  static Future<Map<String, dynamic>?> getCatatanEvaluasiTerakhir(
    String rmPasien,
  ) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('rm', isEqualTo: rmPasien)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;

      final data = snap.docs.first.data();
      final catatan = data['catatan_evaluasi_terakhir'] as String? ?? '';
      if (catatan.isEmpty) return null;
      return {
        'catatan': catatan,
        'agName': data['catatan_evaluasi_ag'] as String? ?? '',
        'createdAtStr': data['catatan_evaluasi_at'] as String? ?? '',
      };
    } catch (e) {
      return null;
    }
  }
}
