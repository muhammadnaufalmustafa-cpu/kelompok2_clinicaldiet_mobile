import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _rmController = TextEditingController();
  final _emailController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirmPass = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _rmController.dispose();
    _emailController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final rm = _rmController.text.trim();
    final email = _emailController.text.trim();
    final weight = _weightController.text.trim();
    final height = _heightController.text.trim();
    final password = _passController.text;
    final confirmPass = _confirmPassController.text;

    // Validasi form
    if (name.isEmpty || rm.isEmpty || email.isEmpty ||
        weight.isEmpty || height.isEmpty || password.isEmpty) {
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

    final result = await AuthService.register(
      name: name,
      rm: rm,
      email: email,
      weight: weight,
      height: height,
      password: password,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _showSnackBar('Registrasi berhasil! Silakan masuk.', isError: false);
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      _showSnackBar(result['message'] ?? 'Registrasi gagal.', isError: true);
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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 24,
        title: Row(
          children: [
            const Icon(Icons.assignment_ind, color: AppColors.primaryDark),
            const SizedBox(width: 8),
            Text(
              'Clinical Diet',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daftar Akun Baru',
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Isi data medis untuk memulai panduan klinis Anda.',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildTextField(
              controller: _nameController,
              label: 'Nama Lengkap',
              hint: 'Masukkan nama lengkap',
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _rmController,
              label: 'Nomor Rekam Medis (RM)',
              hint: 'RM-12345',
              prefixIcon: Icons.badge_outlined,
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'alamat@email.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildNumberField(
                    controller: _weightController,
                    label: 'Berat Badan',
                    hint: '00',
                    suffixText: 'kg',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildNumberField(
                    controller: _heightController,
                    label: 'Tinggi Badan',
                    hint: '000',
                    suffixText: 'cm',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _passController,
              label: 'Kata Sandi',
              hint: '••••••••',
              prefixIcon: Icons.lock_outline,
              obscure: _obscurePass,
              suffix: GestureDetector(
                onTap: () => setState(() => _obscurePass = !_obscurePass),
                child: Icon(
                  _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _confirmPassController,
              label: 'Konfirmasi Kata Sandi',
              hint: '••••••••',
              prefixIcon: Icons.lock_outline,
              obscure: _obscureConfirmPass,
              suffix: GestureDetector(
                onTap: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                child: Icon(
                  _obscureConfirmPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'DAFTAR',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: RichText(
                  text: TextSpan(
                    text: 'Sudah punya akun? ',
                    style: GoogleFonts.manrope(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: 'Masuk di sini',
                        style: GoogleFonts.manrope(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? prefixIcon,
    Widget? suffix,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            style: GoogleFonts.manrope(fontSize: 15, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.manrope(color: AppColors.textMuted, fontSize: 14),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: AppColors.textSecondary, size: 20)
                  : null,
              suffixIcon: suffix,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(fontSize: 15, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.manrope(color: AppColors.textMuted, fontSize: 14),
              suffixIcon: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text(
                      suffixText,
                      style: GoogleFonts.manrope(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14), // adjusted padding for center alignment
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              icon: Icons.person_add_alt_1_outlined,
              label: 'DAFTAR',
              isSelected: true,
              onTap: () {},
            ),
            _buildNavItem(
              icon: Icons.login,
              label: 'MASUK',
              isSelected: false,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F6F0) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
