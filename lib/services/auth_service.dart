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
        'created_at': FieldValue.serverTimestamp(),
      };
      
      await usersRef.doc(uid).set(newAhliGizi);
      
      return {'success': true, 'message': 'Registrasi ahli gizi berhasil!'};
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

  static Future<void> submitRatingAhliGizi(String nip, double newRating, {String ulasan = '', String pasienName = 'Pasien'}) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').where('nip', isEqualTo: nip).where('role', isEqualTo: 'ahli_gizi').get();
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final ag = doc.data();
        
        final currentRating = (ag['rating'] as num?)?.toDouble() ?? 0.0;
        final currentCount = (ag['rating_count'] as num?)?.toInt() ?? 0;
        
        final newCount = currentCount + 1;
        final updatedRating = ((currentRating * currentCount) + newRating) / newCount;
        
        List reviews = ag['reviews'] ?? [];
        reviews.insert(0, {
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

  static Future<Map<String, dynamic>> loginPasien({
    required String identifier, // bisa rm, email, atau username
    required String password,
  }) async {
    try {
      final usersRef = FirebaseFirestore.instance.collection('users');
      String loginEmail = identifier;

      // 1. Jika bukan format email, cari emailnya di Firestore berdasarkan RM atau Username
      if (!identifier.contains('@')) {
        final rmCheck = await usersRef.where('rm', isEqualTo: identifier).where('role', isEqualTo: 'pasien').get();
        if (rmCheck.docs.isNotEmpty) {
          loginEmail = rmCheck.docs.first.data()['email'] ?? '';
        } else {
          final usernameCheck = await usersRef.where('username', isEqualTo: identifier).where('role', isEqualTo: 'pasien').get();
          if (usernameCheck.docs.isNotEmpty) {
            loginEmail = usernameCheck.docs.first.data()['email'] ?? '';
          } else {
            return {'success': false, 'message': 'RM/Username tidak terdaftar.'};
          }
        }
      }

      // 2. Login ke Firebase Auth
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: loginEmail, password: password);
          
      final uid = userCredential.user!.uid;

      // 3. Ambil profil lengkap dari Firestore
      final userDoc = await usersRef.doc(uid).get();
      if (!userDoc.exists || userDoc.data()?['role'] != 'pasien') {
         await FirebaseAuth.instance.signOut();
         return {'success': false, 'message': 'Akun ini bukan pasien.'};
      }

      final userData = userDoc.data()!;
      // Backup session ke SharedPreferences agar tidak merusak halaman lain (SANGAT AMAN)
      final prefs = await SharedPreferences.getInstance();
      userData['password'] = password; // Tetap simpan dummy password untuk backward compatibility jika ada fitur yang butuh
      await prefs.setString(_loggedInUserKey, jsonEncode(userData));

      return {'success': true, 'user': userData};

    } on FirebaseAuthException catch (_) {
      return {'success': false, 'message': 'Email/RM atau kata sandi salah.'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> loginAhliGizi({
    required String identifier, // bisa nip atau email
    required String password,
  }) async {
    try {
      final usersRef = FirebaseFirestore.instance.collection('users');
      String loginEmail = identifier;

      // 1. Jika bukan format email, cari emailnya berdasarkan NIP
      if (!identifier.contains('@')) {
        final nipCheck = await usersRef.where('nip', isEqualTo: identifier).where('role', isEqualTo: 'ahli_gizi').get();
        if (nipCheck.docs.isNotEmpty) {
          loginEmail = nipCheck.docs.first.data()['email'] ?? '';
        } else {
          return {'success': false, 'message': 'NIP tidak terdaftar.'};
        }
      }

      // 2. Login ke Firebase Auth
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: loginEmail, password: password);
          
      final uid = userCredential.user!.uid;

      // 3. Ambil profil dari Firestore
      final userDoc = await usersRef.doc(uid).get();
      if (!userDoc.exists || userDoc.data()?['role'] != 'ahli_gizi') {
         await FirebaseAuth.instance.signOut();
         return {'success': false, 'message': 'Akun ini bukan ahli gizi.'};
      }

      final userData = userDoc.data()!;
      
      // Backup session ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      userData['password'] = password;
      await prefs.setString(_loggedInUserKey, jsonEncode(userData));

      return {'success': true, 'user': userData};

    } on FirebaseAuthException catch (_) {
      return {'success': false, 'message': 'Email/NIP atau kata sandi salah.'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
  
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ LUPA KATA SANDI â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  
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
        await prefs.setString(_loggedInUserKey, jsonEncode(freshData));
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
        await prefs.setString(_loggedInUserKey, jsonEncode(freshData));
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

    await prefs.setString(_usersKey, jsonEncode(users));

    // Update session if it's the logged in user
    final loggedIn = await getLoggedInUser();
    if (loggedIn != null && loggedIn['rm'] == rm) {
      await prefs.setString(_loggedInUserKey, jsonEncode(users[idx]));
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
    await prefs.setString(key, jsonEncode(users));
    
    final loggedIn = await getLoggedInUser();
    if (loggedIn != null && loggedIn[fieldId] == id) {
      await prefs.setString(_loggedInUserKey, jsonEncode(users[idx]));
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
      await prefs.setString(_usersKey, jsonEncode(users));

      final loggedIn = await getLoggedInUser();
      if (loggedIn != null &&
          loggedIn['rm'].toString().toLowerCase() == rm.toLowerCase()) {
        await prefs.setString(_loggedInUserKey, jsonEncode(users[idx]));
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
        await prefs.setString(_loggedInUserKey, jsonEncode(freshData));
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ PILIH AHLI GIZI & DIET â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<bool> selectAhliGizi(String rmPasien, String nipAhliGizi) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) return false;

    final decoded = jsonDecode(usersJson) as List;
    final users = decoded.cast<Map<String, dynamic>>();

    final idx = users.indexWhere(
      (u) => u['rm'].toString().toLowerCase() == rmPasien.toLowerCase(),
    );
    if (idx == -1) return false;

    users[idx]['selected_ahli_gizi_nip'] = nipAhliGizi;

    await prefs.setString(_usersKey, jsonEncode(users));

    final loggedIn = await getLoggedInUser();
    if (loggedIn != null &&
        loggedIn['rm'].toString().toLowerCase() == rmPasien.toLowerCase()) {
      await prefs.setString(_loggedInUserKey, jsonEncode(users[idx]));
    }

    return true;
  }
  
  static Future<bool> updateDietType(String rmPasien, String dietType) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) return false;

    final decoded = jsonDecode(usersJson) as List;
    final users = decoded.cast<Map<String, dynamic>>();

    final idx = users.indexWhere(
      (u) => u['rm'].toString().toLowerCase() == rmPasien.toLowerCase(),
    );
    if (idx == -1) return false;

    users[idx]['diet_type'] = dietType;

    await prefs.setString(_usersKey, jsonEncode(users));

    final loggedIn = await getLoggedInUser();
    if (loggedIn != null &&
        loggedIn['rm'].toString().toLowerCase() == rmPasien.toLowerCase()) {
      await prefs.setString(_loggedInUserKey, jsonEncode(users[idx]));
    }

    return true;
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
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final snapshot = await FirebaseFirestore.instance
          .collection('meal_logs')
          .where('rm_pasien', isEqualTo: rmPasien)
          .where('date', isGreaterThanOrEqualTo: cutoffDate.toIso8601String())
          .get();
      
      final result = snapshot.docs.map((doc) => doc.data()).toList();
      result.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
      return result;
    } catch (e) {
      return [];
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ SESSION â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<Map<String, dynamic>?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_loggedInUserKey);
    if (userJson == null) return null;
    return jsonDecode(userJson) as Map<String, dynamic>;
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
      final prefix = '$year-${month.toString().padLeft(2, '0')}';
      final snapshot = await FirebaseFirestore.instance
          .collection('nutrition_history')
          .where('rm_pasien', isEqualTo: rmPasien)
          .where('date', isGreaterThanOrEqualTo: '$prefix-01')
          .where('date', isLessThanOrEqualTo: '$prefix-31')
          .get();
      
      return snapshot.docs.map((doc) => doc.data()).toList();
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
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_usersKey);
    if (json == null) return false;
    
    final decoded = jsonDecode(json) as List;
    final list = decoded.cast<Map<String, dynamic>>();
    final idx = list.indexWhere((u) => u['role'] == 'pasien' && u['rm'] == rm);
    
    if (idx != -1) {
      list[idx]['diagnosis'] = diagnosis;
      list[idx]['catatan_klinis'] = catatanKlinis;
      if (terapiDiet != null) {
        list[idx]['diet_type'] = terapiDiet;
      }
      
      await prefs.setString(_usersKey, jsonEncode(list));
      
      final current = await getLoggedInUser();
      if (current != null && current['rm'] == rm) {
        current['diagnosis'] = diagnosis;
        current['catatan_klinis'] = catatanKlinis;
        if (terapiDiet != null) current['diet_type'] = terapiDiet;
        await prefs.setString(_loggedInUserKey, jsonEncode(current));
      }
      return true;
    }
    return false;
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
      final snapshot = await FirebaseFirestore.instance
          .collection('diet_reference')
          .orderBy('title')
          .get();
      return snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
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
          .collection('leaflet_reference')
          .orderBy('title')
          .get();
      return snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      return [];
    }
  }

  static Stream<List<Map<String, dynamic>>> streamLeaflets() {
    return FirebaseFirestore.instance
        .collection('leaflet_reference')
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ INISIALISASI DATA AWAL â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<void> initializeAppDataIfNeeded() async {
    try {
      // Cek apakah data referensi sudah ada di Firestore
      final dietCheck = await FirebaseFirestore.instance
          .collection('diet_reference')
          .limit(1)
          .get();

      if (dietCheck.docs.isEmpty) {
        // Seed diet types ke Firestore
        final batch = FirebaseFirestore.instance.batch();
        final dietRef = FirebaseFirestore.instance.collection('diet_reference');
        final leafletRef = FirebaseFirestore.instance.collection('leaflet_reference');

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

        for (final diet in initialDiets) {
          final docId = (diet['title'] as String).toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
          batch.set(dietRef.doc(docId), diet);
        }
        for (final leaflet in initialLeaflets) {
          final docId = (leaflet['title'] as String).toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
          batch.set(leafletRef.doc(docId), leaflet);
        }
        await batch.commit();
      }
    } catch (e) {
      // Tidak gagal aplikasi jika seed gagal
    }
  }
}
