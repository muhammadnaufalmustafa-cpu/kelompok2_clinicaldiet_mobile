import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';

class RegisterAhliGiziScreen extends StatefulWidget {
  const RegisterAhliGiziScreen({super.key});

  @override
  State<RegisterAhliGiziScreen> createState() => _RegisterAhliGiziScreenState();
}

class _RegisterAhliGiziScreenState extends State<RegisterAhliGiziScreen> {
  final _nameController = TextEditingController();
  final _nipController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirmPass = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nipController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final nip = _nipController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passController.text;
    final confirmPass = _confirmPassController.text;

    if (name.isEmpty || nip.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      _showSnackBar('Semua field harus diisi.', isError: true);
      return;
    }
    if (password != confirmPass) {
      _showSnackBar('Kata sandi tidak cocok.', isError: true);
      return;
    }
    if (password.length < 6) {
      _showSnackBar('Kata sandi minimal 6 karakter.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService.registerAhliGizi(
      name: name,
      nip: nip,
      email: email,
      phone: phone,
      password: password,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _showSnackBar('Registrasi berhasil! Silakan masuk.', isError: false);
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    } else {
      _showSnackBar(result['message'] ?? 'Registrasi gagal.', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.manrope()),
      backgroundColor: isError ? Colors.redAccent : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Daftar Ahli Gizi',
            style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blue header badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.medical_services_outlined,
                      color: Color(0xFF0284C7), size: 16),
                  const SizedBox(width: 6),
                  Text('Portal Tenaga Kesehatan',
                      style: GoogleFonts.manrope(
                          color: const Color(0xFF0284C7),
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Daftar Akun\nAhli Gizi',
                style: GoogleFonts.manrope(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.2)),
            const SizedBox(height: 4),
            Text('Isi data identitas tenaga kesehatan Anda.',
                style: GoogleFonts.manrope(
                    fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 24),

            _buildField(label: 'Nama Lengkap', controller: _nameController,
                hint: 'Siti Rahmadhani, S.Gz', icon: Icons.person_outline),
            const SizedBox(height: 14),
            _buildField(label: 'NIP (Nomor Induk Pegawai)',
                controller: _nipController,
                hint: '19850101 201001 1 001',
                icon: Icons.badge_outlined),
            const SizedBox(height: 14),
            _buildField(label: 'Email', controller: _emailController,
                hint: 'ahligizi@rsud.go.id',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 14),
            _buildField(label: 'No. Telepon / WA',
                controller: _phoneController,
                hint: '0812XXXXXXXX',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 14),


            _buildField(label: 'Kata Sandi', controller: _passController,
                hint: '••••••••',
                icon: Icons.lock_outline,
                obscure: _obscurePass,
                trailing: GestureDetector(
                  onTap: () => setState(() => _obscurePass = !_obscurePass),
                  child: Icon(
                    _obscurePass
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textSecondary, size: 20,
                  ),
                )),
            const SizedBox(height: 14),
            _buildField(label: 'Konfirmasi Kata Sandi',
                controller: _confirmPassController,
                hint: '••••••••',
                icon: Icons.lock_outline,
                obscure: _obscureConfirmPass,
                trailing: GestureDetector(
                  onTap: () =>
                      setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                  child: Icon(
                    _obscureConfirmPass
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textSecondary, size: 20,
                  ),
                )),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('DAFTAR SEBAGAI AHLI GIZI',
                        style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? trailing,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.manrope(
                fontSize: 13, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: AppColors.divider.withValues(alpha: 0.5)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            style: GoogleFonts.manrope(
                fontSize: 15, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.manrope(
                  color: AppColors.textMuted, fontSize: 14),
              prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
              suffixIcon: trailing,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
