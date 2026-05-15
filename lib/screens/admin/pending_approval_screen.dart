import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';

/// Layar yang muncul ketika Ahli Gizi sudah daftar tapi belum diapprove admin
class PendingApprovalScreen extends StatelessWidget {
  final Map<String, dynamic> user;
  const PendingApprovalScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.hourglass_empty_rounded, size: 50, color: Color(0xFFF59E0B)),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Pendaftaran Sedang Direview',
                style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Halo, ${user['name'] ?? ''}!\n\nPendaftaran Anda sudah kami terima dan sedang menunggu verifikasi dari Admin Rumah Sakit.\n\nAnda akan dapat login setelah akun Anda disetujui.',
                style: GoogleFonts.manrope(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Proses verifikasi biasanya memakan waktu 1x24 jam kerja.',
                        style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await AuthService.logout();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (r) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, size: 18, color: AppColors.textSecondary),
                  label: Text('Kembali ke Halaman Login', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.divider),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Layar yang muncul ketika pendaftaran Ahli Gizi ditolak
class RejectedScreen extends StatelessWidget {
  final Map<String, dynamic> user;
  final String reason;
  const RejectedScreen({super.key, required this.user, required this.reason});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.cancel_outlined, size: 50, color: Colors.red),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Pendaftaran Ditolak',
                style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Maaf, ${user['name'] ?? ''}. Pendaftaran Anda tidak dapat disetujui saat ini.',
                style: GoogleFonts.manrope(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Alasan Penolakan:', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.red)),
                    const SizedBox(height: 6),
                    Text(reason, style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF991B1B), height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Silakan hubungi Admin Rumah Sakit untuk informasi lebih lanjut atau mendaftar ulang.',
                style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await AuthService.logout();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (r) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, size: 18, color: AppColors.textSecondary),
                  label: Text('Kembali ke Halaman Login', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.divider),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
