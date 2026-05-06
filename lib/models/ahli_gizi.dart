class AhliGizi {
  final String role;
  final String name;
  final String nip;
  final String email;
  final String phone;
  final String password;
  final String specialization; // kept for backward compat
  double rating;
  int ratingCount;
  // ── Field baru ──
  String? profilePhotoPath;
  List<Map<String, dynamic>> reviews; // [{pasienName, ulasan, rating, tanggal}]

  AhliGizi({
    this.role = 'ahli_gizi',
    required this.name,
    required this.nip,
    required this.email,
    required this.phone,
    required this.password,
    this.specialization = '',
    this.rating = 0.0,
    this.ratingCount = 0,
    this.profilePhotoPath,
    List<Map<String, dynamic>>? reviews,
  }) : reviews = reviews ?? [];

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
      'profile_photo_path': profilePhotoPath,
      'reviews': reviews,
    };
  }

  // Create from Map
  factory AhliGizi.fromMap(Map<String, dynamic> map) {
    final rawReviews = map['reviews'];
    List<Map<String, dynamic>> reviewsList = [];
    if (rawReviews is List) {
      reviewsList = rawReviews
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return AhliGizi(
      role: map['role']?.toString() ?? 'ahli_gizi',
      name: map['name']?.toString() ?? '',
      nip: map['nip']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      specialization: map['specialization']?.toString() ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (map['rating_count'] as num?)?.toInt() ?? 0,
      profilePhotoPath: map['profile_photo_path']?.toString(),
      reviews: reviewsList,
    );
  }

  // Get display name with rating
  String get displayName => '$name (⭐ ${rating.toStringAsFixed(1)})';
}
