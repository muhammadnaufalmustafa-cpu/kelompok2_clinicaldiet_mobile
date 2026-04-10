import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _usersKey = 'registered_users';
  static const String _loggedInUserKey = 'logged_in_user';

  // Simpan user baru saat registrasi
  static Future<Map<String, dynamic>> register({
    required String name,
    required String rm,
    required String email,
    required String weight,
    required String height,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Ambil daftar user yang sudah ada
    final usersJson = prefs.getString(_usersKey);
    List<Map<String, dynamic>> users = [];
    if (usersJson != null) {
      final decoded = jsonDecode(usersJson) as List;
      users = decoded.cast<Map<String, dynamic>>();
    }

    // Cek apakah nomor RM sudah terdaftar
    final alreadyExists = users.any((u) =>
        u['rm'].toString().toLowerCase() == rm.toLowerCase());
    if (alreadyExists) {
      return {'success': false, 'message': 'Nomor RM sudah terdaftar!'};
    }

    // Tambah user baru
    final newUser = {
      'name': name,
      'rm': rm,
      'email': email,
      'weight': weight,
      'height': height,
      'password': password,
    };
    users.add(newUser);
    await prefs.setString(_usersKey, jsonEncode(users));

    return {'success': true, 'message': 'Registrasi berhasil!'};
  }

  // Verifikasi login berdasarkan nomor RM dan password
  static Future<Map<String, dynamic>> login({
    required String rm,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) {
      return {'success': false, 'message': 'Akun tidak ditemukan. Silakan daftar terlebih dahulu.'};
    }

    final decoded = jsonDecode(usersJson) as List;
    final users = decoded.cast<Map<String, dynamic>>();

    try {
      final user = users.firstWhere(
        (u) =>
            u['rm'].toString().toLowerCase() == rm.toLowerCase() &&
            u['password'].toString() == password,
      );
      // Simpan sesi login
      await prefs.setString(_loggedInUserKey, jsonEncode(user));
      return {'success': true, 'user': user};
    } catch (_) {
      return {'success': false, 'message': 'Nomor RM atau kata sandi salah.'};
    }
  }

  // Ambil data user yang sedang login
  static Future<Map<String, dynamic>?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_loggedInUserKey);
    if (userJson == null) return null;
    return jsonDecode(userJson) as Map<String, dynamic>;
  }

  // Logout — hapus sesi
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInUserKey);
  }

  // Cek apakah ada sesi yang aktif
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_loggedInUserKey);
  }
}
