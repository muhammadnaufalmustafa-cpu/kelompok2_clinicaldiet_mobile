class Pasien {
  final String role;
  String name;
  final String rm;
  String email;
  double weight; // Berat badan dalam kg
  double height; // Tinggi badan dalam cm
  String password;
  final String gender;
  final String birthdate;
  String phone;
  final String dietType; // kept for backward compat, not shown in register
  final String status; // aktif | berhasil | meninggal
  String? selectedAhliGiziNip; // NIP ahli gizi yang dipilih
  // ── Field baru ──
  String? username;
  String? alamat;
  String? pendidikan;
  String? pekerjaan;
  String? nik;
  String? agama;
  String? profilePhotoPath;

  Pasien({
    this.role = 'pasien',
    required this.name,
    required this.rm,
    required this.email,
    required this.weight,
    required this.height,
    required this.password,
    required this.gender,
    required this.birthdate,
    required this.phone,
    this.dietType = '',
    this.status = 'aktif',
    this.selectedAhliGiziNip,
    this.username,
    this.alamat,
    this.pendidikan,
    this.pekerjaan,
    this.nik,
    this.agama,
    this.profilePhotoPath,
  });

  // Convert to Map for SharedPreferences storage
  Map<String, dynamic> toMap() {
    return {
      'role': role,
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
      'status': status,
      'selected_ahli_gizi_nip': selectedAhliGiziNip,
      'username': username,
      'alamat': alamat,
      'pendidikan': pendidikan,
      'pekerjaan': pekerjaan,
      'nik': nik,
      'agama': agama,
      'profile_photo_path': profilePhotoPath,
    };
  }

  // Create from Map
  factory Pasien.fromMap(Map<String, dynamic> map) {
    return Pasien(
      role: map['role'] ?? 'pasien',
      name: map['name'] ?? '',
      rm: map['rm'] ?? '',
      email: map['email'] ?? '',
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      height: (map['height'] as num?)?.toDouble() ?? 0.0,
      password: map['password'] ?? '',
      gender: map['gender'] ?? '',
      birthdate: map['birthdate'] ?? '',
      phone: map['phone'] ?? '',
      dietType: map['diet_type'] ?? '',
      status: map['status'] ?? 'aktif',
      selectedAhliGiziNip: map['selected_ahli_gizi_nip'],
      username: map['username'],
      alamat: map['alamat'],
      pendidikan: map['pendidikan'],
      pekerjaan: map['pekerjaan'],
      nik: map['nik'],
      agama: map['agama'],
      profilePhotoPath: map['profile_photo_path'],
    );
  }

  // Calculate BMI
  double get bmi {
    if (height == 0) return 0;
    return weight / ((height / 100) * (height / 100));
  }

  // Get BMI category
  String get bmiCategory {
    final currentBmi = bmi;
    if (currentBmi < 18.5) return 'Berat Badan Kurang';
    if (currentBmi < 25) return 'Berat Badan Normal';
    if (currentBmi < 30) return 'Berat Badan Lebih';
    return 'Obesitas';
  }
}
