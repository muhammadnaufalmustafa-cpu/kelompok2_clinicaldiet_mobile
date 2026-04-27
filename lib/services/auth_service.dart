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
    String? username,
    String? alamat,
    String? pendidikan,
    String? pekerjaan,
    String? nik,
    String? agama,
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
    
    // Check if username already exists
    if (username != null && username.isNotEmpty) {
      final usernameExists = users.any((u) => 
        u['username']?.toString().toLowerCase() == username.toLowerCase());
      if (usernameExists) {
        return {'success': false, 'message': 'Username sudah digunakan!'};
      }
    }

    final newUser = {
      'role': 'pasien',
      'name': name,
      'rm': rm,
      'email': email,
      'weight': double.tryParse(weight) ?? 0.0,
      'height': double.tryParse(height) ?? 0.0,
      'password': password,
      'gender': gender,
      'birthdate': birthdate,
      'phone': phone,
      'diet_type': '', // Kosong di awal, diisi setelah login
      'status': 'aktif',
      'username': username,
      'alamat': alamat,
      'pendidikan': pendidikan,
      'pekerjaan': pekerjaan,
      'nik': nik,
      'agama': agama,
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
      'specialization': '', // tidak dipakai saat registrasi lagi
      'rating': 0.0,
      'rating_count': 0,
      'reviews': [],
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

  static Future<void> submitRatingAhliGizi(String nip, double newRating, {String ulasan = '', String pasienName = 'Pasien'}) async {
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
        
        List reviews = ag['reviews'] ?? [];
        reviews.insert(0, {
          'pasienName': pasienName,
          'rating': newRating,
          'ulasan': ulasan,
          'tanggal': DateTime.now().toIso8601String(),
        });
        ag['reviews'] = reviews;
        
        ahliGiziList[index] = ag;
        await prefs.setString(_ahliGiziKey, jsonEncode(ahliGiziList));
      }
    }
  }

  // ─────────────────────────── LOGIN (PASIEN & AHLI GIZI) ──────────────────

  static Future<Map<String, dynamic>> loginPasien({
    required String identifier, // bisa rm, email, atau username
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
            (u['rm'].toString().toLowerCase() == identifier.toLowerCase() ||
             u['email']?.toString().toLowerCase() == identifier.toLowerCase() ||
             u['username']?.toString().toLowerCase() == identifier.toLowerCase()) &&
            u['password'].toString() == password,
      );
      await prefs.setString(_loggedInUserKey, jsonEncode(user));
      return {'success': true, 'user': user};
    } catch (_) {
      return {
        'success': false,
        'message': 'Username/Email/RM atau kata sandi salah.'
      };
    }
  }

  static Future<Map<String, dynamic>> loginAhliGizi({
    required String identifier, // bisa nip atau email
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
            (u['nip'].toString().toLowerCase() == identifier.toLowerCase() ||
             u['email']?.toString().toLowerCase() == identifier.toLowerCase()) &&
            u['password'].toString() == password,
      );
      await prefs.setString(_loggedInUserKey, jsonEncode(user));
      return {'success': true, 'user': user};
    } catch (_) {
      return {
        'success': false,
        'message': 'NIP/Email atau kata sandi salah.'
      };
    }
  }
  
  // ─────────────────────────── LUPA KATA SANDI ─────────────────────────────
  
  static Future<Map<String, dynamic>> resetPassword({required String email, required String newPassword}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Cek di tabel Pasien
    final usersJson = prefs.getString(_usersKey);
    if (usersJson != null) {
      final decoded = jsonDecode(usersJson) as List;
      final users = decoded.cast<Map<String, dynamic>>();
      final idx = users.indexWhere((u) => u['email']?.toString().toLowerCase() == email.toLowerCase());
      if (idx != -1) {
        users[idx]['password'] = newPassword;
        await prefs.setString(_usersKey, jsonEncode(users));
        return {'success': true, 'message': 'Kata sandi berhasil direset'};
      }
    }
    
    // Cek di tabel Ahli Gizi
    final agJson = prefs.getString(_ahliGiziKey);
    if (agJson != null) {
      final decoded = jsonDecode(agJson) as List;
      final ag = decoded.cast<Map<String, dynamic>>();
      final idx = ag.indexWhere((u) => u['email']?.toString().toLowerCase() == email.toLowerCase());
      if (idx != -1) {
        ag[idx]['password'] = newPassword;
        await prefs.setString(_ahliGiziKey, jsonEncode(ag));
        return {'success': true, 'message': 'Kata sandi berhasil direset'};
      }
    }
    
    return {'success': false, 'message': 'Email tidak terdaftar'};
  }

  // ─────────────────────────── PROFIL PASIEN ───────────────────────────────

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
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) return false;

    final decoded = jsonDecode(usersJson) as List;
    final users = decoded.cast<Map<String, dynamic>>();

    final idx = users.indexWhere(
      (u) => u['rm'].toString().toLowerCase() == rm.toLowerCase(),
    );
    if (idx == -1) return false;

    // Check username uniqueness if changed
    if (users[idx]['username'] != username && username.isNotEmpty) {
      final usernameExists = users.any((u) => 
        u['username']?.toString().toLowerCase() == username.toLowerCase());
      if (usernameExists) return false;
    }

    users[idx]['name'] = name;
    users[idx]['username'] = username;
    users[idx]['phone'] = phone;
    users[idx]['email'] = email;
    users[idx]['nik'] = nik;
    users[idx]['agama'] = agama;
    users[idx]['alamat'] = alamat;
    users[idx]['pendidikan'] = pendidikan;
    users[idx]['pekerjaan'] = pekerjaan;

    await prefs.setString(_usersKey, jsonEncode(users));
    
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
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) return [];
    final decoded = jsonDecode(usersJson) as List;
    return decoded.cast<Map<String, dynamic>>();
  }

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

    final loggedIn = await getLoggedInUser();
    if (loggedIn != null &&
        loggedIn['rm'].toString().toLowerCase() == rm.toLowerCase()) {
      await prefs.setString(_loggedInUserKey, jsonEncode(users[idx]));
    }

    return true;
  }

  // ───────────────────────── PILIH AHLI GIZI & DIET ──────────────────────────

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

  // ─────────────────────────── MEAL LOGS ───────────────────────────────────

  static const String _mealLogsKey = 'meal_logs';




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

