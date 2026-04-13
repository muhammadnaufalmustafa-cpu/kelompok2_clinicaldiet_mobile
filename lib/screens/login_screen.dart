import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'welcome_screen.dart';
import 'register_screen.dart';
import 'ahli_gizi/ahli_gizi_main_screen.dart';
import 'ahli_gizi/register_ahli_gizi_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Pasien
  final _rmController = TextEditingController();
  final _passController = TextEditingController();
  bool _obscurePass = true;
  bool _isLoadingPasien = false;

  // Ahli Gizi
  final _nipController = TextEditingController();
  final _passAGController = TextEditingController();
  bool _obscurePassAG = true;
  bool _isLoadingAG = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rmController.dispose();
    _passController.dispose();
    _nipController.dispose();
    _passAGController.dispose();
    super.dispose();
  }

  Future<void> _loginPasien() async {
    final rm = _rmController.text.trim();
    final password = _passController.text;

    if (rm.isEmpty || password.isEmpty) {
      _showError('Nomor RM dan kata sandi tidak boleh kosong.');
      return;
    }

    setState(() => _isLoadingPasien = true);
    final result = await AuthService.loginPasien(rm: rm, password: password);
    if (!mounted) return;
    setState(() => _isLoadingPasien = false);

    if (result['success'] == true) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => WelcomeScreen(user: result['user'])),
      );
    } else {
      _showError(result['message'] ?? 'Login gagal.');
    }
  }

  Future<void> _loginAhliGizi() async {
    final nip = _nipController.text.trim();
    final password = _passAGController.text;

    if (nip.isEmpty || password.isEmpty) {
      _showError('NIP dan kata sandi tidak boleh kosong.');
      return;
    }

    setState(() => _isLoadingAG = true);
    final result =
        await AuthService.loginAhliGizi(nip: nip, password: password);
    if (!mounted) return;
    setState(() => _isLoadingAG = false);

    if (result['success'] == true) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AhliGiziMainScreen()),
      );
    } else {
      _showError(result['message'] ?? 'Login gagal.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.manrope()),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Logo & App Name
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/icon.png',
                      width: 36, height: 36,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.local_hospital,
                            color: AppColors.primary,
                            size: 36,
                          )),
                  const SizedBox(width: 10),
                  Text(
                    'Clinical Diet',
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Sistem Manajemen Diet Klinik',
                style: GoogleFonts.manrope(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),

              // Card Login
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Tab Bar
                    Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor: AppColors.textSecondary,
                        labelStyle: GoogleFonts.manrope(
                            fontWeight: FontWeight.w600, fontSize: 13),
                        unselectedLabelStyle:
                            GoogleFonts.manrope(fontSize: 13),
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: 'Pasien'),
                          Tab(text: 'Ahli Gizi'),
                        ],
                      ),
                    ),

                    SizedBox(
                      height: 320,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPasienForm(),
                          _buildAhliGiziForm(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Register links
              _buildRegisterRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasienForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NOMOR REKAM MEDIS (RM)',
              style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _rmController,
            hint: 'Contoh: 12-34-56',
            suffix: const Icon(Icons.dialpad,
                color: AppColors.textMuted, size: 20),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          Text('KATA SANDI',
              style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _passController,
            hint: '••••••••',
            obscure: _obscurePass,
            suffix: GestureDetector(
              onTap: () => setState(() => _obscurePass = !_obscurePass),
              child: Icon(
                _obscurePass
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textMuted,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoadingPasien ? null : _loginPasien,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isLoadingPasien
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('MASUK SEBAGAI PASIEN',
                      style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAhliGiziForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NOMOR INDUK PEGAWAI (NIP)',
              style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _nipController,
            hint: 'Masukkan NIP',
            suffix: const Icon(Icons.badge_outlined,
                color: AppColors.textMuted, size: 20),
          ),
          const SizedBox(height: 16),
          Text('KATA SANDI',
              style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _passAGController,
            hint: '••••••••',
            obscure: _obscurePassAG,
            suffix: GestureDetector(
              onTap: () => setState(() => _obscurePassAG = !_obscurePassAG),
              child: Icon(
                _obscurePassAG
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textMuted,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoadingAG ? null : _loginAhliGizi,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isLoadingAG
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('MASUK SEBAGAI AHLI GIZI',
                      style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterRow() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const RegisterScreen())),
          child: Text.rich(
            TextSpan(
              text: 'Belum punya akun pasien? ',
              style: GoogleFonts.manrope(
                  color: AppColors.textSecondary, fontSize: 13),
              children: [
                TextSpan(
                  text: 'Daftar di sini',
                  style: GoogleFonts.manrope(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const RegisterAhliGiziScreen())),
          child: Text.rich(
            TextSpan(
              text: 'Daftar sebagai ahli gizi? ',
              style: GoogleFonts.manrope(
                  color: AppColors.textSecondary, fontSize: 13),
              children: [
                TextSpan(
                  text: 'Klik di sini',
                  style: GoogleFonts.manrope(
                      color: const Color(0xFF0284C7),
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    Widget? suffix,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: GoogleFonts.manrope(
            fontSize: 15, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.manrope(color: AppColors.textMuted, fontSize: 14),
          suffixIcon: suffix != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: suffix,
                )
              : null,
          suffixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
