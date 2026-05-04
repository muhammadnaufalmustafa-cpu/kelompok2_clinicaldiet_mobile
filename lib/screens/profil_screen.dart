import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'pilih_ahli_gizi_screen.dart';
import 'pilih_jenis_diet_screen.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _selectedAhliGizi;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getLoggedInUser();
    if (mounted) {
      setState(() {
        _user = user;
      });
      if (user != null && user['rm'] != null) {
        final ag = await AuthService.getSelectedAhliGizi(user['rm'] as String);
        if (mounted) setState(() => _selectedAhliGizi = ag);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null && _user != null) {
        final rm = _user!['rm'];
        await AuthService.updateProfilePhoto(rm, image.path, true);
        await _loadUser();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Foto profil berhasil diperbarui.', style: GoogleFonts.manrope()),
            backgroundColor: AppColors.primary,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal mengambil foto: $e', style: GoogleFonts.manrope()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _launchWhatsApp() async {
    String? phone = _selectedAhliGizi?['phone'] as String?;

    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nomor telepon ahli gizi tidak tersedia. Pastikan Anda sudah memilih ahli gizi.',
            style: GoogleFonts.manrope(),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    phone = phone.replaceAll(RegExp(r'[\s\-()]'), '');
    if (phone.startsWith('0')) {
      phone = '62${phone.substring(1)}';
    } else if (!phone.startsWith('62')) {
      phone = '62$phone';
    }

    final ahliGiziName = _selectedAhliGizi?['name'] ?? 'Ahli Gizi';
    final pasienName = _user?['name'] ?? 'Pasien';
    final message = Uri.encodeComponent(
      'Halo $ahliGiziName, saya $pasienName. Saya ingin berkonsultasi mengenai program diet saya melalui aplikasi ClinicalDiet. Terima kasih.'
    );

    final uri = Uri.parse('https://wa.me/$phone?text=$message');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tidak dapat membuka WhatsApp. Pastikan WhatsApp sudah terinstall.',
            style: GoogleFonts.manrope(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showUpdateBBTBDialog() {
    final weightCtrl = TextEditingController(text: _user?['weight']?.toString() ?? '');
    final heightCtrl = TextEditingController(text: _user?['height']?.toString() ?? '');
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Catat BB & TB',
                  style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text('Perbarui data fisik Anda untuk memantau IMT harian.',
                  style: GoogleFonts.manrope(
                      fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: weightCtrl,
                      keyboardType: TextInputType.number,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: 'Berat Badan',
                        hintText: 'Masukkan berat badan',
                        suffixText: 'kg',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: heightCtrl,
                      keyboardType: TextInputType.number,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: 'Tinggi Badan',
                        hintText: 'Masukkan tinggi badan',
                        suffixText: 'cm',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final weight = double.tryParse(weightCtrl.text);
                          final height = double.tryParse(heightCtrl.text);

                          if (weight == null || height == null) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Masukkan nilai yang valid', style: GoogleFonts.manrope()), backgroundColor: Colors.red));
                            return;
                          }

                          setStateDialog(() => isLoading = true);

                          try {
                            final rm = _user?['rm'];
                            final success = await AuthService.updatePasienBBTB(rm, weight, height);

                            if (success) {
                              weightCtrl.dispose();
                              heightCtrl.dispose();
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              await _loadUser();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data berhasil diperbarui!', style: GoogleFonts.manrope()), backgroundColor: AppColors.primary));
                            } else {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memperbarui data.', style: GoogleFonts.manrope()), backgroundColor: Colors.red));
                            }
                          } finally {
                            setStateDialog(() => isLoading = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('SIMPAN', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _selectedRating = 5;

  void _showRatingDialog() {
    final reviewCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Beri Rating Ahli Gizi',
              style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Seberapa puas Anda dengan pelayanan ahli gizi Anda?',
                    style: GoogleFonts.manrope(
                        fontSize: 14, color: AppColors.textSecondary),
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        setStateDialog(() {
                          _selectedRating = index + 1;
                        });
                      },
                      icon: Icon(
                        index < _selectedRating ? Icons.star : Icons.star_border,
                        color: const Color(0xFFF59E0B),
                        size: 32,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reviewCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Tuliskan ulasan Anda (opsional)...',
                    hintStyle: GoogleFonts.manrope(color: AppColors.textMuted, fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal',
                  style: GoogleFonts.manrope(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () async {
                final ulasan = reviewCtrl.text.trim();
                Navigator.pop(context);
                
                if (_selectedAhliGizi != null) {
                  await AuthService.submitRatingAhliGizi(
                    _selectedAhliGizi!['nip'], 
                    _selectedRating.toDouble(), 
                    ulasan: ulasan,
                    pasienName: _user?['name'] ?? 'Pasien'
                  );
                } else {
                  final ahliGiziList = await AuthService.getAllAhliGizi();
                  if (ahliGiziList.isNotEmpty) {
                    final ag = ahliGiziList.first;
                    await AuthService.submitRatingAhliGizi(
                      ag['nip'], 
                      _selectedRating.toDouble(),
                      ulasan: ulasan,
                      pasienName: _user?['name'] ?? 'Pasien'
                    );
                  }
                }

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Terima kasih atas ulasan dan penilaian Anda!',
                      style: GoogleFonts.manrope()),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Kirim',
                  style: GoogleFonts.manrope(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _user?['name'] ?? '');
    final usernameCtrl = TextEditingController(text: _user?['username'] ?? '');
    final phoneCtrl = TextEditingController(text: _user?['phone'] ?? '');
    final emailCtrl = TextEditingController(text: _user?['email'] ?? '');
    final nikCtrl = TextEditingController(text: _user?['nik'] ?? '');
    final agamaCtrl = TextEditingController(text: _user?['agama'] ?? '');
    final alamatCtrl = TextEditingController(text: _user?['alamat'] ?? '');
    final pendidikanCtrl = TextEditingController(text: _user?['pendidikan'] ?? '');
    final pekerjaanCtrl = TextEditingController(text: _user?['pekerjaan'] ?? '');
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Edit Profil',
                        style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildDialogTextField(nameCtrl, 'Nama Lengkap'),
                        _buildDialogTextField(usernameCtrl, 'Username'),
                        _buildDialogTextField(phoneCtrl, 'No. Telepon'),
                        _buildDialogTextField(emailCtrl, 'Email', keyboardType: TextInputType.emailAddress),
                        _buildDialogTextField(nikCtrl, 'NIK', maxLength: 16, keyboardType: TextInputType.number),
                        _buildDialogTextField(agamaCtrl, 'Agama'),
                        _buildDialogTextField(pendidikanCtrl, 'Pendidikan Terakhir'),
                        _buildDialogTextField(pekerjaanCtrl, 'Pekerjaan'),
                        _buildDialogTextField(alamatCtrl, 'Alamat', maxLines: 3),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            final bool? confirm = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: Text('Simpan Perubahan?', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                                  content: Text('Apakah Anda yakin ingin menyimpan perubahan identitas ini?', style: GoogleFonts.manrope(color: AppColors.textSecondary)),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: Text('Tidak', style: GoogleFonts.manrope(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: Text('Ya, Simpan', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirm != true) return;

                            setStateDialog(() => isLoading = true);
                            try {
                              final rm = _user?['rm'];
                              if (rm != null) {
                                final success = await AuthService.updatePasienProfile(
                                  rm: rm,
                                  name: nameCtrl.text.trim(),
                                  username: usernameCtrl.text.trim(),
                                  phone: phoneCtrl.text.trim(),
                                  email: emailCtrl.text.trim(),
                                  nik: nikCtrl.text.trim(),
                                  agama: agamaCtrl.text.trim(),
                                  alamat: alamatCtrl.text.trim(),
                                  pendidikan: pendidikanCtrl.text.trim(),
                                  pekerjaan: pekerjaanCtrl.text.trim(),
                                );

                                if (success) {
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  await _loadUser();
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profil berhasil diperbarui.', style: GoogleFonts.manrope()), backgroundColor: AppColors.primary));
                                } else {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memperbarui profil (Username mungkin sudah dipakai).', style: GoogleFonts.manrope()), backgroundColor: Colors.red));
                                }
                              }
                            } finally {
                              setStateDialog(() => isLoading = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('SIMPAN PERUBAHAN', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogTextField(TextEditingController controller, String label, {int maxLines = 1, int? maxLength, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        style: GoogleFonts.manrope(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.manrope(fontSize: 14, color: AppColors.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  void _showChangeAuthDialog() {
    final emailCtrl = TextEditingController(text: _user?['email'] ?? '');
    final passwordCtrl = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ganti Email & Password',
                  style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              _buildDialogTextField(emailCtrl, 'Email Baru'),
              _buildDialogTextField(passwordCtrl, 'Password Baru (Kosongkan jika tidak ganti)'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setStateDialog(() => isLoading = true);
                          try {
                            final rm = _user?['rm'];
                            if (rm != null) {
                              final success = await AuthService.updatePasienEmailPassword(
                                rm: rm,
                                email: emailCtrl.text.trim(),
                                password: passwordCtrl.text.trim(),
                              );

                              if (success) {
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                await _loadUser();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Email/Password berhasil diperbarui.', style: GoogleFonts.manrope()), backgroundColor: AppColors.primary));
                              } else {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memperbarui pengaturan keamanan.', style: GoogleFonts.manrope()), backgroundColor: Colors.red));
                              }
                            }
                          } finally {
                            setStateDialog(() => isLoading = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('SIMPAN', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Konfirmasi Logout', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
        content: Text('Apakah Anda yakin ingin keluar dari akun?', style: GoogleFonts.manrope(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.logout();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
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

  void _showAhliGiziCV() {
    if (_selectedAhliGizi == null) return;
    final ag = _selectedAhliGizi!;

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
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          (ag['name'] as String? ?? 'A').substring(0, 1).toUpperCase(),
                          style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF0284C7)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ag['name'] ?? 'Ahli Gizi', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          Text(ag['spesialisasi'] ?? 'Ahli Gizi Klinis', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0284C7))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Curriculum Vitae', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const Divider(),
                _buildCvItem(Icons.school_outlined, 'Pendidikan', ag['pendidikan']),
                _buildCvItem(Icons.business_outlined, 'Instansi / Tempat Praktik', ag['instansi']),
                _buildCvItem(Icons.calendar_today_outlined, 'Tahun Lulus', ag['tahunLulus']),
                _buildCvItem(Icons.work_outline, 'Pengalaman Kerja', ag['pengalamanKerja']),
                _buildCvItem(Icons.badge_outlined, 'No. STR', ag['noStr']),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.divider),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Tutup', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCvItem(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text((value == null || value.isEmpty) ? 'Belum dilengkapi' : value, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weight = (_user?['weight'] as num?)?.toDouble() ?? 0;
    final height = (_user?['height'] as num?)?.toDouble() ?? 0;
    
    double bmi = 0;
    String bmiStatus = 'N/A';
    Color bmiColor = AppColors.textMuted;
    
    if (weight > 0 && height > 0) {
      final heightM = height / 100;
      bmi = weight / (heightM * heightM);
      if (bmi < 18.5) {
        bmiStatus = 'KURANG';
        bmiColor = Colors.orange;
      } else if (bmi >= 18.5 && bmi < 25) {
        bmiStatus = 'NORMAL';
        bmiColor = AppColors.primary;
      } else if (bmi >= 25 && bmi < 30) {
        bmiStatus = 'BERLEBIH';
        bmiColor = Colors.orange;
      } else {
        bmiStatus = 'OBESITAS';
        bmiColor = AppColors.red;
      }
    }

    final profilePhoto = _user?['profile_photo_path'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/icon.png',
                      width: 30,
                      height: 30,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Clinical Diet',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.notifications_outlined,
                    color: AppColors.textSecondary),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6EE7B7), Color(0xFF10B981)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                                color: AppColors.primaryLight, width: 3),
                          ),
                          child: ClipOval(
                            child: profilePhoto != null && profilePhoto.isNotEmpty
                                ? Image.file(File(profilePhoto), fit: BoxFit.cover)
                                : const Icon(Icons.person, color: Colors.white, size: 48),
                          ),
                        ),
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
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _user?['name'] ?? 'Memuat...',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID Pasien: #CD-${_user?['rm'] ?? '...'}',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(child: _buildBodyStat('BERAT BADAN', weight > 0 ? weight.toString() : '-', 'kg')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildBodyStat('TINGGI BADAN', height > 0 ? height.toString() : '-', 'cm')),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border(
                        left: BorderSide(color: bmiColor, width: 4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'IMT SAAT INI',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.1,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              bmi > 0 ? bmi.toStringAsFixed(1) : '-',
                              style: GoogleFonts.manrope(
                                fontSize: 26,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (bmi > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: bmiColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  bmiStatus,
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: bmiColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showUpdateBBTBDialog,
                      icon: const Icon(Icons.monitor_weight_outlined, size: 18, color: AppColors.primary),
                      label: Text('Catat BB & TB Hari Ini', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: AppColors.primary)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _launchWhatsApp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366), // WhatsApp green
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chat_rounded,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedAhliGizi != null
                                      ? 'Chat dengan ${_selectedAhliGizi!['name']}'
                                      : 'Chat WhatsApp dengan Ahli Gizi',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedAhliGizi != null
                                      ? 'AHLI GIZI KLINIS'
                                      : 'PILIH AHLI GIZI TERLEBIH DAHULU',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.85),
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_selectedAhliGizi != null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showAhliGiziCV,
                        icon: const Icon(Icons.badge_outlined, size: 18, color: AppColors.primary),
                        label: Text('Lihat Profil & CV Ahli Gizi', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: AppColors.primary)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  if (_selectedAhliGizi != null) const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showRatingDialog,
                      icon: const Icon(Icons.star_outline, size: 20, color: Color(0xFFD97706)),
                      label: Text('Beri Rating & Ulasan Ahli Gizi', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: const Color(0xFFD97706))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFDE68A)),
                        backgroundColor: const Color(0xFFFEF3C7),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
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
                      'AKUN & PENGATURAN',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildActionItem(
                          icon: Icons.person_outline,
                          title: 'Edit Identitas',
                          onTap: _showEditProfileDialog,
                        ),
                        _divider(),
                        _buildActionItem(
                          icon: Icons.sync_alt,
                          title: 'Ubah Program Diet & Ahli Gizi',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PilihJenisDietScreen(isFromProfil: true),
                              ),
                            ).then((_) => _loadUser());
                          },
                        ),
                        _divider(),
                        _buildActionItem(
                          icon: Icons.track_changes_outlined,
                          title: 'Target Diet (Segera)',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'KEAMANAN',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildActionItem(
                          icon: Icons.lock_outline,
                          title: 'Ganti Email & Password',
                          onTap: _showChangeAuthDialog,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Center(
                    child: TextButton.icon(
                      onPressed: _showLogoutConfirmation,
                      icon: const Icon(Icons.logout,
                          color: AppColors.red, size: 18),
                      label: Text(
                        'KELUAR AKUN',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.red,
                          letterSpacing: 1,
                        ),
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

  Widget _buildBodyStat(String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Divider(height: 1, thickness: 1, color: AppColors.divider, indent: 56);

  Widget _buildActionItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 18),
      ),
      title: Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      trailing:
          const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
      onTap: onTap,
    );
  }
}