<<<<<<< HEAD
  // ─────────────────────────── MULTI-DIET ──────────────────────────────────

  static Future<bool> updateDietTypes(String rmPasien, List<String> dietTypes) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) return false;
    final decoded = jsonDecode(usersJson) as List;
    final users = decoded.cast<Map<String, dynamic>>();
    final idx = users.indexWhere((u) => u['rm'].toString().toLowerCase() == rmPasien.toLowerCase());
    if (idx == -1) return false;
    users[idx]['diet_types'] = dietTypes;
    users[idx]['diet_type'] = dietTypes.isNotEmpty ? dietTypes.join(', ') : '';
    await prefs.setString(_usersKey, jsonEncode(users));
    final loggedIn = await getLoggedInUser();
    if (loggedIn != null && loggedIn['rm'].toString().toLowerCase() == rmPasien.toLowerCase()) {
      await prefs.setString(_loggedInUserKey, jsonEncode(users[idx]));
    }
    return true;
  }

  static List<String> getDietTypesList(Map<String, dynamic> pasien) {
    final raw = pasien['diet_types'];
    if (raw is List) return raw.cast<String>();
    final single = pasien['diet_type'] as String? ?? '';
    return single.isEmpty ? [] : [single];
  }

  // ─────────────────────────── INFORM CONSENT ──────────────────────────────

  static Future<bool> saveInformConsent(String rm, String signaturePath) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) return false;
    final decoded = jsonDecode(usersJson) as List;
    final users = decoded.cast<Map<String, dynamic>>();
    final idx = users.indexWhere((u) => u['rm'].toString().toLowerCase() == rm.toLowerCase());
    if (idx == -1) return false;
    users[idx]['inform_consent_signed'] = true;
    users[idx]['consent_signature_path'] = signaturePath;
    users[idx]['consent_signed_at'] = DateTime.now().toIso8601String();
    await prefs.setString(_usersKey, jsonEncode(users));
    final loggedIn = await getLoggedInUser();
    if (loggedIn != null && loggedIn['rm'].toString().toLowerCase() == rm.toLowerCase()) {
      await prefs.setString(_loggedInUserKey, jsonEncode(users[idx]));
    }
    return true;
  }

  static bool isConsentSigned(Map<String, dynamic>? user) {
    return user?['inform_consent_signed'] == true;
  }

  // ─────────────────────────── BB/TB HISTORY ───────────────────────────────

  static Future<bool> updateBBTBWithHistory(String rm, double weight, double height) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) return false;
    final decoded = jsonDecode(usersJson) as List;
    final users = decoded.cast<Map<String, dynamic>>();
    final idx = users.indexWhere((u) => u['rm'].toString().toLowerCase() == rm.toLowerCase());
    if (idx == -1) return false;
    users[idx]['weight'] = weight;
    users[idx]['height'] = height;
    final history = (users[idx]['bb_history'] as List? ?? []).cast<Map<String, dynamic>>();
    history.insert(0, {
      'weight': weight,
      'height': height,
      'recorded_at': DateTime.now().toIso8601String(),
    });
    users[idx]['bb_history'] = history.take(30).toList();
    await prefs.setString(_usersKey, jsonEncode(users));
    final loggedIn = await getLoggedInUser();
    if (loggedIn != null && loggedIn['rm'].toString().toLowerCase() == rm.toLowerCase()) {
      await prefs.setString(_loggedInUserKey, jsonEncode(users[idx]));
    }
    return true;
  }

  static List<Map<String, dynamic>> getBBTBHistory(Map<String, dynamic> pasien) {
    final raw = pasien['bb_history'];
    if (raw is List) return raw.cast<Map<String, dynamic>>();
    return [];
  }

  // ─────────────────────────── NUTRISI (6 KOMPONEN) ────────────────────────

  static const String _nutrisiKey = 'nutrisi_pasien_v2';

  static Future<bool> saveNutrisiPasien({
    required String rmPasien,
    double energiTarget = 0,
    double proteinTarget = 0,
    double lemakTarget = 0,
    double karboTarget = 0,
    double natriumTarget = 0,
    double kaliumTarget = 0,
    double energiAktual = 0,
    double proteinAktual = 0,
    double lemakAktual = 0,
    double karboAktual = 0,
    double natriumAktual = 0,
    double kaliumAktual = 0,
    double seratAktual = 0,
    double seratTarget = 30,
    double hidrasiAktual = 0,
    double hidrasiTarget = 2.5,
    String catatan = '',
    String rambuPeringatan = '',
    List<String> monitoredComponents = const [],
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
      'energi_target': energiTarget,
      'protein_target': proteinTarget,
      'lemak_target': lemakTarget,
      'karbo_target': karboTarget,
      'natrium_target': natriumTarget,
      'kalium_target': kaliumTarget,
      'energi_aktual': energiAktual,
      'protein_aktual': proteinAktual,
      'lemak_aktual': lemakAktual,
      'karbo_aktual': karboAktual,
      'natrium_aktual': natriumAktual,
      'kalium_aktual': kaliumAktual,
      'kalori_target': energiTarget,
      'kalori_aktual': energiAktual,
      'serat_aktual': seratAktual,
      'serat_target': seratTarget,
      'hidrasi_aktual': hidrasiAktual,
      'hidrasi_target': hidrasiTarget,
      'catatan': catatan,
      'rambu_peringatan': rambuPeringatan,
      'monitored_components': monitoredComponents,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (idx != -1) {
      list[idx] = data;
    } else {
      list.add(data);
    }
    await prefs.setString(_nutrisiKey, jsonEncode(list));
    // Also save to legacy key for backward compat
    final legacyKey = 'nutrisi_pasien';
    final legacyJson = prefs.getString(legacyKey);
    List<Map<String, dynamic>> legacyList = [];
    if (legacyJson != null) {
      final decoded2 = jsonDecode(legacyJson) as List;
      legacyList = decoded2.cast<Map<String, dynamic>>();
    }
    final legacyIdx = legacyList.indexWhere((n) => n['rm_pasien'] == rmPasien);
    if (legacyIdx != -1) {
      legacyList[legacyIdx] = data;
    } else {
      legacyList.add(data);
    }
    await prefs.setString(legacyKey, jsonEncode(legacyList));
    return true;
  }

  static Future<Map<String, dynamic>?> getNutrisiPasien(String rmPasien) async {
    final prefs = await SharedPreferences.getInstance();
    // Try new key first
    final json = prefs.getString(_nutrisiKey);
    if (json != null) {
      final decoded = jsonDecode(json) as List;
      final list = decoded.cast<Map<String, dynamic>>();
      try {
        return list.firstWhere((n) => n['rm_pasien'] == rmPasien);
      } catch (_) {}
    }
    // Fallback to legacy
    final legacyJson = prefs.getString('nutrisi_pasien');
    if (legacyJson == null) return null;
    final decoded2 = jsonDecode(legacyJson) as List;
    final list2 = decoded2.cast<Map<String, dynamic>>();
    try {
      return list2.firstWhere((n) => n['rm_pasien'] == rmPasien);
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────── DROPOUT DETECTION ───────────────────────────

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

  // ─────────────────────────── HASIL LAB ───────────────────────────────────

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

  // ─────────────────────────── PROFIL AHLI GIZI (EXTENDED) ─────────────────

  static Future<bool> updateAhliGiziProfile({
    required String nip,
    required String name,
    required String email,
    required String phone,
    String pendidikan = '',
    String instansi = '',
    String tahunLulus = '',
    String pengalamanKerja = '',
    String strNumber = '',
    String spesialisasi = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_ahliGiziKey);
    if (json == null) return false;
    final decoded = jsonDecode(json) as List;
    final list = decoded.cast<Map<String, dynamic>>();
    final idx = list.indexWhere((u) => u['nip'].toString() == nip);
    if (idx == -1) return false;
    list[idx]['name'] = name;
    list[idx]['email'] = email;
    list[idx]['phone'] = phone;
    list[idx]['pendidikan'] = pendidikan;
    list[idx]['instansi'] = instansi;
    list[idx]['tahun_lulus'] = tahunLulus;
    list[idx]['pengalaman_kerja'] = pengalamanKerja;
    list[idx]['str_number'] = strNumber;
    list[idx]['specialization'] = spesialisasi;
    await prefs.setString(_ahliGiziKey, jsonEncode(list));
    final loggedIn = await getLoggedInUser();
    if (loggedIn != null && loggedIn['nip']?.toString() == nip) {
      await prefs.setString(_loggedInUserKey, jsonEncode(list[idx]));
    }
    return true;
  }

  // ─────────────────────────── MEAL LOG (dengan JAM) ───────────────────────

  static Future<bool> saveMealLog({
    required String rmPasien,
    required String mealPagi,
    required String selinganPagi,
    required String mealSiang,
    required String selinganSore,
    required String mealMalam,
    double? beratBadan,
    double? tinggiBadan,
    String? jamPagi,
    String? jamSelinganPagi,
    String? jamSiang,
    String? jamSelinganSore,
    String? jamMalam,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final logsJson = prefs.getString(_mealLogsKey);
    List<Map<String, dynamic>> logs = [];
    if (logsJson != null) {
      final decoded = jsonDecode(logsJson) as List;
      logs = decoded.cast<Map<String, dynamic>>();
    }
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    final existingLogIndex = logs.indexWhere(
      (log) => log['rm_pasien'] == rmPasien && log['date'].toString().startsWith(todayString),
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
      'jam_pagi': jamPagi ?? '',
      'jam_selingan_pagi': jamSelinganPagi ?? '',
      'jam_siang': jamSiang ?? '',
      'jam_selingan_sore': jamSelinganSore ?? '',
      'jam_malam': jamMalam ?? '',
      'berat_badan': beratBadan,
      'tinggi_badan': tinggiBadan,
      'created_at': today.toIso8601String(),
      'updated_at': today.toIso8601String(),
    };
    if (existingLogIndex != -1) {
      newLog['id'] = logs[existingLogIndex]['id'];
      newLog['created_at'] = logs[existingLogIndex]['created_at'];
      logs[existingLogIndex] = newLog;
    } else {
      logs.add(newLog);
    }
    await prefs.setString(_mealLogsKey, jsonEncode(logs));
    return true;
  }

  // ─────────────────────────── SEED DUMMY DATA ─────────────────────────────

  static Future<void> seedDummyDataIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Auto-refresh cache by checking seed version
    final seedVersion = prefs.getInt('seed_version') ?? 0;
    if (seedVersion < 4) {
      await prefs.clear();
      await prefs.setInt('seed_version', 4);
    }
    
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null || (jsonDecode(usersJson) as List).isEmpty) {
      await register(name: 'Budi Santoso', rm: '100001', email: 'budi@gmail.com', weight: '65', height: '170', password: 'password123', gender: 'Laki-laki', birthdate: '1990-01-01', phone: '08123456789', username: 'budi123');
      await register(name: 'Andi Pratama', rm: '100002', email: 'andi@gmail.com', weight: '70', height: '175', password: 'password123', gender: 'Laki-laki', birthdate: '1985-05-12', phone: '08129876543', username: 'andi123');
      await register(name: 'Siti Aminah', rm: '100003', email: 'siti@gmail.com', weight: '55', height: '160', password: 'password123', gender: 'Perempuan', birthdate: '1992-08-17', phone: '08123334445', username: 'siti123');
      await register(name: 'Dewi Lestari', rm: '100004', email: 'dewi@gmail.com', weight: '60', height: '165', password: 'password123', gender: 'Perempuan', birthdate: '1988-11-20', phone: '08129998887', username: 'dewi123');
      await register(name: 'Rudi Hermawan', rm: '100005', email: 'rudi@gmail.com', weight: '85', height: '172', password: 'password123', gender: 'Laki-laki', birthdate: '1975-03-30', phone: '08125556667', username: 'rudi123');
      
      // Update statuses to make dashboard colorful
      await updatePasienStatus('100002', 'berhasil');
      await updatePasienStatus('100004', 'meninggal');
    }

    final ahliGiziJson = prefs.getString(_ahliGiziKey);
    if (ahliGiziJson == null || (jsonDecode(ahliGiziJson) as List).isEmpty) {
      await registerAhliGizi(name: 'Siti Rahmadhani, S.Gz', nip: '200001', email: 'siti.rahmadhani@rsud.go.id', phone: '08129876543', password: 'password123');
      await registerAhliGizi(name: 'Hendra Wijaya, S.Gz', nip: '200002', email: 'hendra.wijaya@rsud.go.id', phone: '08121112223', password: 'password123');
      
      await submitRatingAhliGizi('200001', 5.0, ulasan: 'Sangat ramah dan sabar menjelaskan detail diet saya.', pasienName: 'Budi Santoso');
      await submitRatingAhliGizi('200001', 4.0, ulasan: 'Menu diet yang diberikan sangat membantu!', pasienName: 'Siti Aminah');
    }
  }
}

