import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingPhoto = false;

  Future<void> _processImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 50,
      );
      if (image != null && _user != null) {
        setState(() {
          _isUploadingPhoto = true;
        });
        
        final nip = _user!['nip'];
        final error = await AuthService.updateProfilePhoto(nip, image.path, false);
        
        await _loadUser();
        
        if (mounted) {
          setState(() {
            _isUploadingPhoto = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error ?? 'Foto profil berhasil diperbarui.', style: GoogleFonts.manrope()),
            backgroundColor: error == null ? AppColors.primary : Colors.red,
            duration: const Duration(seconds: 4),
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal mengambil foto: $e', style: GoogleFonts.manrope()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _removePhoto() async {
    setState(() => _isUploadingPhoto = true);
    final error = await AuthService.removeProfilePhoto(false);
    await _loadUser();
    if (mounted) {
      setState(() => _isUploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error ?? 'Foto profil berhasil dihapus.', style: GoogleFonts.manrope()),
        backgroundColor: error == null ? Colors.green : Colors.red,
      ));
    }
  }

  void _showPreview(String? base64Str, String? urlStr) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: (base64Str != null && base64Str.isNotEmpty)
                    ? Image.memory(base64Decode(base64Str), fit: BoxFit.contain)
                    : (urlStr != null && urlStr.isNotEmpty)
                        ? (urlStr.startsWith('http') ? Image.network(urlStr, fit: BoxFit.contain) : Image.file(File(urlStr), fit: BoxFit.contain))
                        : Container(color: Colors.white, padding: const EdgeInsets.all(40), child: Text((_user?['name'] as String? ?? 'A').substring(0, 1).toUpperCase(), style: GoogleFonts.manrope(fontSize: 100, fontWeight: FontWeight.w700, color: AppColors.secondary))),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoOptions() {
    final profilePhotoBase64 = _user?['profile_photo_base64'] as String?;
    final profilePhotoPath = _user?['profile_photo_path'] as String?;
    final hasPhoto = (profilePhotoBase64 != null && profilePhotoBase64.isNotEmpty) || (profilePhotoPath != null && profilePhotoPath.isNotEmpty);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Foto Profil', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 20),
            if (hasPhoto)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.fullscreen, color: Colors.blue),
                ),
                title: Text('Lihat Foto', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showPreview(profilePhotoBase64, profilePhotoPath);
                },
              ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, color: AppColors.primary),
              ),
              title: Text('Kamera', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _processImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Icon(Icons.photo_library, color: AppColors.secondary),
              ),
              title: Text('Galeri', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _processImage(ImageSource.gallery);
              },
            ),
            if (hasPhoto) ...[
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.delete_outline, color: AppColors.red),
                ),
                title: Text('Hapus Foto', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _removePhoto();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

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
                      if (!ctx.mounted) return; Navigator.pop(ctx);
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
                    if (!ctx.mounted) return; Navigator.pop(ctx);
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
      body: RefreshIndicator(
        onRefresh: _loadUser,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                  GestureDetector(
                    onTap: _showPhotoOptions,
                    child: Stack(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 1),
                            ],
                          ),
                          child: ClipOval(
                            child: _isUploadingPhoto
                                ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
                                : (_user?['profile_photo_base64'] != null && _user!['profile_photo_base64'].toString().isNotEmpty)
                                    ? Image.memory(base64Decode(_user!['profile_photo_base64']), fit: BoxFit.cover, errorBuilder: (c,e,s) => Center(child: Text((_user?['name'] as String? ?? 'A').substring(0, 1).toUpperCase(), style: GoogleFonts.manrope(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.secondary))))
                                    : (_user?['profile_photo_url'] != null || _user?['profile_photo_path'] != null) && (_user?['profile_photo_url'] ?? _user?['profile_photo_path']).isNotEmpty
                                        ? ((_user?['profile_photo_url'] ?? _user?['profile_photo_path']).startsWith('http')
                                            ? Image.network(_user?['profile_photo_url'] ?? _user?['profile_photo_path'], fit: BoxFit.cover, errorBuilder: (c,e,s) => Center(child: Text((_user?['name'] as String? ?? 'A').substring(0, 1).toUpperCase(), style: GoogleFonts.manrope(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.secondary))))
                                            : Image.file(File(_user?['profile_photo_path']), fit: BoxFit.cover, errorBuilder: (c,e,s) => Center(child: Text((_user?['name'] as String? ?? 'A').substring(0, 1).toUpperCase(), style: GoogleFonts.manrope(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.secondary)))))
                                        : Center(
                                            child: Text(
                                              (_user?['name'] as String? ?? 'A').substring(0, 1).toUpperCase(),
                                              style: GoogleFonts.manrope(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.secondary),
                                            ),
                                          ),
                          ),
                        ),
                        if (!_isUploadingPhoto)
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 13),
                            ),
                          ),
                      ],
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
                    style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.secondary),
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
                      const Icon(Icons.star, color: AppColors.accent, size: 20),
                      const SizedBox(width: 6),
                      Text(_rating.toStringAsFixed(1), style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
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

                  // ----------- SECTION: Ulasan dari Pasien -----------
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ULASAN DARI PASIEN',
                          style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: AppColors.textMuted),
                        ),
                        if (_ratingCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, color: AppColors.accent, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${_rating.toStringAsFixed(1)} • $_ratingCount ulasan',
                                  style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildReviewsList(),
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
      ),
    );
  }

  Widget _buildReviewsList() {
    final reviews = (_user?['reviews'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    if (reviews.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(Icons.chat_bubble_outline, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 8),
            Text(
              'Belum ada ulasan dari pasien.',
              style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ...reviews.take(3).map((r) {
          final name = r['pasienName']?.toString() ?? 'Pasien';
          final rm = r['pasienRm']?.toString() ?? '';
          final rating = (r['rating'] as num?)?.toDouble() ?? 0.0;
          final ulasan = r['ulasan']?.toString() ?? '';
          final tanggalStr = r['tanggal']?.toString() ?? '';
          String tanggalFormatted = '-';
          try {
            final dt = DateTime.parse(tanggalStr);
            tanggalFormatted = '${dt.day}/${dt.month}/${dt.year}';
          } catch (_) {}

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'P',
                      style: GoogleFonts.manrope(
                          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.accent),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name + (rm.isNotEmpty ? ' (RM: $rm)' : ''),
                              style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(tanggalFormatted, style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(5, (i) => Icon(
                          i < rating.round() ? Icons.star : Icons.star_border,
                          color: AppColors.accent,
                          size: 16,
                        )),
                      ),
                      if (ulasan.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          '"$ulasan"',
                          style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        if (reviews.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showAllReviewsBottomSheet(reviews),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Lihat Semua ${reviews.length} Ulasan', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
            ),
          ),
      ],
    );
  }

  void _showAllReviewsBottomSheet(List<Map<String, dynamic>> reviews) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(bottom: BorderSide(color: AppColors.divider)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Semua Ulasan', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  itemBuilder: (ctx, index) {
                    final r = reviews[index];
                    final name = r['pasienName']?.toString() ?? 'Pasien';
                    final rm = r['pasienRm']?.toString() ?? '';
                    final rating = (r['rating'] as num?)?.toDouble() ?? 0.0;
                    final ulasan = r['ulasan']?.toString() ?? '';
                    final tanggalStr = r['tanggal']?.toString() ?? '';
                    String tanggalFormatted = '-';
                    try {
                      final dt = DateTime.parse(tanggalStr);
                      tanggalFormatted = '${dt.day}/${dt.month}/${dt.year}';
                    } catch (_) {}

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.2), shape: BoxShape.circle),
                            child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'P', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.accent))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(name + (rm.isNotEmpty ? ' (RM: $rm)' : ''), style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    Text(tanggalFormatted, style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textMuted)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(children: List.generate(5, (i) => Icon(i < rating.round() ? Icons.star : Icons.star_border, color: AppColors.accent, size: 16))),
                                if (ulasan.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text('"$ulasan"', style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
