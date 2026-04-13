import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _usersKey = 'registered_users';
  static const String _loggedInUserKey = 'logged_in_user';
  static const String _ahliGiziKey = 'registered_ahli_gizi';

  // ─────────────────────────── REGISTRASI PASIEN ───────────────────────────

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
    required String dietType,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final usersJson = prefs.getString(_usersKey);
    List<Map<String, dynamic>> users = [];
    if (usersJson != null) {
      final decoded = jsonDecode(usersJson) as List;
      users = decoded.cast<Map<String, dynamic>>();
    }

    final alreadyExists =
        users.any((u) => u['rm'].toString().toLowerCase() == rm.toLowerCase());
    if (alreadyExists) {
      return {'success': false, 'message': 'Nomor RM sudah terdaftar!'};
    }

    final newUser = {
      'role': 'pasien',
      'name': name,
      'rm': rm,
      'email': email,
      'weight': weight,
      'height': height,
      'password': password,
      'gender': gender,
      'birthdate': birthdate,
      'phone': phone,
      'diet_type': dietType,
      'status': 'aktif', // aktif | berhasil | meninggal
    };
    users.add(newUser);
    await prefs.setString(_usersKey, jsonEncode(users));

    return {'success': true, 'message': 'Registrasi berhasil!'};
  }

  // ─────────────────────────── REGISTRASI AHLI GIZI ────────────────────────

  static Future<Map<String, dynamic>> registerAhliGizi({
    required String name,
    required String nip,
    required String email,
    required String phone,
    required String password,
    required String specialization,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final ahliGiziJson = prefs.getString(_ahliGiziKey);
    List<Map<String, dynamic>> ahliGiziList = [];
    if (ahliGiziJson != null) {
      final decoded = jsonDecode(ahliGiziJson) as List;
      ahliGiziList = decoded.cast<Map<String, dynamic>>();
    }

    final alreadyExists = ahliGiziList
        .any((u) => u['nip'].toString().toLowerCase() == nip.toLowerCase());
    if (alreadyExists) {
      return {'success': false, 'message': 'NIP sudah terdaftar!'};
    }

    final newAhliGizi = {
      'role': 'ahli_gizi',
      'name': name,
      'nip': nip,
      'email': email,
      'phone': phone,
      'password': password,
      'specialization': specialization,
      'rating': 0.0,
      'rating_count': 0,
    };
    ahliGiziList.add(newAhliGizi);
    await prefs.setString(_ahliGiziKey, jsonEncode(ahliGiziList));

    return {'success': true, 'message': 'Registrasi ahli gizi berhasil!'};
  }

  // ─────────────────────────── AMBIL SEMUA AHLI GIZI ───────────────────────

  static Future<List<Map<String, dynamic>>> getAllAhliGizi() async {
    final prefs = await SharedPreferences.getInstance();
    final ahliGiziJson = prefs.getString(_ahliGiziKey);
    if (ahliGiziJson == null) return [];
    final decoded = jsonDecode(ahliGiziJson) as List;
    return decoded.cast<Map<String, dynamic>>();
  }

  // ─────────────────────────── RATING AHLI GIZI ────────────────────────────

  static Future<void> submitRatingAhliGizi(String nip, double newRating) async {
    final prefs = await SharedPreferences.getInstance();
    final ahliGiziJson = prefs.getString(_ahliGiziKey);
    if (ahliGiziJson != null) {
      final decoded = jsonDecode(ahliGiziJson) as List;
      final ahliGiziList = decoded.cast<Map<String, dynamic>>();
      
      final index = ahliGiziList.indexWhere((ag) => ag['nip'] == nip);
      if (index != -1) {
        final ag = ahliGiziList[index];
        final currentRating = (ag['rating'] as num?)?.toDouble() ?? 0.0;
        final currentCount = (ag['rating_count'] as num?)?.toInt() ?? 0;
        
        final newCount = currentCount + 1;
        final updatedRating = ((currentRating * currentCount) + newRating) / newCount;
        
        ag['rating'] = updatedRating;
        ag['rating_count'] = newCount;
        
        ahliGiziList[index] = ag;
        await prefs.setString(_ahliGiziKey, jsonEncode(ahliGiziList));
      }
    }
  }

  // ─────────────────────────── LOGIN (PASIEN & AHLI GIZI) ──────────────────

  static Future<Map<String, dynamic>> loginPasien({
    required String rm,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) {
      return {
        'success': false,
        'message': 'Akun tidak ditemukan. Silakan daftar terlebih dahulu.'
      };
    }

    final decoded = jsonDecode(usersJson) as List;
    final users = decoded.cast<Map<String, dynamic>>();

    try {
      final user = users.firstWhere(
        (u) =>
            u['rm'].toString().toLowerCase() == rm.toLowerCase() &&
            u['password'].toString() == password,
      );
      await prefs.setString(_loggedInUserKey, jsonEncode(user));
      return {'success': true, 'user': user};
    } catch (_) {
      return {
        'success': false,
        'message': 'Nomor RM atau kata sandi salah.'
      };
    }
  }

  static Future<Map<String, dynamic>> loginAhliGizi({
    required String nip,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final ahliGiziJson = prefs.getString(_ahliGiziKey);
    if (ahliGiziJson == null) {
      return {
        'success': false,
        'message': 'Akun ahli gizi tidak ditemukan. Silakan daftar terlebih dahulu.'
      };
    }

    final decoded = jsonDecode(ahliGiziJson) as List;
    final ahliGiziList = decoded.cast<Map<String, dynamic>>();

    try {
      final user = ahliGiziList.firstWhere(
        (u) =>
            u['nip'].toString().toLowerCase() == nip.toLowerCase() &&
            u['password'].toString() == password,
      );
      await prefs.setString(_loggedInUserKey, jsonEncode(user));
      return {'success': true, 'user': user};
    } catch (_) {
      return {
        'success': false,
        'message': 'NIP atau kata sandi salah.'
      };
    }
  }

  // ─────────────────────────── SEMUA PASIEN (untuk ahli gizi) ──────────────

  static Future<List<Map<String, dynamic>>> getAllPasien() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) return [];
    final decoded = jsonDecode(usersJson) as List;
    return decoded.cast<Map<String, dynamic>>();
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

      // Jika user yang di-update adalah user yang sedang login, update sesi juga
      final loggedIn = await getLoggedInUser();
      if (loggedIn != null &&
          loggedIn['rm'].toString().toLowerCase() == rm.toLowerCase()) {
        await prefs.setString(_loggedInUserKey, jsonEncode(users[idx]));
      }
    }
  }

  // ─────────────────────────── RATING AHLI GIZI ────────────────────────────

  static Future<void> rateAhliGizi(String nip, double rating) async {
    final prefs = await SharedPreferences.getInstance();
    final ahliGiziJson = prefs.getString(_ahliGiziKey);
    if (ahliGiziJson == null) return;

    final decoded = jsonDecode(ahliGiziJson) as List;
    final ahliGiziList = decoded.cast<Map<String, dynamic>>();

    final idx = ahliGiziList.indexWhere(
        (u) => u['nip'].toString().toLowerCase() == nip.toLowerCase());
    if (idx != -1) {
      final oldRating = (ahliGiziList[idx]['rating'] as num).toDouble();
      final oldCount = (ahliGiziList[idx]['rating_count'] as num).toInt();
      final newCount = oldCount + 1;
      final newRating = ((oldRating * oldCount) + rating) / newCount;
      ahliGiziList[idx]['rating'] = newRating;
      ahliGiziList[idx]['rating_count'] = newCount;
      await prefs.setString(_ahliGiziKey, jsonEncode(ahliGiziList));
    }
  }

  // ─────────────────────────── SESSION ─────────────────────────────────────

  static Future<Map<String, dynamic>?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_loggedInUserKey);
    if (userJson == null) return null;
    return jsonDecode(userJson) as Map<String, dynamic>;
  }

  static Future<void> logout() async {
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
}
