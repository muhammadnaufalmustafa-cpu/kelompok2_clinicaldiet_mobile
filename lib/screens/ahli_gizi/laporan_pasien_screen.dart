import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

/// Laporan Bulanan — Menunggu format laporan dari mitra.
class LaporanPasienScreen extends StatelessWidget {
  final Map<String, dynamic> pasien;
  const LaporanPasienScreen({super.key, required this.pasien});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Laporan Bulanan',
          style: GoogleFonts.manrope(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontSize: 15),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 52,
                  color: Color(0xFFD97706),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'SEGERA',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: const Color(0xFFD97706),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Laporan Bulanan',
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Text(
                  'TUNGGU FORMAT LAPORAN DARI MITRA\n\nFitur laporan bulanan sedang dalam tahap pengembangan dan menunggu format standar resmi dari mitra klinik. Fitur ini akan segera tersedia.',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: const Color(0xFF92400E),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text('Kembali',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.divider),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
