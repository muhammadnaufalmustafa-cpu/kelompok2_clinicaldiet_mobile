class MealLog {
  final String id;
  final String rmPasien;
  final DateTime date;
  final String mealPagi;
  final String selinganPagi;
  final String mealSiang;
  final String selinganSore;
  final String mealMalam;
  final DateTime createdAt;
  DateTime? updatedAt;

  MealLog({
    required this.id,
    required this.rmPasien,
    required this.date,
    required this.mealPagi,
    required this.selinganPagi,
    required this.mealSiang,
    required this.selinganSore,
    required this.mealMalam,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to Map for SharedPreferences storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rm_pasien': rmPasien,
      'date': date.toIso8601String(),
      'meal_pagi': mealPagi,
      'selingan_pagi': selinganPagi,
      'meal_siang': mealSiang,
      'selingan_sore': selinganSore,
      'meal_malam': mealMalam,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Create from Map
  factory MealLog.fromMap(Map<String, dynamic> map) {
    return MealLog(
      id: map['id'] ?? '',
      rmPasien: map['rm_pasien'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      mealPagi: map['meal_pagi'] ?? '',
      selinganPagi: map['selingan_pagi'] ?? '',
      mealSiang: map['meal_siang'] ?? '',
      selinganSore: map['selingan_sore'] ?? '',
      mealMalam: map['meal_malam'] ?? '',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  // Check if all meals are empty
  bool get isEmpty =>
      mealPagi.isEmpty &&
      selinganPagi.isEmpty &&
      mealSiang.isEmpty &&
      selinganSore.isEmpty &&
      mealMalam.isEmpty;

  // Get summary of entered meals
  List<String> get filledMeals {
    final meals = <String>[];
    if (mealPagi.isNotEmpty) meals.add('Pagi');
    if (selinganPagi.isNotEmpty) meals.add('Selingan Pagi');
    if (mealSiang.isNotEmpty) meals.add('Siang');
    if (selinganSore.isNotEmpty) meals.add('Selingan Sore');
    if (mealMalam.isNotEmpty) meals.add('Malam');
    return meals;
  }
}
