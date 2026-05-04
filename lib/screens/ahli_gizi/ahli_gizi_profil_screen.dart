import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';

class AhliGiziProfilScreen extends StatefulWidget {
  const AhliGiziProfilScreen({super.key});

  @override
  State<AhliGiziProfilScreen> createState() => _AhliGiziProfilScreenState();
}

class _AhliGiziProfilScreenState extends State<AhliGiziProfilScreen> {
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getLoggedInUser();
    if (mounted) setState(() => _user = user);
  }

  double get _rating => (_user?['rating'] as num?)?.toDouble() ?? 0.0;
  int get _ratingCount => (_user?['rating_count'] as num?)?.toInt() ?? 0;

  void _showEditProfileDialog() {
    if (_user == null) return;
    final nameCtrl = TextEditingController(text: _user!['name']);
    final phoneCtrl = TextEditingController(text: _user!['phone']);
    final emailCtrl = TextEditingController(text: _user!['email']);
    final pendidikanCtrl = TextEditingController(text: _user!['pendidikan'] ?? '');
    final instansiCtrl = TextEditingController(text: _user!['instansi'] ?? '');
    final tahunLulusCtrl = TextEditingController(text: _user!['tahunLulus'] ?? '');
    final pengalamanKerjaCtrl = TextEditingController(text: _user!['pengalamanKerja'] ?? '');
    final noStrCtrl = TextEditingController(text: _user!['noStr'] ?? '');
    final spesialisasiCtrl = TextEditingController(text: _user!['spesialisasi'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit Identitas & CV', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                _buildTextField(nameCtrl, 'Nama Lengkap'),
                _buildTextField(phoneCtrl, 'No. WhatsApp', isNumber: true),
                _buildTextField(emailCtrl, 'Email', isEmail: true),
                _buildTextField(pendidikanCtrl, 'Pendidikan Terakhir (Contoh: S1 Gizi Universitas X)'),
                _buildTextField(instansiCtrl, 'Instansi Asal / Tempat Praktik'),
                _buildTextField(tahunLulusCtrl, 'Tahun Lulus (Contoh: 2018)', isNumber: true),
                _buildTextField(pengalamanKerjaCtrl, 'Pengalaman Kerja (Contoh: 3 Tahun)'),
                _buildTextField(noStrCtrl, 'No. STR (Surat Tanda Registrasi)'),
                _buildTextField(spesialisasiCtrl, 'Spesialisasi (Contoh: Ahli Gizi Klinis)'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;
                      await AuthService.updateAhliGiziProfile(
                        nip: _user!['nip'],
                        name: nameCtrl.text,
                        phone: phoneCtrl.text,
                        email: emailCtrl.text,
                        pendidikan: pendidikanCtrl.text,
                        instansi: instansiCtrl.text,
                        tahunLulus: tahunLulusCtrl.text,
                        pengalamanKerja: pengalamanKerjaCtrl.text,
                        noStr: noStrCtrl.text,
                        spesialisasi: spesialisasiCtrl.text,
                      );
                      if (mounted) Navigator.pop(ctx);
                      _loadUser();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Simpan', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChangeAuthDialog() {
    if (_user == null) return;
    final emailCtrl = TextEditingController(text: _user!['email']);
    final passwordCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ganti Email & Password', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              _buildTextField(emailCtrl, 'Email Baru', isEmail: true),
              _buildTextField(passwordCtrl, 'Password Baru (Opsional)', obscure: true),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (emailCtrl.text.isEmpty) return;
                    await AuthService.updateAhliGiziEmailPassword(
                      nip: _user!['nip'],
                      email: emailCtrl.text,
                      password: passwordCtrl.text,
                    );
                    if (mounted) Navigator.pop(ctx);
                    _loadUser();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Simpan Perubahan', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showManageDietDialog() {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tambah Program Diet Baru', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              _buildTextField(titleCtrl, 'Nama Program Diet (Contoh: Diet Khusus XYZ)'),
              _buildTextField(urlCtrl, 'URL Leaflet / PDF (Link Google Drive)'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.isEmpty || urlCtrl.text.isEmpty) return;
                    final success = await AuthService.addDietType(
                      title: titleCtrl.text,
                      pdfUrl: urlCtrl.text,
                    );
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(success ? 'Program diet berhasil ditambahkan!' : 'Gagal menambahkan diet.'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Tambah Diet', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Keluar Akun', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
        content: Text('Apakah Anda yakin ingin keluar dari akun ini?', style: GoogleFonts.manrope(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.manrope(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Keluar', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false, bool isEmail = false, bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: isNumber ? TextInputType.number : (isEmail ? TextInputType.emailAddress : TextInputType.text),
        style: GoogleFonts.manrope(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.manrope(color: AppColors.textSecondary, fontSize: 13),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            pinned: true,
            centerTitle: true,
            title: Text('Profil Saya', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: AppColors.divider, height: 1),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 1),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        (_user?['name'] as String? ?? 'A').substring(0, 1).toUpperCase(),
                        style: GoogleFonts.manrope(fontSize: 36, fontWeight: FontWeight.w700, color: const Color(0xFF0284C7)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _user?['name'] ?? 'Ahli Gizi',
                    style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _user?['spesialisasi'] ?? 'Ahli Gizi Klinis',
                    style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF0284C7)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'NIP: ${_user?['nip'] ?? '-'}',
                    style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Color(0xFFF59E0B), size: 20),
                      const SizedBox(width: 6),
                      Text('${_rating.toStringAsFixed(1)}', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      Text(' ($_ratingCount ulasan)', style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'AKUN & PROFIL',
                      style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: AppColors.textMuted),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        _buildActionItem(icon: Icons.person_outline, title: 'Edit Identitas & CV', onTap: _showEditProfileDialog),
                        _divider(),
                        _buildActionItem(icon: Icons.post_add, title: 'Kelola Program Diet', onTap: _showManageDietDialog),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'KEAMANAN',
                      style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: AppColors.textMuted),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        _buildActionItem(icon: Icons.lock_outline, title: 'Ganti Email & Password', onTap: _showChangeAuthDialog),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton.icon(
                      onPressed: _showLogoutConfirmation,
                      icon: const Icon(Icons.logout, color: AppColors.red, size: 18),
                      label: Text(
                        'KELUAR AKUN',
                        style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.red, letterSpacing: 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, thickness: 1, color: AppColors.divider, indent: 56);

  Widget _buildActionItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.textSecondary, size: 18),
      ),
      title: Text(title, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
      onTap: onTap,
    );
  }
}
