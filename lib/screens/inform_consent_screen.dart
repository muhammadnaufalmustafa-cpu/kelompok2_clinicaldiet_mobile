import 'dart:convert';
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
      String? signatureBase64;
      String? consentDocBase64; // Dokumen HTML lengkap

      final bytes = await _signatureController.toPngBytes();
      if (bytes == null) return;

      final sigBase64 = base64Encode(bytes);

      if (kIsWeb) {
        // Web: simpan tanda tangan sebagai base64
        signatureBase64 = sigBase64;
      } else {
        // Mobile/Desktop: simpan file tanda tangan sebagai PNG
        final dir = await getApplicationDocumentsDirectory();
        signaturePath = '${dir.path}/consent_${user['rm']}.png';
        final file = File(signaturePath);
        await file.writeAsBytes(bytes);
        signatureBase64 = sigBase64; // juga simpan base64 untuk dokumen HTML
      }

      // Generate dokumen HTML lengkap (isi + centang + tanda tangan)
      final signedAt = DateTime.now();
      final signedDateStr =
          '${signedAt.day.toString().padLeft(2, '0')}/${signedAt.month.toString().padLeft(2, '0')}/${signedAt.year} '
          '${signedAt.hour.toString().padLeft(2, '0')}:${signedAt.minute.toString().padLeft(2, '0')} WIB';
      final patientName = user['name'] ?? '-';
      final patientRm = user['rm'] ?? '-';

      consentDocBase64 = _generateConsentHtml(
        patientName: patientName,
        patientRm: patientRm,
        signedDateStr: signedDateStr,
        signatureBase64: sigBase64,
      );

      await AuthService.saveInformConsent(
        user['rm'] as String,
        signaturePath,
        signatureBase64: signatureBase64,
        consentDocBase64: consentDocBase64,
      );

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

  /// Generate dokumen HTML lengkap informed consent
  String _generateConsentHtml({
    required String patientName,
    required String patientRm,
    required String signedDateStr,
    required String signatureBase64,
  }) {
    final htmlContent = '''<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Informed Consent - $patientName</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: 'Segoe UI', Arial, sans-serif; background: #f8fafc; color: #1e293b; padding: 32px; }
    .page { max-width: 800px; margin: 0 auto; background: #fff; border-radius: 16px; box-shadow: 0 4px 24px rgba(0,0,0,0.10); padding: 48px 56px; }
    .header { text-align: center; border-bottom: 3px solid #3B7A57; padding-bottom: 24px; margin-bottom: 32px; }
    .logo-title { font-size: 22px; font-weight: 800; color: #3B7A57; letter-spacing: 1px; margin-bottom: 4px; }
    .subtitle { font-size: 13px; color: #64748b; }
    .doc-title { font-size: 18px; font-weight: 700; color: #1e293b; text-align: center; margin-bottom: 24px; letter-spacing: 0.5px; text-transform: uppercase; }
    .patient-info { background: #f1faf5; border: 1px solid #bbf0d4; border-radius: 10px; padding: 16px 20px; margin-bottom: 28px; }
    .patient-info table { width: 100%; border-collapse: collapse; }
    .patient-info td { padding: 5px 8px; font-size: 14px; }
    .patient-info td:first-child { color: #64748b; width: 150px; }
    .patient-info td:last-child { font-weight: 600; color: #1e293b; }
    .section-label { font-size: 12px; font-weight: 700; color: #3B7A57; letter-spacing: 1.2px; text-transform: uppercase; margin-bottom: 10px; }
    .consent-box { border: 1px solid #e2e8f0; border-radius: 10px; padding: 20px 24px; margin-bottom: 24px; background: #fafafa; }
    p { font-size: 14px; color: #475569; line-height: 1.7; margin-bottom: 10px; }
    .point-row { display: flex; gap: 10px; margin-bottom: 8px; }
    .point-num { font-size: 14px; font-weight: 700; color: #3B7A57; min-width: 24px; }
    .point-text { font-size: 14px; color: #475569; line-height: 1.6; }
    .agreement-box { background: #f0fdf4; border: 2px solid #3B7A57; border-radius: 10px; padding: 14px 18px; margin-bottom: 24px; display: flex; align-items: center; gap: 12px; }
    .check-icon { width: 24px; height: 24px; background: #3B7A57; border-radius: 6px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
    .check-icon svg { width: 14px; height: 14px; }
    .agreement-text { font-size: 14px; font-weight: 600; color: #166534; line-height: 1.5; }
    .signature-section { margin-bottom: 32px; }
    .signature-label { font-size: 12px; font-weight: 700; color: #64748b; letter-spacing: 1.2px; text-transform: uppercase; margin-bottom: 10px; }
    .signature-box { border: 1.5px solid #3B7A57; border-radius: 12px; padding: 12px; background: #fff; display: inline-block; }
    .signature-box img { max-width: 100%; height: auto; max-height: 180px; display: block; border-radius: 6px; background: #fff; }
    .footer { border-top: 2px solid #e2e8f0; padding-top: 20px; margin-top: 32px; display: flex; justify-content: space-between; align-items: flex-end; }
    .signed-info { font-size: 12px; color: #64748b; }
    .signed-info strong { color: #1e293b; font-weight: 700; }
    .verified-badge { background: #dcfce7; border: 1px solid #86efac; border-radius: 20px; padding: 6px 14px; font-size: 12px; font-weight: 700; color: #16a34a; }
    @media print {
      body { background: #fff; padding: 0; }
      .page { box-shadow: none; border-radius: 0; padding: 32px; }
    }
  </style>
</head>
<body>
  <div class="page">
    <div class="header">
      <div class="logo-title">🏥 Clinical Diet</div>
      <div class="subtitle">Sistem Pemantauan Gizi Klinik</div>
    </div>

    <div class="doc-title">Surat Persetujuan Program Diet<br><span style="font-size:13px;font-weight:500;color:#64748b;text-transform:none;letter-spacing:0">Informed Consent</span></div>

    <div class="patient-info">
      <div class="section-label">Data Pasien</div>
      <table>
        <tr><td>Nama Lengkap</td><td>: $patientName</td></tr>
        <tr><td>No. Rekam Medis</td><td>: $patientRm</td></tr>
        <tr><td>Tanggal Tanda Tangan</td><td>: $signedDateStr</td></tr>
      </table>
    </div>

    <div class="section-label">Isi Persetujuan</div>
    <div class="consent-box">
      <p>Saya dengan ini menyatakan bahwa saya telah memahami dan menyetujui untuk mengikuti Program Diet Klinik yang diselenggarakan oleh Clinical Diet.</p>
      <p>Saya memahami bahwa program ini melibatkan pemantauan asupan makanan, berat badan, tinggi badan, dan parameter gizi lainnya oleh ahli gizi yang telah ditunjuk.</p>
      <div class="point-row"><span class="point-num">1.</span><span class="point-text">Saya bersedia untuk mengisi catatan makan harian secara jujur dan tepat waktu.</span></div>
      <div class="point-row"><span class="point-num">2.</span><span class="point-text">Saya memahami bahwa apabila tidak mengisi catatan makan selama 3 (tiga) hari berturut-turut, saya akan dinyatakan GUGUR dari program dan tidak dapat menggunakan aplikasi hingga dikonfirmasi ulang oleh ahli gizi.</span></div>
      <div class="point-row"><span class="point-num">3.</span><span class="point-text">Saya bersedia memberikan data kesehatan yang akurat, termasuk berat badan dan tinggi badan secara berkala.</span></div>
      <div class="point-row"><span class="point-num">4.</span><span class="point-text">Saya memahami bahwa data saya akan digunakan untuk keperluan pemantauan gizi dan tidak akan disebarluaskan kepada pihak ketiga tanpa izin.</span></div>
      <div class="point-row"><span class="point-num">5.</span><span class="point-text">Saya berhak untuk mengundurkan diri dari program dengan memberitahukan ahli gizi terlebih dahulu.</span></div>
      <div class="point-row"><span class="point-num">6.</span><span class="point-text">Saya memahami bahwa rekomendasi dalam aplikasi ini bersifat edukatif dan tidak menggantikan konsultasi medis langsung.</span></div>
      <p style="margin-top:12px">Dengan menandatangani dokumen ini, saya menyatakan bahwa saya telah membaca, memahami, dan menyetujui seluruh ketentuan di atas.</p>
    </div>

    <div class="agreement-box">
      <div class="check-icon">
        <svg viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M2 7L5.5 10.5L12 3.5" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      </div>
      <div class="agreement-text">✔ Saya telah membaca dan menyetujui seluruh ketentuan di atas</div>
    </div>

    <div class="signature-section">
      <div class="signature-label">Tanda Tangan Pasien</div>
      <div class="signature-box">
        <img src="data:image/png;base64,$signatureBase64" alt="Tanda Tangan $patientName" />
      </div>
      <p style="margin-top:8px;font-size:12px;color:#94a3b8;">Tanda tangan digital di atas dibuat oleh pasien pada $signedDateStr</p>
    </div>

    <div class="footer">
      <div class="signed-info">
        <div>Ditandatangani secara digital oleh:</div>
        <div><strong>$patientName</strong> &nbsp;|&nbsp; RM: $patientRm</div>
        <div>Tanggal: $signedDateStr</div>
      </div>
      <div class="verified-badge">✓ Terverifikasi</div>
    </div>
  </div>
</body>
</html>''';
    return base64Encode(utf8.encode(htmlContent));
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
