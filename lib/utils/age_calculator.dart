class AgeCalculator {
  static Map<String, int>? calculateAge(String? birthdateStr) {
    if (birthdateStr == null || birthdateStr.isEmpty) return null;
    try {
      final birthDate = DateTime.parse(birthdateStr);
      final today = DateTime.now();
      
      int years = today.year - birthDate.year;
      int months = today.month - birthDate.month;
      int days = today.day - birthDate.day;

      if (months < 0 || (months == 0 && days < 0)) {
        years--;
        months += (months < 0 ? 12 : 11);
      }
      
      if (days < 0) {
        final previousMonth = DateTime(today.year, today.month, 0);
        days += previousMonth.day;
      }
      
      return {'years': years, 'months': months, 'days': days};
    } catch (_) {
      return null;
    }
  }

  static String formatAge(Map<String, int>? ageMap) {
    if (ageMap == null) return 'Belum tersedia';
    final years = ageMap['years']!;
    final months = ageMap['months']!;
    final days = ageMap['days']!;
    
    final totalMonths = (years * 12) + months;
    
    if (totalMonths < 60) {
      // Kondisi A
      return '$totalMonths bulan $days hari';
    } else if (years < 18) {
      // Kondisi B
      return '$years tahun $months bulan $days hari';
    } else {
      // Kondisi C
      return '$years tahun';
    }
  }

  static String getKondisi(Map<String, int>? ageMap) {
    if (ageMap == null) return 'UNKNOWN';
    final years = ageMap['years']!;
    final months = ageMap['months']!;
    final totalMonths = (years * 12) + months;
    
    if (totalMonths < 60) return 'A';
    if (years < 18) return 'B';
    return 'C';
  }

  static String? calculateIMT(dynamic weightDyn, dynamic heightDyn) {
    try {
      final weight = double.parse(weightDyn.toString());
      final height = double.parse(heightDyn.toString());
      if (weight > 0 && height > 0) {
        final imt = weight / ((height / 100) * (height / 100));
        return imt.toStringAsFixed(1);
      }
    } catch (_) {}
    return null;
  }
}
