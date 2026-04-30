import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'pilih_jenis_diet_screen.dart';

class InformConsentScreen extends StatefulWidget {
  const InformConsentScreen({super.key});

  @override
  State<InformConsentScreen> createState() => _InformConsentScreenState();
}

class _InformConsentScreenState extends State<InformConsentScreen> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2.5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  bool _isSaving = false;
  bool _hasRead = false;
  bool _hasSigned = false;

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  void _onSignatureChanged() {
    if (!_hasSigned && _signatureController.isNotEmpty) {
      setState(() => _hasSigned = true);
    }
  }

  Future<void> _saveConsent() async {
    if (!_hasRead) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Harap baca dan centang pernyataan persetujuan terlebih dahulu.', style: GoogleFonts.manrope()),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Harap buat tanda tangan terlebih dahulu.', style: GoogleFonts.manrope()),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final user = await AuthService.getLoggedInUser();
      if (user == null) return;

      String signaturePath = '';

      if (!kIsWeb) {
        // Mobile/Desktop: simpan file tanda tangan sebagai PNG
        final bytes = await _signatureController.toPngBytes();
        if (bytes == null) return;

        final dir = await getApplicationDocumentsDirectory();
        signaturePath = '${dir.path}/consent_${user['rm']}.png';
        final file = File(signaturePath);
        await file.writeAsBytes(bytes);
      }
      // Web: skip penyimpanan file (path_provider tidak support web),
      // cukup tandai consent sebagai sudah ditandatangani

      await AuthService.saveInformConsent(user['rm'] as String, signaturePath);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const PilihJenisDietScreen(isFromProfil: false),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e', style: GoogleFonts.manrope()),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset('assets/images/icon.png', width: 28, height: 28),
            const SizedBox(width: 8),
            Text('Inform Consent',
                style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.assignment_outlined, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Surat Persetujuan', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                              Text('Baca dan tandatangani sebelum melanjutkan', style: GoogleFonts.manrope(fontSize: 11, color: Colors.white.withValues(alpha: 0.85))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Isi consent
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SURAT PERSETUJUAN PROGRAM DIET',
                            style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 0.5)),
                        const Divider(height: 20),
                        _consentParagraph(
                          'Saya dengan ini menyatakan bahwa saya telah memahami dan menyetujui untuk mengikuti Program Diet Klinik yang diselenggarakan oleh Clinical Diet.'
                        ),
                        _consentParagraph(
                          'Saya memahami bahwa program ini melibatkan pemantauan asupan makanan, berat badan, tinggi badan, dan parameter gizi lainnya oleh ahli gizi yang telah ditunjuk.'
                        ),
                        _consentPoint('1.', 'Saya bersedia untuk mengisi catatan makan harian secara jujur dan tepat waktu.'),
                        _consentPoint('2.', 'Saya memahami bahwa apabila tidak mengisi catatan makan selama 3 (tiga) hari berturut-turut, saya akan dinyatakan GUGUR dari program dan tidak dapat menggunakan aplikasi hingga dikonfirmasi ulang oleh ahli gizi.'),
                        _consentPoint('3.', 'Saya bersedia memberikan data kesehatan yang akurat, termasuk berat badan dan tinggi badan secara berkala.'),
                        _consentPoint('4.', 'Saya memahami bahwa data saya akan digunakan untuk keperluan pemantauan gizi dan tidak akan disebarluaskan kepada pihak ketiga tanpa izin.'),
                        _consentPoint('5.', 'Saya berhak untuk mengundurkan diri dari program dengan memberitahukan ahli gizi terlebih dahulu.'),
                        _consentPoint('6.', 'Saya memahami bahwa rekomendasi dalam aplikasi ini bersifat edukatif dan tidak menggantikan konsultasi medis langsung.'),
                        const SizedBox(height: 8),
                        _consentParagraph(
                          'Dengan menandatangani dokumen ini, saya menyatakan bahwa saya telah membaca, memahami, dan menyetujui seluruh ketentuan di atas.'
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Checkbox persetujuan
                  GestureDetector(
                    onTap: () => setState(() => _hasRead = !_hasRead),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _hasRead ? AppColors.primaryLight : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _hasRead ? AppColors.primary : AppColors.divider,
                          width: _hasRead ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: _hasRead ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _hasRead ? AppColors.primary : AppColors.textMuted,
                                width: 2,
                              ),
                            ),
                            child: _hasRead
                                ? const Icon(Icons.check, color: Colors.white, size: 14)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Saya telah membaca dan menyetujui seluruh ketentuan di atas',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _hasRead ? AppColors.primaryDark : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Area tanda tangan
                  Text('TANDA TANGAN',
                      style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _hasSigned ? AppColors.primary : AppColors.divider,
                        width: _hasSigned ? 1.5 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Signature(
                        controller: _signatureController,
                        height: 180,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tanda tangan di area putih di atas',
                          style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textMuted)),
                      TextButton.icon(
                        onPressed: () {
                          _signatureController.clear();
                          setState(() => _hasSigned = false);
                        },
                        icon: const Icon(Icons.refresh, size: 16, color: AppColors.textSecondary),
                        label: Text('Hapus', style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textSecondary)),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Info notifikasi
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Jika tidak mengisi catatan makan 3 hari berturut-turut, akun akan dinyatakan gugur.',
                            style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF92400E), height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Bottom button
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : () {
                  _signatureController.addListener(_onSignatureChanged);
                  _saveConsent();
                },
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.verified_outlined, color: Colors.white),
                label: Text(
                  _isSaving ? 'MENYIMPAN...' : 'SETUJU & MULAI PROGRAM',
                  style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _consentParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
    );
  }

  Widget _consentPoint(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(number, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ),
          Expanded(
            child: Text(text, style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
          ),
        ],
      ),
    );
  }
}
