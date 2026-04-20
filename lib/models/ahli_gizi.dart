class AhliGizi {
  final String role;
  final String name;
  final String nip;
  final String email;
  final String phone;
  final String password;
  final String specialization;
  double rating;
  int ratingCount;

  AhliGizi({
    this.role = 'ahli_gizi',
    required this.name,
    required this.nip,
    required this.email,
    required this.phone,
    required this.password,
    required this.specialization,
    this.rating = 0.0,
    this.ratingCount = 0,
  });

  // Convert to Map for SharedPreferences storage
  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'name': name,
      'nip': nip,
      'email': email,
      'phone': phone,
      'password': password,
      'specialization': specialization,
      'rating': rating,
      'rating_count': ratingCount,
    };
  }

  // Create from Map
  factory AhliGizi.fromMap(Map<String, dynamic> map) {
    return AhliGizi(
      role: map['role'] ?? 'ahli_gizi',
      name: map['name'] ?? '',
      nip: map['nip'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      password: map['password'] ?? '',
      specialization: map['specialization'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (map['rating_count'] as num?)?.toInt() ?? 0,
    );
  }

  // Get display name with rating
  String get displayName => '$name (⭐ ${rating.toStringAsFixed(1)})';
}
