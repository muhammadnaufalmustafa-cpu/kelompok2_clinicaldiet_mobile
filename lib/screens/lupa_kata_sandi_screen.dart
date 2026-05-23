import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class LupaKataSandiScreen extends StatefulWidget {
  const LupaKataSandiScreen({super.key});

  @override
  State<LupaKataSandiScreen> createState() => _LupaKataSandiScreenState();
}

class _LupaKataSandiScreenState extends State<LupaKataSandiScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('Email tidak boleh kosong.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService.resetPassword(email: email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() => _isSuccess = true);
    } else {
      _showSnackBar(result['message'] ?? 'Gagal mengirim email reset.', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.manrope()),
        backgroundColor: isError ? Colors.redAccent : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Lupa Kata Sandi',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon / Illustration
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_reset_rounded, size: 64, color: AppColors.primaryDark),
              ),
            ),
            const SizedBox(height: 32),
            
            Text(
              'Reset Kata Sandi',
              style: GoogleFonts.manrope(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            if (!_isSuccess) ...[
              Text(
                'Masukkan alamat email yang terdaftar. Kami akan mengirimkan tautan aman untuk mengatur ulang kata sandi Anda.',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Form Email
              Text('ALAMAT EMAIL',
                  style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textMuted.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.manrope(fontSize: 16, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'nama@email.com',
                    hintStyle: GoogleFonts.manrope(color: AppColors.textMuted, fontSize: 15),
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary, size: 22),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text('KIRIM TAUTAN RESET',
                          style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5)),
                ),
              ),
            ] else ...[
              // Success State
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.mark_email_read_outlined, size: 48, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Tautan Berhasil Dikirim!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(
                        text: 'Silakan periksa kotak masuk (Inbox) atau Spam untuk email ',
                        style: GoogleFonts.manrope(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                        children: [
                          TextSpan(
                            text: _emailController.text,
                            style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const TextSpan(text: ' dan ikuti instruksi yang diberikan untuk memulihkan akun Anda.'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.secondary),
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('KEMBALI KE HALAMAN MASUK',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
