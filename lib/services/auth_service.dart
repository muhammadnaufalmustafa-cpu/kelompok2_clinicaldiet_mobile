import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static const String _usersKey = 'registered_users';
  static const String _loggedInUserKey = 'logged_in_user';
  static const String _ahliGiziKey = 'registered_ahli_gizi';


  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ REGISTRASI PASIEN â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
      final rmCheck = await usersRef.where('rm', isEqualTo: rm).get();
      if (rmCheck.docs.isNotEmpty) {
        return {'success': false, 'message': 'Nomor RM sudah terdaftar!'};
      }
      
      // 2. Cek duplikasi Username di Firestore
      if (username != null && username.isNotEmpty) {
        final usernameCheck = await usersRef.where('username', isEqualTo: username).get();
        if (usernameCheck.docs.isNotEmpty) {
          return {'success': false, 'message': 'Username sudah digunakan!'};
        }
      }

      // 3. Buat akun di Firebase Auth
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

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

      await usersRef.doc(uid).set(newUser);
      
      return {'success': true, 'message': 'Registrasi berhasil!'};
    } on FirebaseAuthException catch (e) {
      String msg = 'Terjadi kesalahan saat registrasi.';
      if (e.code == 'weak-password') msg = 'Kata sandi minimal 6 karakter.';
      else if (e.code == 'email-already-in-use') msg = 'Email sudah terdaftar.';
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ REGISTRASI AHLI GIZI â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
      final nipCheck = await usersRef.where('nip', isEqualTo: nip).get();
      if (nipCheck.docs.isNotEmpty) {
        return {'success': false, 'message': 'NIP sudah terdaftar!'};
      }

      // 2. Buat akun di Firebase Auth
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

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
      
      await usersRef.doc(uid).set(newAhliGizi);

      // Kirim notifikasi ke admin bahwa ada pendaftar baru
      try {
        final adminSnap = await usersRef.where('role', isEqualTo: 'admin').limit(1).get();
        if (adminSnap.docs.isNotEmpty) {
          final adminUid = adminSnap.docs.first.data()['uid'] as String? ?? '';
          if (adminUid.isNotEmpty) {
            await FirebaseFirestore.instance.collection('notifications').add({
              'userId': adminUid,
              'role': 'admin',
              'title': '👤 Pendaftaran Ahli Gizi Baru',
              'message': '$name (NIP: $nip) mendaftar dan menunggu verifikasi Anda.',
              'type': 'new_ahligizi_request',
              'isRead': false,
              'relatedId': uid,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        }
      } catch (_) {}

      return {'success': true, 'message': 'Pendaftaran berhasil! Akun Anda sedang menunggu verifikasi dari Admin.'};
    } on FirebaseAuthException catch (e) {
      String msg = 'Terjadi kesalahan saat registrasi.';
      if (e.code == 'weak-password') msg = 'Kata sandi minimal 6 karakter.';
      else if (e.code == 'email-already-in-use') msg = 'Email sudah terdaftar.';
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ AMBIL SEMUA AHLI GIZI â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ RATING AHLI GIZI â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<void> submitRatingAhliGizi(String nip, double newRating, {String ulasan = '', String pasienName = 'Pasien', String pasienRm = ''}) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').where('nip', isEqualTo: nip).where('role', isEqualTo: 'ahli_gizi').get();
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
          final existingIndex = reviews.indexWhere((r) => r['pasienRm'] == pasienRm);
          if (existingIndex != -1) {
            final oldRating = (reviews[existingIndex]['rating'] as num?)?.toDouble() ?? 0.0;
            ratingDiff = newRating - oldRating;
            countDiff = 0; // Already rated, just updating
            reviews.removeAt(existingIndex);
          }
        }

        final newCount = currentCount + countDiff;
        final updatedRating = newCount > 0 ? ((currentRating * currentCount) + ratingDiff) / newCount : newRating;
        
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ LOGIN (PASIEN & AHLI GIZI) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // ── LOGIN UNIVERSAL (SATU PINTU TANPA PILIH ROLE) ──
  static Future<Map<String, dynamic>> loginUniversal({
    required String identifier, // bisa rm, nip, username, atau email
    required String password,
  }) async {
    try {
      print('DEBUG_AUTH: Memulai login universal untuk identifier: $identifier');
      final usersRef = FirebaseFirestore.instance.collection('users');
      String loginEmail = identifier;

      // 1. Jika bukan format email, cari emailnya di Firestore berdasarkan RM, Username, atau NIP
      if (!identifier.contains('@')) {
        print('DEBUG_AUTH: Mencari email berdasarkan RM/Username/NIP...');
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
          return {'success': false, 'message': 'Username / RM / NIP tidak terdaftar.'};
        }
      }

      print('DEBUG_AUTH: Melakukan signInWithEmailAndPassword untuk: $loginEmail');
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: loginEmail, password: password);
          
      final uid = userCredential.user!.uid;

      print('DEBUG_AUTH: Login Auth berhasil, mengambil profil Firestore untuk UID: $uid');
      final userDoc = await usersRef.doc(uid).get()
          .timeout(const Duration(seconds: 15), onTimeout: () => throw 'Timeout saat mengambil profil pengguna.');
          
      if (!userDoc.exists) {
         await FirebaseAuth.instance.signOut();
         return {'success': false, 'message': 'Data akun tidak ditemukan di database.'};
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
          final reason = userData['rejection_reason'] as String? ?? 'Tidak ada keterangan.';
          return {'success': false, 'message': 'REJECTED', 'rejection_reason': reason, 'user': userData};
        }
      }

      // Backup session ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      userData['password'] = password;
      await prefs.setString(_loggedInUserKey, jsonEncode(_makeEncodable(userData)));

      print('DEBUG_AUTH: Login universal BERHASIL ($userRole).');
      return {'success': true, 'user': userData, 'role': userRole};

    } on FirebaseAuthException catch (e) {
      print('DEBUG_AUTH_ERROR (Auth Universal): ${e.code} - ${e.message}');
      return {'success': false, 'message': 'Kredensial (Email/Username/RM/NIP atau Kata Sandi) salah.'};
    } catch (e) {
      print('DEBUG_AUTH_ERROR (General Universal): $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }


  // ════════════════════════════════════════════════════
  // ── ADMIN: Ambil semua Ahli Gizi untuk verifikasi ──
  // ════════════════════════════════════════════════════
  static Future<List<Map<String, dynamic>>> getAllAhliGiziForAdmin({String filter = 'all'}) async {
    try {
      Query query = FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'ahli_gizi');
      if (filter == 'pending') query = query.where('status_akun', isEqualTo: 'pending');
      else if (filter == 'approved') query = query.where('status_akun', isEqualTo: 'approved');
      else if (filter == 'rejected') query = query.where('status_akun', isEqualTo: 'rejected');
      final snap = await query.get();
      return snap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
    } catch (e) { return []; }
  }

  static Future<bool> approveAhliGizi(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'status_akun': 'approved', 'rejection_reason': '',
        'approved_at': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': uid, 'role': 'ahli_gizi',
        'title': '✅ Akun Anda Disetujui!',
        'message': 'Selamat! Akun Anda telah diverifikasi. Anda sekarang bisa login.',
        'type': 'account_approved', 'isRead': false, 'relatedId': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) { return false; }
  }

  static Future<bool> rejectAhliGizi(String uid, {required String reason}) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'status_akun': 'rejected', 'rejection_reason': reason,
      });
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': uid, 'role': 'ahli_gizi',
        'title': '❌ Pendaftaran Ditolak',
        'message': 'Maaf, pendaftaran Anda ditolak. Alasan: $reason',
        'type': 'account_rejected', 'isRead': false, 'relatedId': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) { return false; }
  }



  // ─────────────────────────────────────────────────────────────
  
  static Future<Map<String, dynamic>> resetPassword({required String email, required String newPassword}) async {
    try {
      // Kita abaikan parameter newPassword karena Firebase mengirim email reset
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return {'success': true, 'message': 'Link reset kata sandi telah dikirim ke email Anda.'};
    } on FirebaseAuthException catch (e) {
      String msg = 'Gagal mengirim email reset.';
      if (e.code == 'user-not-found') msg = 'Email tidak terdaftar.';
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ PROFIL AHLI GIZI â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final updateData = {
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

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updateData);
      
      final prefs = await SharedPreferences.getInstance();
      final freshData = (await FirebaseFirestore.instance.collection('users').doc(user.uid).get()).data();
      if (freshData != null) {
        await prefs.setString(_loggedInUserKey, jsonEncode(_makeEncodable(freshData)));
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
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'email': email});
      }

      if (password != null && password.isNotEmpty) {
        await user.updatePassword(password);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ PROFIL PASIEN â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updateData);
      
      // Update session local
      final prefs = await SharedPreferences.getInstance();
      final freshData = (await FirebaseFirestore.instance.collection('users').doc(user.uid).get()).data();
      if (freshData != null) {
        await prefs.setString(_loggedInUserKey, jsonEncode(_makeEncodable(freshData)));
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
    if (password != null && password.isNotEmpty) users[idx]['password'] = password;

    await prefs.setString(_usersKey, jsonEncode(_makeEncodable(users)));

    // Update session if it's the logged in user
    final loggedIn = await getLoggedInUser();
    if (loggedIn != null && loggedIn['rm'] == rm) {
      await prefs.setString(_loggedInUserKey, jsonEncode(_makeEncodable(users[idx])));
    }
    return true;
  }
  
  static Future<bool> updateProfilePhoto(String id, String photoPath, bool isPasien) async {
    final prefs = await SharedPreferences.getInstance();
    final key = isPasien ? _usersKey : _ahliGiziKey;
    final fieldId = isPasien ? 'rm' : 'nip';
    
    final jsonStr = prefs.getString(key);
    if (jsonStr == null) return false;

    final decoded = jsonDecode(jsonStr) as List;
    final users = decoded.cast<Map<String, dynamic>>();

    final idx = users.indexWhere((u) => u[fieldId].toString() == id);
    if (idx == -1) return false;

    users[idx]['profile_photo_path'] = photoPath;
    await prefs.setString(key, jsonEncode(_makeEncodable(users)));
    
    final loggedIn = await getLoggedInUser();
    if (loggedIn != null && loggedIn[fieldId] == id) {
      await prefs.setString(_loggedInUserKey, jsonEncode(_makeEncodable(users[idx])));
    }
    return true;
  }

  static Future<void> updatePasienStatus(String rm, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) return;

    final decoded = jsonDecode(usersJson) as List;
    final users = decoded.cast<Map<String, dynamic>>();

    final idx = users.indexWhere(
        (u) => u['rm'].toString().toLowerCase() == rm.toLowerCase());
    if (idx != -1) {
      users[idx]['status'] = status;
      await prefs.setString(_usersKey, jsonEncode(_makeEncodable(users)));

      final loggedIn = await getLoggedInUser();
      if (loggedIn != null &&
          loggedIn['rm'].toString().toLowerCase() == rm.toLowerCase()) {
        await prefs.setString(_loggedInUserKey, jsonEncode(_makeEncodable(users[idx])));
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ UPDATE PASIEN BB/TB â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updateData);
      
      // Update session local
      final prefs = await SharedPreferences.getInstance();
      final freshData = (await FirebaseFirestore.instance.collection('users').doc(user.uid).get()).data();
      if (freshData != null) {
        await prefs.setString(_loggedInUserKey, jsonEncode(_makeEncodable(freshData)));
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ PILIH AHLI GIZI & DIET â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<bool> selectAhliGizi(String rmPasien, String nipAhliGizi) async {
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
        if (user != null && user['rm'].toString().toLowerCase() == rmPasien.toLowerCase()) {
          user['ahli_gizi_nip'] = nipAhliGizi;
          user['selected_ahli_gizi_nip'] = nipAhliGizi;
          await prefs.setString(_loggedInUserKey, jsonEncode(_makeEncodable(user)));
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
        if (user != null && user['rm'].toString().toLowerCase() == rmPasien.toLowerCase()) {
          user['diet_type'] = dietType;
          user['diet_types'] = [dietType];
          await prefs.setString(_loggedInUserKey, jsonEncode(_makeEncodable(user)));
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getSelectedAhliGizi(String rmPasien) async {
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ MEAL LOGS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static const String _mealLogsKey = 'meal_logs';




  static Future<Map<String, dynamic>?> getMealLogForDate(
    String rmPasien,
    DateTime date,
  ) async {
    try {
      final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final docId = '${rmPasien}_$dateString';
      
      final doc = await FirebaseFirestore.instance.collection('meal_logs').doc(docId).get();
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
      final result = snapshot.docs
          .map((doc) => doc.data())
          .where((log) {
            final dateStr = log['date'] as String? ?? '';
            if (dateStr.isEmpty) return true; // sertakan jika tidak ada tanggal
            final logDate = DateTime.tryParse(dateStr);
            return logDate != null && logDate.isAfter(cutoffDate);
          })
          .toList();

      result.sort((a, b) => (b['date'] as String? ?? '').compareTo(a['date'] as String? ?? ''));
      return result;
    } catch (e) {
      return [];
    }
  }


  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ SESSION â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
        final doc = await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).get()
            .timeout(const Duration(seconds: 10));
        if (doc.exists) {
          final userData = doc.data()!;
          await prefs.setString(_loggedInUserKey, jsonEncode(_makeEncodable(userData)));
          return userData;
        }
      } catch (e) {
        print('DEBUG_AUTH_ERROR (getLoggedInUser): $e');
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
      final snapshot = await FirebaseFirestore.instance.collection('users').where('rm', isEqualTo: rm).where('role', isEqualTo: 'pasien').get();
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
              await prefs.setString(_loggedInUserKey, jsonEncode(_makeEncodable(loggedIn)));
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ MULTI-DIET â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<bool> updateDietTypes(String rmPasien, List<String> dietTypes) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').where('rm', isEqualTo: rmPasien).where('role', isEqualTo: 'pasien').get();
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
            if (loggedIn['rm'].toString().toLowerCase() == rmPasien.toLowerCase()) {
              loggedIn['diet_types'] = dietTypes;
              loggedIn['diet_type'] = dietTypeString;
              await prefs.setString(_loggedInUserKey, jsonEncode(_makeEncodable(loggedIn)));
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ INFORM CONSENT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<bool> saveInformConsent(
    String rm,
    String signaturePath, {
    String? signatureBase64,
    String? consentDocBase64,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').where('rm', isEqualTo: rm).where('role', isEqualTo: 'pasien').get();
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
              await prefs.setString(_loggedInUserKey, jsonEncode(_makeEncodable(loggedIn)));
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ BB/TB HISTORY â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<bool> updateBBTBWithHistory(String rm, double weight, double height) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').where('rm', isEqualTo: rm).where('role', isEqualTo: 'pasien').get();
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        
        final history = (data['bb_history'] as List? ?? []).cast<Map<String, dynamic>>();
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

  static List<Map<String, dynamic>> getBBTBHistory(Map<String, dynamic> pasien) {
    final raw = pasien['bb_history'];
    if (raw is List) return raw.cast<Map<String, dynamic>>();
    return [];
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ NUTRISI (6 KOMPONEN) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€




  // â”€â”€â”€ Nutrisi per Jenis Diet (NEW) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
        cleanTargets[key] = {
          'target': targetVal,
          'aktual': aktualVal,
        };
      });

      final data = {
        'rm_pasien': rmPasien,
        'diet_type': dietType,
        'target_nutrients': cleanTargets,
        'catatan': catatan,
        'evaluasi_ahli_gizi': evaluasiAhliGizi,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance.collection('nutrition_plans').doc(docId).set(data);

      // Save to history too
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final historyId = '${rmPasien}_${dietType.replaceAll(' ', '_')}_$dateKey';
      
      final historyData = Map<String, dynamic>.from(data);
      historyData['date'] = dateKey;
      
      await FirebaseFirestore.instance.collection('nutrition_history').doc(historyId).set(historyData);
      
      return true;
    } catch (e) {
      return false;
    }
  }


  static Future<Map<String, dynamic>?> getNutrisiHistoryForDate(
      String rmPasien, String dietType, String dateKey) async {
    try {
      final historyId = '${rmPasien}_${dietType.replaceAll(' ', '_')}_$dateKey';
      final doc = await FirebaseFirestore.instance.collection('nutrition_history').doc(historyId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getNutrisiHistoryForMonth(
      String rmPasien, int month, int year) async {
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

  static Future<List<Map<String, dynamic>>> getAllNutrisiPasien(String rmPasien) async {
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
      String rmPasien, String dietType) async {
    final all = await getAllNutrisiPasien(rmPasien);
    try {
      return all.firstWhere((n) => n['diet_type'] == dietType);
    } catch (_) {
      return null;
    }
  }

  // â”€â”€â”€ Nutrisi global (legacy, backward compat) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€


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
        final idx = list.indexWhere((u) => u['role'] == 'pasien' && u['rm'] == rm);
        
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
        await prefs.setString(_loggedInUserKey, jsonEncode(_makeEncodable(current)));
      }
      return true;
    } catch (e) {
      print('Error updateClinicalData: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getNutrisiPasien(String rmPasien) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('nutrition_plans').where('rm_pasien', isEqualTo: rmPasien).get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ DROPOUT DETECTION â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
      final rm = pasien['rm'] as String;
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
        final hasLog = pasienLogs.any((l) => l['date'].toString().startsWith(dateStr));
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ HASIL LAB â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ MEAL LOG (dengan JAM) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
      final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
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

      await FirebaseFirestore.instance.collection('meal_logs').doc(docId).set(logData, SetOptions(merge: true));
      return true;
    } catch (e) {
      return false;
    }
  }


  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ KELOLA JENIS DIET (FIRESTORE) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<List<Map<String, dynamic>>> getDietTypes() async {
    try {
      print('DEBUG_DIET: Memulai ambil data diet...');
      final snapshot = await FirebaseFirestore.instance
          .collection('diet_reference')
          .get();
      
      print('DEBUG_DIET: Berhasil ambil ${snapshot.docs.length} data.');
      return snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      print('DEBUG_DIET_ERROR: $e');
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
      final docId = title.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
      await FirebaseFirestore.instance.collection('diet_reference').doc(docId).set({
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
        return {'success': false, 'message': 'Program terapi diet ini sedang digunakan oleh pasien dan tidak dapat dihapus.'};
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('diet_reference')
          .where('title', isEqualTo: title)
          .get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      return {'success': true, 'message': 'Program terapi diet berhasil dihapus.'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ KELOLA LEAFLET (FIRESTORE) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
      final title = leaflet['title'] as String;
      final docId = title.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
      await FirebaseFirestore.instance.collection('leaflet_reference').doc(docId).set({
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

  // ─── KELOLA PROGRAM TERAPI DIET & LEAFLET (KYOKU) ───

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

      final programId = programName.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
      final programRef = FirebaseFirestore.instance.collection('therapy_programs').doc(programId);
      
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
      final leafletId = leafletTitle.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
      final leafletRef = FirebaseFirestore.instance.collection('leaflets').doc(leafletId);
      
      batch.set(leafletRef, {
        'programId': programId,
        'programName': programName,
        'title': leafletTitle,
        'content': leafletContent,
        'url': leafletUrl ?? '',
        'created_at': FieldValue.serverTimestamp(),
        // Mapping compatibility for old views
        'desc': leafletContent.length > 50 ? leafletContent.substring(0, 50) + '...' : leafletContent,
        'category': 'Terapi Diet',
        'iconCode': Icons.article_outlined.codePoint,
        'colorVal': 0xFFDBEAFE,
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('KYOKU_SYNC_ERROR: $e');
      return false;
    }
  }

  static Future<bool> deleteTherapyProgram(String programId) async {
    try {
      // 1. Delete program
      await FirebaseFirestore.instance.collection('therapy_programs').doc(programId).delete();
      
      // 2. Delete associated leaflets
      final leaflets = await FirebaseFirestore.instance
          .collection('leaflets')
          .where('programId', isEqualTo: programId)
          .get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in leaflets.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      return true;
    } catch (_) {
      return false;
    }
  }


  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ INISIALISASI DATA AWAL â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<String?> forceUpdateAppData() async {
    try {
      print('DEBUG_SYNC: Memulai proses sinkronisasi...');
      final batch = FirebaseFirestore.instance.batch();
      final dietRef = FirebaseFirestore.instance.collection('diet_reference');
      final leafletRef = FirebaseFirestore.instance.collection('leaflet_reference');
      
      print('DEBUG_SYNC: Menyiapkan 18 data diet...');

      final List<Map<String, dynamic>> initialDiets = [
        {'title': 'Makanan Sehat Ibu Hamil', 'pdfUrl': 'https://drive.google.com/file/d/1DtEIRBLioGTeehUTETRn2dlWY8QjWNoO/view?usp=sharing', 'iconCodePoint': Icons.pregnant_woman_outlined.codePoint, 'colorValue': 0xFFFCE7F3},
        {'title': 'Makanan Sehat Ibu Menyusui', 'pdfUrl': 'https://drive.google.com/file/d/16Uesv76NVgnZ5DPtjAJOkAFpFPxtgb8V/view?usp=sharing', 'iconCodePoint': Icons.favorite_border.codePoint, 'colorValue': 0xFFFCE7F3},
        {'title': 'Makanan Sehat Bayi', 'pdfUrl': 'https://drive.google.com/file/d/1u1EYyFS-gOVI-aiHTcz8VWbgs-qzdheX/view?usp=sharing', 'iconCodePoint': Icons.child_care_outlined.codePoint, 'colorValue': 0xFFD1FAE5},
        {'title': 'Makanan Sehat Anak Balita', 'pdfUrl': 'https://drive.google.com/file/d/1Fl9rdfVJFzf3G-kChGXHHVcx0XQ3Z67y/view?usp=sharing', 'iconCodePoint': Icons.child_friendly_outlined.codePoint, 'colorValue': 0xFFD1FAE5},
        {'title': 'Makanan Sehat Lansia', 'pdfUrl': 'https://drive.google.com/file/d/13yRFdbNbAT6X-e6cvG1xdmGzFqej1BQo/view?usp=sharing', 'iconCodePoint': Icons.elderly_outlined.codePoint, 'colorValue': 0xFFFEF3C7},
        {'title': 'Makanan Sehat Jemaah Haji', 'pdfUrl': 'https://drive.google.com/file/d/1SdpV1JQwBQw58c2WyUIPzcbqCtgKRX5X/view?usp=sharing', 'iconCodePoint': Icons.mosque_outlined.codePoint, 'colorValue': 0xFFFEF3C7},
        {'title': 'Diet Hati', 'pdfUrl': 'https://drive.google.com/file/d/1AWJyvHUsXiTSaXB4vJWRV8DuVueeg-11/view?usp=sharing', 'iconCodePoint': Icons.monitor_heart_outlined.codePoint, 'colorValue': 0xFFDBEAFE},
        {'title': 'Diet Lambung', 'pdfUrl': 'https://drive.google.com/file/d/1gTHCfYnHRpMWlzDg2Fpn174_amfBPB78/view?usp=sharing', 'iconCodePoint': Icons.medical_services_outlined.codePoint, 'colorValue': 0xFFDBEAFE},
        {'title': 'Diet Jantung', 'pdfUrl': 'https://drive.google.com/file/d/1AMmx0UVPXAi-rWn5MdANHgVCz3AjnfE9/view?usp=sharing', 'iconCodePoint': Icons.favorite_outlined.codePoint, 'colorValue': 0xFFFCE7F3},
        {'title': 'Diet Penyakit Ginjal Kronik', 'pdfUrl': 'https://drive.google.com/file/d/1ULJ2xjXQVqhIL-uwzgyYMbPxGXSJdVbg/view?usp=sharing', 'iconCodePoint': Icons.water_drop_outlined.codePoint, 'colorValue': 0xFFDBEAFE},
        {'title': 'Diet Garam Rendah', 'pdfUrl': 'https://drive.google.com/file/d/1ILDn0y04uS0pbgugZyKKGiQ5pXUQY6ET/view?usp=sharing', 'iconCodePoint': Icons.no_meals_outlined.codePoint, 'colorValue': 0xFFDBEAFE},
        {'title': 'Diet Diabetes Melitus', 'pdfUrl': 'https://drive.google.com/file/d/1rPTX_FR46-CaYOZN-lT-2GwE-ExiKpxY/view?usp=sharing', 'iconCodePoint': Icons.bloodtype_outlined.codePoint, 'colorValue': 0xFFFEF3C7},
        {'title': 'Diet Diabetes Melitus Saat Puasa', 'pdfUrl': 'https://drive.google.com/file/d/1WU8gTXow_V4wuPQEjSFZhZ95BA5A4m0h/view?usp=sharing', 'iconCodePoint': Icons.no_food_outlined.codePoint, 'colorValue': 0xFFFEF3C7},
        {'title': 'Diet Energi Rendah', 'pdfUrl': 'https://drive.google.com/file/d/16aiV08zXHsS_275djT5MXlo6n8aopqVy/view?usp=sharing', 'iconCodePoint': Icons.local_fire_department_outlined.codePoint, 'colorValue': 0xFFFEF3C7},
        {'title': 'Diet Purin Rendah', 'pdfUrl': 'https://drive.google.com/file/d/1D_dhoFxw8ZoK8sYBcCaKrMZsr_k0R2ZL/view?usp=sharing', 'iconCodePoint': Icons.science_outlined.codePoint, 'colorValue': 0xFFFEF3C7},
        {'title': 'Diet Protein Rendah', 'pdfUrl': 'https://drive.google.com/file/d/1pUfHw-KGuJGi64ujMwzAHwtZyBi-WXUK/view?usp=sharing', 'iconCodePoint': Icons.egg_outlined.codePoint, 'colorValue': 0xFFEDE9FE},
        {'title': 'Diet Lemak Rendah', 'pdfUrl': 'https://drive.google.com/file/d/1QREic6oki2pyC2xFQ5Qvulx0-UvTXCm-/view?usp=sharing', 'iconCodePoint': Icons.oil_barrel_outlined.codePoint, 'colorValue': 0xFFEDE9FE},
        {'title': 'Diet Kekebalan Tubuh Menurun', 'pdfUrl': 'https://drive.google.com/file/d/1oDCEedQNVE-FRyhAXIvky7cHmIWuTnhZ/view?usp=sharing', 'iconCodePoint': Icons.shield_outlined.codePoint, 'colorValue': 0xFFEDE9FE},
      ];

      final List<Map<String, dynamic>> initialLeaflets = [
        {'title': 'Makanan Sehat Ibu Hamil', 'desc': 'Panduan nutrisi lengkap untuk ibu hamil demi kesehatan ibu dan janin', 'category': 'Ibu & Anak', 'url': 'https://drive.google.com/file/d/1DtEIRBLioGTeehUTETRn2dlWY8QjWNoO/view?usp=sharing', 'iconCode': Icons.pregnant_woman_outlined.codePoint, 'colorVal': 0xFFFCE7F3},
        {'title': 'Makanan Sehat Ibu Menyusui', 'desc': 'Kebutuhan gizi ibu menyusui untuk mendukung produksi ASI berkualitas', 'category': 'Ibu & Anak', 'url': 'https://drive.google.com/file/d/16Uesv76NVgnZ5DPtjAJOkAFpFPxtgb8V/view?usp=sharing', 'iconCode': Icons.favorite_border.codePoint, 'colorVal': 0xFFFCE7F3},
        {'title': 'Makanan Sehat Bayi', 'desc': 'Pemberian MPASI yang tepat untuk tumbuh kembang bayi optimal', 'category': 'Ibu & Anak', 'url': 'https://drive.google.com/file/d/1u1EYyFS-gOVI-aiHTcz8VWbgs-qzdheX/view?usp=sharing', 'iconCode': Icons.child_care_outlined.codePoint, 'colorVal': 0xFFD1FAE5},
        {'title': 'Makanan Sehat Anak Balita', 'desc': 'Panduan gizi untuk anak usia 1-5 tahun agar tumbuh sehat dan cerdas', 'category': 'Ibu & Anak', 'url': 'https://drive.google.com/file/d/1Fl9rdfVJFzf3G-kChGXHHVcx0XQ3Z67y/view?usp=sharing', 'iconCode': Icons.child_friendly_outlined.codePoint, 'colorVal': 0xFFD1FAE5},
        {'title': 'Makanan Sehat Lansia', 'desc': 'Kebutuhan nutrisi khusus untuk menjaga kualitas hidup di usia lanjut', 'category': 'Gizi Khusus', 'url': 'https://drive.google.com/file/d/13yRFdbNbAT6X-e6cvG1xdmGzFqej1BQo/view?usp=sharing', 'iconCode': Icons.elderly_outlined.codePoint, 'colorVal': 0xFFFEF3C7},
        {'title': 'Makanan Sehat Jemaah Haji', 'desc': 'Panduan menjaga asupan gizi selama menjalankan ibadah haji', 'category': 'Gizi Khusus', 'url': 'https://drive.google.com/file/d/1SdpV1JQwBQw58c2WyUIPzcbqCtgKRX5X/view?usp=sharing', 'iconCode': Icons.mosque_outlined.codePoint, 'colorVal': 0xFFFEF3C7},
        {'title': 'Diet Hati', 'desc': 'Pengaturan makan untuk pasien dengan gangguan fungsi hati / liver', 'category': 'Penyakit Organ', 'url': 'https://drive.google.com/file/d/1AWJyvHUsXiTSaXB4vJWRV8DuVueeg-11/view?usp=sharing', 'iconCode': Icons.monitor_heart_outlined.codePoint, 'colorVal': 0xFFDBEAFE},
        {'title': 'Diet Lambung', 'desc': 'Diet khusus untuk penderita gastritis dan gangguan lambung', 'category': 'Penyakit Organ', 'url': 'https://drive.google.com/file/d/1gTHCfYnHRpMWlzDg2Fpn174_amfBPB78/view?usp=sharing', 'iconCode': Icons.medical_services_outlined.codePoint, 'colorVal': 0xFFDBEAFE},
        {'title': 'Diet Jantung', 'desc': 'Panduan diet rendah lemak jenuh untuk pasien kardiovaskular', 'category': 'Kardiovaskular', 'url': 'https://drive.google.com/file/d/1AMmx0UVPXAi-rWn5MdANHgVCz3AjnfE9/view?usp=sharing', 'iconCode': Icons.favorite_outlined.codePoint, 'colorVal': 0xFFFCE7F3},
        {'title': 'Diet Penyakit Ginjal Kronik', 'desc': 'Pembatasan protein dan mineral untuk pasien gagal ginjal kronik', 'category': 'Kardiovaskular', 'url': 'https://drive.google.com/file/d/1ULJ2xjXQVqhIL-uwzgyYMbPxGXSJdVbg/view?usp=sharing', 'iconCode': Icons.water_drop_outlined.codePoint, 'colorVal': 0xFFDBEAFE},
        {'title': 'Diet Garam Rendah', 'desc': 'Pembatasan natrium untuk pasien hipertensi dan retensi cairan', 'category': 'Kardiovaskular', 'url': 'https://drive.google.com/file/d/1ILDn0y04uS0pbgugZyKKGiQ5pXUQY6ET/view?usp=sharing', 'iconCode': Icons.no_meals_outlined.codePoint, 'colorVal': 0xFFDBEAFE},
        {'title': 'Diet Diabetes Melitus', 'desc': 'Pengaturan karbohidrat dan indeks glikemik untuk pasien DM tipe 1 & 2', 'category': 'Metabolik', 'url': 'https://drive.google.com/file/d/1rPTX_FR46-CaYOZN-lT-2GwE-ExiKpxY/view?usp=sharing', 'iconCode': Icons.bloodtype_outlined.codePoint, 'colorVal': 0xFFFEF3C7},
        {'title': 'Diet Diabetes Melitus Saat Puasa', 'desc': 'Panduan khusus pengaturan makan bagi penderita DM yang berpuasa', 'category': 'Metabolik', 'url': 'https://drive.google.com/file/d/1WU8gTXow_V4wuPQEjSFZhZ95BA5A4m0h/view?usp=sharing', 'iconCode': Icons.no_food_outlined.codePoint, 'colorVal': 0xFFFEF3C7},
        {'title': 'Diet Energi Rendah', 'desc': 'Program diet kalori terkontrol untuk manajemen berat badan', 'category': 'Metabolik', 'url': 'https://drive.google.com/file/d/16aiV08zXHsS_275djT5MXlo6n8aopqVy/view?usp=sharing', 'iconCode': Icons.local_fire_department_outlined.codePoint, 'colorVal': 0xFFFEF3C7},
        {'title': 'Diet Purin Rendah', 'desc': 'Pembatasan purin untuk mencegah dan menangani penyakit asam urat', 'category': 'Metabolik', 'url': 'https://drive.google.com/file/d/1D_dhoFxw8ZoK8sYBcCaKrMZsr_k0R2ZL/view?usp=sharing', 'iconCode': Icons.science_outlined.codePoint, 'colorVal': 0xFFFEF3C7},
        {'title': 'Diet Protein Rendah', 'desc': 'Pengurangan asupan protein untuk perlindungan fungsi ginjal dan hati', 'category': 'Diet Khusus', 'url': 'https://drive.google.com/file/d/1pUfHw-KGuJGi64ujMwzAHwtZyBi-WXUK/view?usp=sharing', 'iconCode': Icons.egg_outlined.codePoint, 'colorVal': 0xFFEDE9FE},
        {'title': 'Diet Lemak Rendah', 'desc': 'Pembatasan lemak total dan lemak jenuh untuk kesehatan kardiovaskular', 'category': 'Diet Khusus', 'url': 'https://drive.google.com/file/d/1QREic6oki2pyC2xFQ5Qvulx0-UvTXCm-/view?usp=sharing', 'iconCode': Icons.oil_barrel_outlined.codePoint, 'colorVal': 0xFFEDE9FE},
        {'title': 'Diet Kekebalan Tubuh Menurun', 'desc': 'Panduan gizi untuk pasien dengan kondisi imunokompromais / daya tahan tubuh rendah', 'category': 'Diet Khusus', 'url': 'https://drive.google.com/file/d/1oDCEedQNVE-FRyhAXIvky7cHmIWuTnhZ/view?usp=sharing', 'iconCode': Icons.shield_outlined.codePoint, 'colorVal': 0xFFEDE9FE},
      ];

      print('DEBUG_SYNC: Menambahkan data ke batch...');
      
      // 1. Koleksi Lama (Backwards Compatibility)
      for (final diet in initialDiets) {
        final docId = (diet['title'] as String).toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
        batch.set(dietRef.doc(docId), diet, SetOptions(merge: true));
      }
      for (final leaflet in initialLeaflets) {
        final docId = (leaflet['title'] as String).toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
        batch.set(leafletRef.doc(docId), leaflet, SetOptions(merge: true));
      }

      // 2. Koleksi Baru (KYOKU Unified)
      final therapyRef = FirebaseFirestore.instance.collection('therapy_programs');
      final newLeafletRef = FirebaseFirestore.instance.collection('leaflets');

      for (final diet in initialDiets) {
        final name = diet['title'] as String;
        final docId = name.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
        batch.set(therapyRef.doc(docId), {
          'name': name,
          'description': 'Program diet standar untuk $name',
          'purpose': 'Membantu pengaturan pola makan yang tepat.',
          'notes': '-',
          'pdfUrl': diet['pdfUrl'] ?? '',
          'iconCode': diet['iconCodePoint'] ?? Icons.restaurant_menu_outlined.codePoint,
          'colorVal': diet['colorValue'] ?? 0xFFDBEAFE,
          'created_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      for (final leaflet in initialLeaflets) {
        final title = leaflet['title'] as String;
        final docId = title.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
        batch.set(newLeafletRef.doc(docId), {
          ...leaflet,
          'programId': docId, // Link to the therapy program
          'programName': title,
          'content': leaflet['desc'] ?? '', // Initial content from desc
          'created_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      
      print('DEBUG_SYNC: Mengirim data ke Firebase (Commit)...');
      await batch.commit();
      print('DEBUG_SYNC: Sinkronisasi SELESAI dan BERHASIL.');
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
          .timeout(const Duration(seconds: 7)); // Timeout singkat untuk init data

      if (dietCheck.docs.isEmpty) {
        await forceUpdateAppData();
      }
    } catch (e) {
      print('DEBUG_INIT_ERROR: Inisialisasi data referensi dilewati karena: $e');
      // Tidak gagal aplikasi jika seed gagal
    }
  }

  // ─── PATIENT THERAPY PROGRAMS ─────────────────────────────────────────────

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
        return {'success': false, 'message': 'Program "$therapyProgramName" sudah aktif untuk pasien ini.'};
      }

      final now = DateTime.now();
      final patientProgramId = '${patientRm}_${therapyProgramId}_${now.millisecondsSinceEpoch}';

      await FirebaseFirestore.instance.collection('patientTherapyPrograms').doc(patientProgramId).set({
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
      });

      return {'success': true, 'patientProgramId': patientProgramId};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Menyimpan diagnosis ke dokumen patientTherapyPrograms (per program)
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
      print('Error updateProgramDiagnosis: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getPatientTherapyPrograms(String patientId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('patientTherapyPrograms')
          .where('patientId', isEqualTo: patientId)
          .get()
          .timeout(const Duration(seconds: 10));
          
      final docs = snapshot.docs.map((d) => {'patientProgramId': d.id, ...d.data()}).toList();
      // Sort locally to avoid Firebase composite index requirement
      docs.sort((a, b) {
        final dateA = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final dateB = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return dateB.compareTo(dateA); // Descending
      });
      return docs;
    } catch (e) {
      print('Error in getPatientTherapyPrograms: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getPatientTherapyProgramsByRm(String patientRm) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('patientTherapyPrograms')
          .where('patientRm', isEqualTo: patientRm)
          .get()
          .timeout(const Duration(seconds: 10));
          
      final docs = snapshot.docs.map((d) => {'patientProgramId': d.id, ...d.data()}).toList();
      // Sort locally to avoid Firebase composite index requirement
      docs.sort((a, b) {
        final dateA = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final dateB = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return dateB.compareTo(dateA); // Descending
      });
      return docs;
    } catch (e) {
      print('Error in getPatientTherapyProgramsByRm: $e');
      return [];
    }
  }

  static Future<bool> updatePatientProgramStatus(String patientProgramId, String status) async {
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

  // ─── NUTRITION TARGETS (per patientProgram) ───────────────────────────────

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

  static Future<Map<String, dynamic>?> getNutritionTarget(String patientProgramId) async {
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

  // ─── NUTRITION ACTUALIZATIONS (per patientProgram per date) ──────────────

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
      String patientProgramId, String date) async {
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
      String patientProgramId, {int days = 30}) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('meal_logs')
          .where('patientProgramId', isEqualTo: patientProgramId)
          .limit(90)
          .get()
          .timeout(const Duration(seconds: 10));
      final since = DateTime.now().subtract(Duration(days: days));
      final result = snapshot.docs
          .map((d) => d.data())
          .where((log) {
            final dateStr = log['date'] as String? ?? '';
            if (dateStr.isEmpty) return true;
            final logDate = DateTime.tryParse(dateStr);
            return logDate != null && logDate.isAfter(since);
          })
          .toList();
      result.sort((a, b) => (b['date'] as String? ?? '').compareTo(a['date'] as String? ?? ''));
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

  // ─── REVIEWS ────────────────────────────────────────────────────────────────
  
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

  static Future<List<Map<String, dynamic>>> getReviewsByAhliGizi(String nip) async {
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
}

