class Pasien {
  final String role;
  final String name;
  final String rm;
  final String email;
  double weight; // Berat badan dalam kg
  double height; // Tinggi badan dalam cm
  final String password;
  final String gender;
  final String birthdate;
  final String phone;
  final String dietType;
  final String status; // aktif | berhasil | meninggal
  String? selectedAhliGiziNip; // NIP ahli gizi yang dipilih

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
    required this.dietType,
    this.status = 'aktif',
    this.selectedAhliGiziNip,
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
    );
  }

  // Calculate BMI
  double get BMI {
    if (height == 0) return 0;
    return weight / ((height / 100) * (height / 100));
  }

  // Get BMI category
  String get BMICategory {
    final bmi = BMI;
    if (bmi < 18.5) return 'Berat Badan Kurang';
    if (bmi < 25) return 'Berat Badan Normal';
    if (bmi < 30) return 'Berat Badan Lebih';
    return 'Obesitas';
  }
}
