import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'pilih_ahli_gizi_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const WelcomeScreen({super.key, required this.user});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // Mock data for BMR / kebutuhan kalori
  late int _kalori;
  late int _protein;
  late int _lemak;
  late int _karbohidrat;

  @override
  void initState() {
    super.initState();
    // Di aplikasi nyata, hitung BMR pakai rumus Harris-Benedict
    // Di sini kita mock berdasarkan jenis diet
    final diet = widget.user['diet_type'] as String? ?? 'Normal';
    if (diet.contains('Tinggi Kalori')) {
      _kalori = 2500;
      _protein = 100;
      _lemak = 70;
      _karbohidrat = 350;
    } else if (diet.contains('Gizi Kurang')) {
      _kalori = 2800;
      _protein = 120;
      _lemak = 80;
      _karbohidrat = 400;
    } else {
      _kalori = 1840;
      _protein = 60;
      _lemak = 55;
      _karbohidrat = 250;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text('Selamat Datang!',
                  style: GoogleFonts.manrope(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Text(
                widget.user['name'] ?? '-',
                style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary),
              ),
              const SizedBox(height: 32),
              
              Text('Kebutuhan Gizi Harian Anda',
                  style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 16),

              // Kalori utama
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: Colors.white, size: 40),
                    const SizedBox(height: 8),
                    Text('$_kalori',
                        style: GoogleFonts.manrope(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1)),
                    Text('Kkal / Hari',
                        style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9))),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Makronutrien
              Row(
                children: [
                  Expanded(
                      child: _buildMacro('Protein', _protein, 'g',
                          const Color(0xFFFEF3C7))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildMacro('Lemak', _lemak, 'g',
                          const Color(0xFFFEE2E2))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildMacro('Karbo', _karbohidrat, 'g',
                          const Color(0xFFE0F2FE))),
                ],
              ),
              
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PilihAhliGiziScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('LANJUTKAN',
                      style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacro(String label, int value, String unit, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text('$value',
              style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          Text('$unit $label',
              style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
