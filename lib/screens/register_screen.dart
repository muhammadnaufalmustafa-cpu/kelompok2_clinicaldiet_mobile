import 'dart:math';
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
  final _usernameController = TextEditingController();
  final _rmController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _nikController = TextEditingController();
  final _agamaController = TextEditingController();
  final _pendidikanController = TextEditingController();
  final _pekerjaanController = TextEditingController();
  final _alamatController = TextEditingController();
  
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _captchaController = TextEditingController();

  String _selectedGender = 'Laki-laki';
  DateTime? _selectedBirthdate;
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;
  bool _isLoading = false;

  final List<String> _genders = ['Laki-laki', 'Perempuan'];
  
  // CAPTCHA Math variables
  late int _captchaVal1;
  late int _captchaVal2;

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
  }

  void _generateCaptcha() {
    final random = Random();
    _captchaVal1 = random.nextInt(10) + 1; // 1-10
    _captchaVal2 = random.nextInt(10) + 1; // 1-10
    _captchaController.clear();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _rmController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _nikController.dispose();
    _agamaController.dispose();
    _pendidikanController.dispose();
    _pekerjaanController.dispose();
    _alamatController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthdate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedBirthdate = picked);
    }
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final rm = _rmController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final weight = _weightController.text.trim();
    final height = _heightController.text.trim();
    final nik = _nikController.text.trim();
    final agama = _agamaController.text.trim();
    final pendidikan = _pendidikanController.text.trim();
    final pekerjaan = _pekerjaanController.text.trim();
    final alamat = _alamatController.text.trim();
    final password = _passController.text;
    final confirmPass = _confirmPassController.text;
    final captchaInput = _captchaController.text.trim();

    if (name.isEmpty || rm.isEmpty || email.isEmpty || phone.isEmpty ||
        weight.isEmpty || height.isEmpty || password.isEmpty || username.isEmpty) {
      _showSnackBar('Semua field wajib (yang bukan opsional) harus diisi.', isError: true);
      return;
    }
    if (_selectedBirthdate == null) {
      _showSnackBar('Tanggal lahir harus diisi.', isError: true);
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
    
    // Validasi Captcha
    if (captchaInput.isEmpty || int.tryParse(captchaInput) != (_captchaVal1 + _captchaVal2)) {
      _showSnackBar('Jawaban pertanyaan keamanan (CAPTCHA) salah.', isError: true);
      setState(() {
        _generateCaptcha();
      });
      return;
    }

    setState(() => _isLoading = true);

    final birthdateStr =
        '${_selectedBirthdate!.day}/${_selectedBirthdate!.month}/${_selectedBirthdate!.year}';

    final result = await AuthService.register(
      name: name,
      rm: rm,
      email: email,
      phone: phone,
      weight: weight,
      height: height,
      password: password,
      gender: _selectedGender,
      birthdate: birthdateStr,
      username: username,
      nik: nik,
      agama: agama,
      pendidikan: pendidikan,
      pekerjaan: pekerjaan,
      alamat: alamat,
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
      setState(() {
        _generateCaptcha(); // regenerate if fail
      });
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.assignment_ind, color: AppColors.primaryDark),
            const SizedBox(width: 8),
            Text('Clinical Diet',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                )),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daftar Akun Pasien',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 6),
            Text('Isi data identitas dan medis Anda.',
                style: GoogleFonts.manrope(
                    fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 24),

            // ── Identitas Utama ──
            _sectionLabel('DATA IDENTITAS UTAMA'),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _nameController,
              label: 'Nama Lengkap *',
              hint: 'Masukkan nama lengkap',
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _usernameController,
              label: 'Username *',
              hint: 'Pilih username untuk login',
              prefixIcon: Icons.alternate_email,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _rmController,
              label: 'Nomor Rekam Medis (RM) *',
              hint: 'RM-12345',
              prefixIcon: Icons.badge_outlined,
            ),
            const SizedBox(height: 14),

            // Jenis Kelamin
            Text('Jenis Kelamin *',
                style: GoogleFonts.manrope(
                    fontSize: 13, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Row(
              children: _genders.map((g) {
                final selected = _selectedGender == g;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedGender = g),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: g == 'Laki-laki'
                          ? const EdgeInsets.only(right: 6)
                          : const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.divider),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            g == 'Laki-laki'
                                ? Icons.male
                                : Icons.female,
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(g,
                              style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Tanggal Lahir
            Text('Tanggal Lahir *',
                style: GoogleFonts.manrope(
                    fontSize: 13, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickBirthdate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.divider.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _selectedBirthdate == null
                          ? 'Pilih tanggal lahir'
                          : '${_selectedBirthdate!.day}/${_selectedBirthdate!.month}/${_selectedBirthdate!.year}',
                      style: GoogleFonts.manrope(
                          fontSize: 15,
                          color: _selectedBirthdate == null
                              ? AppColors.textMuted
                              : AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _phoneController,
              label: 'No. Telepon / WA *',
              hint: '0812XXXXXXXX',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _emailController,
              label: 'Email *',
              hint: 'alamat@email.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            // ── Identitas Tambahan ──
            _sectionLabel('DATA IDENTITAS TAMBAHAN (Opsional)'),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _nikController,
              label: 'NIK',
              hint: 'Masukkan NIK KTP',
              prefixIcon: Icons.credit_card_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _agamaController,
              label: 'Agama',
              hint: 'Contoh: Islam, Kristen, dll',
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _pendidikanController,
              label: 'Pendidikan Terakhir',
              hint: 'Contoh: SMA, S1, dll',
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _pekerjaanController,
              label: 'Pekerjaan',
              hint: 'Contoh: Wiraswasta',
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _alamatController,
              label: 'Alamat Lengkap',
              hint: 'Masukkan alamat domisili',
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // ── Data Medis ──
            _sectionLabel('DATA FISIK'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildNumberField(
                    controller: _weightController,
                    label: 'Berat Badan *',
                    hint: '00',
                    suffixText: 'kg',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildNumberField(
                    controller: _heightController,
                    label: 'Tinggi Badan *',
                    hint: '000',
                    suffixText: 'cm',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Kata Sandi ──
            _sectionLabel('KATA SANDI'),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _passController,
              label: 'Kata Sandi *',
              hint: '••••••••',
              prefixIcon: Icons.lock_outline,
              obscure: _obscurePass,
              suffix: GestureDetector(
                onTap: () => setState(() => _obscurePass = !_obscurePass),
                child: Icon(
                  _obscurePass
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _confirmPassController,
              label: 'Konfirmasi Kata Sandi *',
              hint: '••••••••',
              prefixIcon: Icons.lock_outline,
              obscure: _obscureConfirmPass,
              suffix: GestureDetector(
                onTap: () =>
                    setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                child: Icon(
                  _obscureConfirmPass
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // ── CAPTCHA Sederhana ──
            _sectionLabel('VERIFIKASI KEAMANAN'),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$_captchaVal1 + $_captchaVal2 = ?',
                    style: GoogleFonts.manrope(
                      fontSize: 18, 
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _captchaController,
                    label: 'Jawaban',
                    hint: 'Hasil',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('DAFTAR SEKARANG',
                        style: GoogleFonts.manrope(
                            fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: Text.rich(TextSpan(
                  text: 'Sudah punya akun? ',
                  style: GoogleFonts.manrope(
                      color: AppColors.textSecondary, fontSize: 14),
                  children: [
                    TextSpan(
                      text: 'Masuk di sini',
                      style: GoogleFonts.manrope(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                )),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        Text(label,
            style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.textSecondary)),
      ],
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
    int maxLines = 1,
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
            maxLines: maxLines,
            style: GoogleFonts.manrope(
                fontSize: 15, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.manrope(
                  color: AppColors.textMuted, fontSize: 14),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: AppColors.textSecondary, size: 20)
                  : null,
              suffixIcon: suffix,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
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
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
                fontSize: 15, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.manrope(
                  color: AppColors.textMuted, fontSize: 14),
              suffixIcon: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text(suffixText,
                        style: GoogleFonts.manrope(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ),
                ],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
