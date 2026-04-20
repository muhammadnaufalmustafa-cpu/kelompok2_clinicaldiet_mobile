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

  // ─────────────────────────── GET SPECIFIC PASIEN ─────────────────────────

  static Future<Map<String, dynamic>?> getPasienByRm(String rm) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) return null;

    final decoded = jsonDecode(usersJson) as List;
    final users = decoded.cast<Map<String, dynamic>>();

    try {
      return users.firstWhere(
        (u) => u['rm'].toString().toLowerCase() == rm.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────── UPDATE PASIEN BB/TB ──────────────────────────

  static Future<bool> updatePasienBBTB(
    String rm,
    double weight,
    double height,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) return false;

    final decoded = jsonDecode(usersJson) as List;
    final users = decoded.cast<Map<String, dynamic>>();

    final idx = users.indexWhere(
      (u) => u['rm'].toString().toLowerCase() == rm.toLowerCase(),
    );
    if (idx == -1) return false;

    users[idx]['weight'] = weight;
    users[idx]['height'] = height;

    await prefs.setString(_usersKey, jsonEncode(users));

    // Update logged-in user session jika pasien yang diupdate sedang login
    final loggedIn = await getLoggedInUser();
    if (loggedIn != null &&
        loggedIn['rm'].toString().toLowerCase() == rm.toLowerCase()) {
      await prefs.setString(_loggedInUserKey, jsonEncode(users[idx]));
    }

    return true;
  }

  // ───────────────────────── PILIH AHLI GIZI ──────────────────────────────

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

    // Update logged-in user session jika pasien yang diupdate sedang login
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

  // ─────────────────────────── MEAL LOGS ───────────────────────────────────

  static const String _mealLogsKey = 'meal_logs';

  static Future<bool> saveMealLog({
    required String rmPasien,
    required String mealPagi,
    required String selinganPagi,
    required String mealSiang,
    required String selinganSore,
    required String mealMalam,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Ambil existing logs
    final logsJson = prefs.getString(_mealLogsKey);
    List<Map<String, dynamic>> logs = [];
    if (logsJson != null) {
      final decoded = jsonDecode(logsJson) as List;
      logs = decoded.cast<Map<String, dynamic>>();
    }

    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';

    // Cek apakah sudah ada log untuk hari ini
    final existingLogIndex = logs.indexWhere(
      (log) =>
          log['rm_pasien'] == rmPasien &&
          log['date'].toString().startsWith(todayString),
    );

    final newLog = {
      'id': '${rmPasien}_${today.millisecondsSinceEpoch}',
      'rm_pasien': rmPasien,
      'date': today.toIso8601String(),
      'meal_pagi': mealPagi,
      'selingan_pagi': selinganPagi,
      'meal_siang': mealSiang,
      'selingan_sore': selinganSore,
      'meal_malam': mealMalam,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (existingLogIndex != -1) {
      // Update existing log
      logs[existingLogIndex] = newLog;
    } else {
      // Add new log
      logs.add(newLog);
    }

    await prefs.setString(_mealLogsKey, jsonEncode(logs));
    return true;
  }

  static Future<Map<String, dynamic>?> getMealLogForDate(
    String rmPasien,
    DateTime date,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final logsJson = prefs.getString(_mealLogsKey);
    if (logsJson == null) return null;

    final decoded = jsonDecode(logsJson) as List;
    final logs = decoded.cast<Map<String, dynamic>>();

    final dateString = '${date.year}-${date.month}-${date.day}';

    try {
      return logs.firstWhere(
        (log) =>
            log['rm_pasien'] == rmPasien &&
            log['date'].toString().startsWith(dateString),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getMealLogsForPasien(
    String rmPasien, {
    int days = 30,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final logsJson = prefs.getString(_mealLogsKey);
    if (logsJson == null) return [];

    final decoded = jsonDecode(logsJson) as List;
    final logs = decoded.cast<Map<String, dynamic>>();

    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final result = logs
        .where((log) =>
            log['rm_pasien'] == rmPasien &&
            DateTime.parse(log['date']).isAfter(cutoffDate))
        .toList();

    // Sort by date descending (newest first)
    result.sort((a, b) => DateTime.parse(b['date']).compareTo(
      DateTime.parse(a['date']),
    ));

    return result;
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

  // ─────────────────────────── NUTRISI PASIEN ──────────────────────────────

  static const String _nutrisiKey = 'nutrisi_pasien';

  /// Simpan data nutrisi pasien (target & realisasi) oleh ahli gizi.
  static Future<bool> saveNutrisiPasien({
    required String rmPasien,
    double kaloriTarget = 0,
    double proteinTarget = 0,
    double lemakTarget = 0,
    double karboTarget = 0,
    double kaloriAktual = 0,
    double proteinAktual = 0,
    double lemakAktual = 0,
    double karboAktual = 0,
    double seratAktual = 0,
    double seratTarget = 30,
    double hidrasiAktual = 0,
    double hidrasiTarget = 2.5,
    String catatan = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_nutrisiKey);
    List<Map<String, dynamic>> list = [];
    if (json != null) {
      final decoded = jsonDecode(json) as List;
      list = decoded.cast<Map<String, dynamic>>();
    }

    final idx = list.indexWhere((n) => n['rm_pasien'] == rmPasien);
    final data = {
      'rm_pasien': rmPasien,
      'kalori_target': kaloriTarget,
      'protein_target': proteinTarget,
      'lemak_target': lemakTarget,
      'karbo_target': karboTarget,
      'kalori_aktual': kaloriAktual,
      'protein_aktual': proteinAktual,
      'lemak_aktual': lemakAktual,
      'karbo_aktual': karboAktual,
      'serat_aktual': seratAktual,
      'serat_target': seratTarget,
      'hidrasi_aktual': hidrasiAktual,
      'hidrasi_target': hidrasiTarget,
      'catatan': catatan,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (idx != -1) {
      list[idx] = data;
    } else {
      list.add(data);
    }

    await prefs.setString(_nutrisiKey, jsonEncode(list));
    return true;
  }

  /// Ambil data nutrisi pasien berdasarkan RM.
  static Future<Map<String, dynamic>?> getNutrisiPasien(String rmPasien) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_nutrisiKey);
    if (json == null) return null;

    final decoded = jsonDecode(json) as List;
    final list = decoded.cast<Map<String, dynamic>>();

    try {
      return list.firstWhere((n) => n['rm_pasien'] == rmPasien);
    } catch (_) {
      return null;
    }
  }

  /// Simpan target diet teks dan catatan evaluasi (CPPT) ke record pasien.
  static Future<bool> saveTargetDietPasien({
    required String rm,
    required String targetDiet,
    required String catatanEvaluasi,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) return false;

    final decoded = jsonDecode(usersJson) as List;
    final users = decoded.cast<Map<String, dynamic>>();

    final idx = users.indexWhere(
        (u) => u['rm'].toString().toLowerCase() == rm.toLowerCase());
    if (idx == -1) return false;

    users[idx]['target_diet'] = targetDiet;
    users[idx]['catatan_evaluasi'] = catatanEvaluasi;

    await prefs.setString(_usersKey, jsonEncode(users));
    return true;
  }
}
