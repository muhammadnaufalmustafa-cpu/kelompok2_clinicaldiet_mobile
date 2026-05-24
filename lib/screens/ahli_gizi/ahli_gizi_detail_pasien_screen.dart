import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../utils/age_calculator.dart';
import 'laporan_harian_ag_screen.dart';
import '../../services/firebase_notification_service.dart';
import '../../services/notification_service.dart';

class AhliGiziDetailPasienScreen extends StatefulWidget {
  final Map<String, dynamic> pasien;
  const AhliGiziDetailPasienScreen({super.key, required this.pasien});

  @override
  State<AhliGiziDetailPasienScreen> createState() =>
      _AhliGiziDetailPasienScreenState();
}

class _AhliGiziDetailPasienScreenState
    extends State<AhliGiziDetailPasienScreen> {
  late String _status;
  bool _isSaving = false;
  List<Map<String, dynamic>> _riwayatMakan = [];
  String? _selectedDietType; // Jenis diet yang sedang diedit
  int _missedDays = 0; // jumlah hari tidak isi log

  // ---Â---Â--- Patient Therapy Programs ---Â---Â---
  List<Map<String, dynamic>> _patientPrograms = [];
  Map<String, dynamic>? _selectedPatientProgram;
  bool _isLoadingPrograms = false;
  List<Map<String, dynamic>> _availableTherapyPrograms = [];

  // ---Â ---Â --- Existing controllers ---Â ---Â ---
  final _targetCtrl = TextEditingController();

  // ---Â ---Â --- Clinical Inputs ---Â ---Â ---
  final _diagnosisCtrl = TextEditingController();
  final _catatanNutrisiCtrl = TextEditingController();
  final _customDietCtrl = TextEditingController();
  final _evaluasiHarianCtrl = TextEditingController();

  // Poin 3 & 6: Status Gizi Manual dan kunci dinamis
  String? _statusGiziManual; // Dipilih oleh Ahli Gizi

  static const List<String> _statusGiziOptions = [
    'Gizi Baik',
    'Gizi Kurang',
    'Gizi Buruk',
    'Gizi Lebih',
    'Obesitas',
    'Berisiko Gizi Lebih',
    'Tidak Terkategorikan',
  ];

  final _imtManualCtrl = TextEditingController();

  final List<String> _terapiDietList = [
    'Diet Normal',
    'Diet Rendah Garam',
    'Diet Rendah Gula',
    'Diet Rendah Lemak',
    'Diet Tinggi Protein',
    'Diet Diabetes Mellitus',
    'Diet Hipertensi',
    'Diet Jantung',
    'Diet Ginjal',
    'Diet Hati',
    'Diet Rendah Purin',
    'Diet Tinggi Kalori Tinggi Protein',
    'Diet Khusus/Lainnya',
  ];

  static const List<String> _icd10List = [
    'E11.9 - Diabetes Mellitus Tipe 2 tanpa Komplikasi',
    'I10 - Hipertensi Esensial (Primer)',
    'E66.9 - Obesitas, tidak Spesifik',
    'E44.0 - Malnutrisi Energi-Protein Sedang',
    'N18.9 - Penyakit Ginjal Kronis, tidak Spesifik',
    'K74.6 - Sirosis Hati lainnya dan tidak Spesifik',
    'E78.5 - Hiperlipidemia, tidak Spesifik',
    'Z71.3 - Konseling dan Pengawasan Diet',
    'K21.9 - Penyakit Refluks Gastroesofagus (GERD) tanpa Esofagitis',
    'M10.9 - Gout, tidak Spesifik',
    'E10.9 - Diabetes Mellitus Tipe 1 tanpa Komplikasi',
    'I25.1 - Penyakit Jantung Aterosklerotik',
    'K52.9 - Gastroenteritis dan Kolitis Non-infeksi, tidak Spesifik',
    'R63.4 - Penurunan Berat Badan yang Tidak Diinginkan',
    'D64.9 - Anemia, tidak Spesifik',
    'K29.7 - Gastritis, tidak Spesifik',
    'E11.65 - Diabetes Mellitus Tipe 2 dengan Hiperglikemia',
    'I20.9 - Angina Pektoris, tidak Spesifik',
    'K58.9 - Irritable Bowel Syndrome (IBS) tanpa Diare',
  ];

  // ---Â ---Â --- Dynamic Nutrition Target controllers & state ---Â ---Â ---
  final Map<String, TextEditingController> _targetCtrls = {};
  final Map<String, TextEditingController> _aktualCtrls = {};
  final Map<String, bool> _checkedNutrients = {};

  static const Map<String, List<String>> _nutrientCategories = {
    'Makronutrien dan Cairan': [
      'Energi (kkal)',
      'Protein (g)',
      'Lemak (g)',
      'Karbohidrat (g)',
      'Serat (g)',
      'Air (ml)',
    ],
    'Mineral': [
      'Kalsium (mg)',
      'Fosfor (mg)',
      'Magnesium (mg)',
      'Besi (mg)',
      'Iodium (mcg)',
      'Seng (mg)',
      'Selenium (mcg)',
      'Mangan (mg)',
      'Fluor (mg)',
      'Kromium (mcg)',
      'Kalium (mg)',
      'Natrium (mg)',
      'Klor (mg)',
      'Tembaga (mcg)',
    ],
    'Vitamin': [
      'Vitamin A / Vit A (RE)',
      'Vitamin D (mcg)',
      'Vitamin E (mcg)',
      'Vitamin K (mcg)',
      'Vitamin B1 (mg)',
      'Vitamin B2 (mg)',
      'Vitamin B3 (mg)',
      'Vitamin B5 / Pantotenat (mg)',
      'Vitamin B6 (mg)',
      'Folat (mcg)',
      'Vitamin B12 (mcg)',
      'Biotin (mcg)',
      'Kolin (mg)',
      'Vitamin C (mg)',
    ],
  };

  @override
  void initState() {
    super.initState();
    _status = widget.pasien['status'] ?? 'aktif';
    _targetCtrl.text = widget.pasien['target_diet'] ?? '';
    _diagnosisCtrl.text = widget.pasien['diagnosis'] ?? '';
    _statusGiziManual = widget.pasien['status_gizi_manual'];
    _imtManualCtrl.text = widget.pasien['imt_manual']?.toString() ?? '';

    _loadInitialData();
    _checkMissedLogs();
  }

  Future<void> _checkMissedLogs() async {
    final agUser = await AuthService.getLoggedInUser();
    if (agUser == null) return;
    final result = await FirebaseNotificationService.checkPatientMissedLogs(
      patientRm: widget.pasien['rm'] as String? ?? '',
      patientId: widget.pasien['uid'] as String? ?? '',
      patientName: widget.pasien['name'] as String? ?? 'Pasien',
      ahliGiziId: agUser['uid'] as String? ?? '',
      ahliGiziName: agUser['name'] as String? ?? 'Ahli Gizi',
    );
    if (mounted)
      setState(() => _missedDays = result['missedDays'] as int? ?? 0);
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingPrograms = true);

    // 1. Load therapy programs from new collection
    final programs = await AuthService.getTherapyPrograms();
    if (mounted && programs.isNotEmpty) {
      final newTitles = programs
          .map((p) => p['name'] as String? ?? '')
          .toList();
      for (var title in newTitles) {
        if (!_terapiDietList.contains(title)) {
          _terapiDietList.insert(_terapiDietList.length - 1, title);
        }
      }
    }

    // 2. Load patient therapy programs
    final patientId = widget.pasien['uid'] as String? ?? '';
    if (patientId.isNotEmpty) {
      try {
        final freshSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(patientId)
            .get();
        if (freshSnap.exists && freshSnap.data() != null) {
          widget.pasien.addAll(freshSnap.data()!);
        }
      } catch (e) {
        /* fail silently */
      }
    }

    final rm = widget.pasien['rm'] as String? ?? '';
    List<Map<String, dynamic>> patientPrograms = [];
    if (patientId.isNotEmpty) {
      patientPrograms = await AuthService.getPatientTherapyPrograms(patientId);
    }
    if (patientPrograms.isEmpty && rm.isNotEmpty) {
      final rmProgs = await AuthService.getPatientTherapyProgramsByRm(rm);
      patientPrograms = rmProgs.where((p) {
        final progUid = p['patientId'] as String? ?? '';
        return progUid.isEmpty || progUid == patientId;
      }).toList();
    }

    // [FIX Bug 1] Jika program kosong, baca diet_types (array) dari onboarding
    // Buat SATU virtual program PER item agar tampil terpisah di UI
    if (patientPrograms.isEmpty) {
      final raw = widget.pasien['diet_types'];
      List<String> dietList = [];
      if (raw is List && raw.isNotEmpty) {
        dietList = raw.cast<String>();
      } else {
        final single = widget.pasien['diet_type'] as String? ?? '';
        if (single.isNotEmpty && single != '(Belum ada diet)') {
          dietList = [single];
        }
      }
      for (int i = 0; i < dietList.length; i++) {
        patientPrograms.add({
          'patientProgramId': 'initial_onboarding_$i',
          'therapyProgramName': dietList[i],
          'status': 'active',
          'isInitial': true,
        });
      }
    }

    if (mounted) {
      setState(() {
        _availableTherapyPrograms = programs;
        _patientPrograms = patientPrograms;
        _isLoadingPrograms = false;
        // Auto-select first active program
        final active = patientPrograms
            .where((p) => p['status'] == 'active')
            .toList();
        if (active.isNotEmpty) _selectedPatientProgram = active.first;
      });
    }

    if (_selectedPatientProgram != null) {
      await _loadNutrisiForProgram(_selectedPatientProgram!);
    } else {
      final diets = _getDietList();
      if (diets.isNotEmpty) _selectedDietType = diets.first;
      _loadNutrisi();
    }
  }

  @override
  void dispose() {
    _targetCtrl.dispose();
    _diagnosisCtrl.dispose();
    _catatanNutrisiCtrl.dispose();
    _evaluasiHarianCtrl.dispose();
    for (var c in _targetCtrls.values) {
      c.dispose();
    }
    for (var c in _aktualCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  // -Â ---Â  Regenerate Informed Consent (oleh Ahli Gizi) -Â ---Â
  Future<void> _regenerateConsent() async {
    final rm = widget.pasien['rm'] as String? ?? '';
    final name = widget.pasien['name'] as String? ?? '-';
    if (rm.isEmpty) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('rm', isEqualTo: rm)
          .where('role', isEqualTo: 'pasien')
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Data pasien tidak ditemukan.',
                style: GoogleFonts.manrope(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      final patientData = snapshot.docs.first.data();
      final signatureBase64 =
          patientData['consent_signature_base64'] as String? ?? '';
      final consentSignedAt = patientData['consent_signed_at'] as String? ?? '';
      if (signatureBase64.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Pasien belum menandatangani informed consent.',
                style: GoogleFonts.manrope(),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      String signedDateStr = 'Tanggal tidak tercatat';
      if (consentSignedAt.isNotEmpty) {
        try {
          final dt = DateTime.parse(consentSignedAt).toLocal();
          signedDateStr =
              '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} WIB';
        } catch (_) {}
      }

      // Load logo assets
      final logoNatunaData = await rootBundle.load(
        'assets/images/logo_natuna.png',
      );
      final logoKarsData = await rootBundle.load('assets/images/logo_kars.png');
      final logoNatunaBytes = logoNatunaData.buffer.asUint8List();
      final logoKarsBytes = logoKarsData.buffer.asUint8List();

      // Build PDF natively using pw package (pure Dart, no WebView needed)
      final pdfBytes = await _generateConsentPdf(
        patientName: name,
        patientRm: rm,
        signedDateStr: signedDateStr,
        signatureBase64: signatureBase64,
        logoNatunaBytes: logoNatunaBytes,
        logoKarsBytes: logoKarsBytes,
      );

      await snapshot.docs.first.reference.update({
        'consent_regenerated_at': DateTime.now().toIso8601String(),
      });

      // Save PDF to temp dir and share (works on mobile; web handled separately if needed)
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/informed_consent_$rm.pdf');
      await file.writeAsBytes(pdfBytes);

      if (!kIsWeb) {
        if (Platform.isAndroid) {
          try {
            // Simpan juga secara langsung ke folder Download publik Android
            final downloadDir = Directory('/storage/emulated/0/Download');
            if (await downloadDir.exists()) {
              final downloadFile = File(
                '${downloadDir.path}/Informed_Consent_$rm.pdf',
              );
              await downloadFile.writeAsBytes(pdfBytes);
            }
          } catch (_) {}
        }

        try {
          await NotificationService().showInstantNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: 'Unduhan Berhasil',
            body:
                'File Informed_Consent_$rm.pdf berhasil disimpan di folder Download.',
          );
        } catch (_) {}

        // Removed Share.shareXFiles
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Dokumen consent (PDF) berhasil diunduh!',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            action: SnackBarAction(
              label: 'Buka',
              textColor: Colors.white,
              onPressed: () {
                if (Platform.isAndroid || Platform.isIOS) {
                  OpenFilex.open(file.path);
                }
              },
            ),
          ),
        );

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Berhasil Diunduh',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: Text(
              'Dokumen Informed Consent (PDF) berhasil disimpan ke folder Download di HP Anda.',
              style: GoogleFonts.manrope(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Tutup',
                  style: GoogleFonts.manrope(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (Platform.isAndroid || Platform.isIOS) {
                    OpenFilex.open(file.path);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Buka File',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e', style: GoogleFonts.manrope()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {}
  }

  /// Generate PDF native menggunakan package pdf (pure Dart, tidak butuh WebView)
  Future<List<int>> _generateConsentPdf({
    required String patientName,
    required String patientRm,
    required String signedDateStr,
    required String signatureBase64,
    required Uint8List logoNatunaBytes,
    required Uint8List logoKarsBytes,
  }) async {
    final doc = pw.Document();
    final logoNatuna = pw.MemoryImage(Uint8List.fromList(logoNatunaBytes));
    final logoKars = pw.MemoryImage(Uint8List.fromList(logoKarsBytes));
    final sigBytes = base64Decode(signatureBase64);
    final sigImage = pw.MemoryImage(sigBytes);

    final PdfColor green = PdfColor.fromHex('#3B7A57');
    final PdfColor greenLight = PdfColor.fromHex('#F0FDF4');
    final PdfColor textDark = PdfColor.fromHex('#1E293B');
    final PdfColor textGrey = PdfColor.fromHex('#64748B');
    final PdfColor borderColor = PdfColor.fromHex('#E2E8F0');

    const consentPoints = [
      'Saya bersedia untuk mengisi catatan makan harian secara jujur dan tepat waktu.',
      'Saya memahami bahwa apabila tidak mengisi catatan makan selama 3 (tiga) hari berturut-turut, saya akan dinyatakan GUGUR dari program dan tidak dapat menggunakan aplikasi hingga dikonfirmasi ulang oleh ahli gizi.',
      'Saya bersedia memberikan data kesehatan yang akurat, termasuk berat badan dan tinggi badan secara berkala.',
      'Saya memahami bahwa data saya akan digunakan untuk keperluan pemantauan gizi dan tidak akan disebarluaskan kepada pihak ketiga tanpa izin.',
      'Saya berhak untuk mengundurkan diri dari program dengan memberitahukan ahli gizi terlebih dahulu.',
      'Saya memahami bahwa rekomendasi dalam aplikasi ini bersifat edukatif dan tidak menggantikan konsultasi medis langsung.',
    ];

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) => [
          // KOP SURAT
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Image(logoNatuna, height: 60),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'PEMERINTAH KABUPATEN NATUNA',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    pw.Text(
                      'DINAS KESEHATAN',
                      style: pw.TextStyle(fontSize: 10, color: textDark),
                    ),
                    pw.Text(
                      'UPTD RUMAH SAKIT UMUM DAERAH NATUNA',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Jalan H. Ali Murtopo, Kabupaten Natuna, Kepulauan Riau, 29783',
                      style: pw.TextStyle(fontSize: 8, color: textGrey),
                    ),
                    pw.Text(
                      'Telp. (0773) 3211378 | rsud.natunakab.go.id',
                      style: pw.TextStyle(fontSize: 8, color: textGrey),
                    ),
                  ],
                ),
              ),
              pw.Image(logoKars, height: 60),
            ],
          ),
          pw.Divider(thickness: 2, color: textDark),
          pw.SizedBox(height: 16),

          // JUDUL
          pw.Center(
            child: pw.Text(
              'INFORMED CONSENT MONITORING DIET',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: textDark,
                decoration: pw.TextDecoration.underline,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 16),

          // DATA PASIEN
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: greenLight,
              border: pw.Border.all(color: PdfColor.fromHex('#BBF0D4')),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'DATA PASIEN',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: green,
                    letterSpacing: 1.2,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  children: [
                    pw.SizedBox(
                      width: 140,
                      child: pw.Text(
                        'Nama Lengkap',
                        style: pw.TextStyle(fontSize: 11, color: textGrey),
                      ),
                    ),
                    pw.Text(
                      ': $patientName',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Row(
                  children: [
                    pw.SizedBox(
                      width: 140,
                      child: pw.Text(
                        'No. Rekam Medis',
                        style: pw.TextStyle(fontSize: 11, color: textGrey),
                      ),
                    ),
                    pw.Text(
                      ': $patientRm',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Row(
                  children: [
                    pw.SizedBox(
                      width: 140,
                      child: pw.Text(
                        'Tanggal Tanda Tangan',
                        style: pw.TextStyle(fontSize: 11, color: textGrey),
                      ),
                    ),
                    pw.Text(
                      ': $signedDateStr',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // ISI CONSENT
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: borderColor),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Saya dengan ini menyatakan bahwa saya telah memahami dan menyetujui untuk mengikuti Program Diet Klinik yang diselenggarakan oleh Naksihat.',
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: textGrey,
                    lineSpacing: 3,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Saya memahami bahwa program ini melibatkan pemantauan asupan makanan, berat badan, tinggi badan, dan parameter gizi lainnya oleh ahli gizi yang telah ditunjuk.',
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: textGrey,
                    lineSpacing: 3,
                  ),
                ),
                pw.SizedBox(height: 8),
                ...consentPoints.asMap().entries.map(
                  (e) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 5),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.SizedBox(
                          width: 20,
                          child: pw.Text(
                            '${e.key + 1}.',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: green,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            e.value,
                            style: pw.TextStyle(
                              fontSize: 11,
                              color: textGrey,
                              lineSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Dengan menandatangani dokumen ini, saya menyatakan bahwa saya telah membaca, memahami, dan menyetujui seluruh ketentuan di atas.',
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: textGrey,
                    lineSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // PERNYATAAN PERSETUJUAN
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: greenLight,
              border: pw.Border.all(color: green, width: 1.5),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 18,
                  height: 18,
                  decoration: pw.BoxDecoration(
                    color: green,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'V',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    'Saya telah membaca dan menyetujui seluruh ketentuan di atas',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#166534'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // TANDA TANGAN
          pw.Text(
            'TANDA TANGAN PASIEN',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: textGrey,
              letterSpacing: 1.2,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: green, width: 1.5),
              borderRadius: pw.BorderRadius.circular(8),
              color: PdfColors.white,
            ),
            child: pw.Image(sigImage, height: 100, fit: pw.BoxFit.contain),
          ),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
              'Tanda tangan digital pasien - $patientName pada $signedDateStr',
              style: pw.TextStyle(fontSize: 9, color: textGrey),
            ),
          ),
          pw.SizedBox(height: 20),

          // FOOTER
          pw.Divider(color: borderColor),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Ditandatangani secara digital oleh:',
                    style: pw.TextStyle(fontSize: 9, color: textGrey),
                  ),
                  pw.Text(
                    '$patientName  |  RM: $patientRm',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  pw.Text(
                    'Tanggal: $signedDateStr',
                    style: pw.TextStyle(fontSize: 9, color: textGrey),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#DCFCE7'),
                  border: pw.Border.all(color: PdfColor.fromHex('#86EFAC')),
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Text(
                  'Terverifikasi',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#16A34A'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return doc.save();
  }

  // HTML-based consent generation and _exportLaporanBulanan removed (replaced by native PDF flow).

  List<String> _getDietList() {
    final raw = widget.pasien['diet_types'];
    if (raw is List && raw.isNotEmpty) return raw.cast<String>();
    final single = widget.pasien['diet_type'] as String? ?? '';
    return single.isEmpty ? ['(Belum ada diet)'] : [single];
  }

  Future<void> _loadNutrisi() async {
    final rm = widget.pasien['rm'] as String? ?? '';

    // Load clinical info from widget.pasien
    if (mounted) {
      setState(() {
        _diagnosisCtrl.text = widget.pasien['diagnosis'] ?? '';
        _catatanNutrisiCtrl.text = widget.pasien['catatan_klinis'] ?? '';

        final dt = widget.pasien['diet_type'] as String? ?? 'Diet Normal';
        if (_terapiDietList.contains(dt)) {
          _selectedDietType = dt;
        } else {
          _selectedDietType = 'Diet Khusus/Lainnya';
          _customDietCtrl.text = dt;
        }
      });
    }

    if (_selectedDietType != null) {
      final String effectiveDiet = _selectedDietType == 'Diet Khusus/Lainnya'
          ? _customDietCtrl.text
          : _selectedDietType!;

      final nutrisiDiet = await AuthService.getNutrisiPasienPerDiet(
        rm,
        effectiveDiet,
      );
      if (mounted && nutrisiDiet != null) {
        setState(() {
          final Map<String, dynamic>? targetNutrients =
              nutrisiDiet['target_nutrients'];
          _checkedNutrients.clear();

          if (targetNutrients != null) {
            targetNutrients.forEach((key, val) {
              _checkedNutrients[key] = true;
              if (!_targetCtrls.containsKey(key))
                _targetCtrls[key] = TextEditingController();
              _targetCtrls[key]!.text = _fmtNum(val['target']);
              // Load aktual yang sudah diinput AG sebelumnya
              if (!_aktualCtrls.containsKey(key))
                _aktualCtrls[key] = TextEditingController();
              final aktualVal = (val['aktual'] as num?)?.toDouble() ?? 0.0;
              _aktualCtrls[key]!.text = aktualVal > 0 ? _fmtNum(aktualVal) : '';
            });
          }
        });
      }
    }

    final logs = await AuthService.getMealLogsForPasien(rm, days: 30);
    if (mounted) setState(() => _riwayatMakan = logs);
  }

  Future<void> _loadNutrisiForProgram(Map<String, dynamic> program) async {
    final patientProgramId = program['patientProgramId'] as String? ?? '';
    final programName = program['therapyProgramName'] as String? ?? '';
    final rm = widget.pasien['rm'] as String? ?? '';

    if (mounted) {
      setState(() {
        _selectedDietType = programName;
        _checkedNutrients.clear();
        for (var c in _targetCtrls.values) {
          c.clear();
        }
        for (var c in _aktualCtrls.values) {
          c.clear();
        }
      });
    }

    // 1. Coba load dari nutritionTargets (collection baru)
    final nutritionTarget = await AuthService.getNutritionTarget(
      patientProgramId,
    );
    if (mounted) {
      setState(() {
        if (nutritionTarget != null) {
          final nutrientItems =
              (nutritionTarget['nutrientItems'] as Map?)
                  ?.cast<String, dynamic>() ??
              {};
          nutrientItems.forEach((key, val) {
            _checkedNutrients[key] = true;
            if (!_targetCtrls.containsKey(key))
              _targetCtrls[key] = TextEditingController();
            _targetCtrls[key]!.text = _fmtNum(val['target']);
            if (!_aktualCtrls.containsKey(key))
              _aktualCtrls[key] = TextEditingController();
            final aktualVal = (val['aktual'] as num?)?.toDouble() ?? 0.0;
            _aktualCtrls[key]!.text = aktualVal > 0 ? _fmtNum(aktualVal) : '';
          });
          _catatanNutrisiCtrl.text =
              nutritionTarget['catatan'] ??
              widget.pasien['catatan_klinis'] ??
              '';
        } else {
          // 2. Fallback ke nutrition_plans lama berdasarkan nama program
          _diagnosisCtrl.text = widget.pasien['diagnosis'] ?? '';
          _catatanNutrisiCtrl.text = widget.pasien['catatan_klinis'] ?? '';
        }
      });
    }

    // Jika nutritionTarget null, coba fallback ke nutrition_plans lama
    if (nutritionTarget == null) {
      final legacyNutrisi = await AuthService.getNutrisiPasienPerDiet(
        rm,
        programName,
      );
      if (mounted && legacyNutrisi != null) {
        setState(() {
          final Map<String, dynamic> targetNutrients =
              legacyNutrisi['target_nutrients'] ?? {};
          targetNutrients.forEach((key, val) {
            _checkedNutrients[key] = true;
            if (!_targetCtrls.containsKey(key))
              _targetCtrls[key] = TextEditingController();
            _targetCtrls[key]!.text = _fmtNum(val['target']);
            if (!_aktualCtrls.containsKey(key))
              _aktualCtrls[key] = TextEditingController();
            final aktualVal = (val['aktual'] as num?)?.toDouble() ?? 0.0;
            _aktualCtrls[key]!.text = aktualVal > 0 ? _fmtNum(aktualVal) : '';
          });
          if (legacyNutrisi['evaluasi_ahli_gizi'] != null) {
            _catatanNutrisiCtrl.text = legacyNutrisi['evaluasi_ahli_gizi'];
          }
        });
      }
    }

    // Load meal logs: utamakan per-RM (30 hari), karena meal logs lama tidak punya patientProgramId
    final logs = await AuthService.getMealLogsForPasien(rm, days: 30);
    if (mounted) setState(() => _riwayatMakan = logs);
  }

  void _selectProgram(Map<String, dynamic> program) {
    setState(() => _selectedPatientProgram = program);
    _loadNutrisiForProgram(program);
  }

  String _fmtNum(dynamic val) {
    if (val == null) return '';
    final d = (val as num).toDouble();
    return d == d.truncateToDouble()
        ? d.toInt().toString()
        : d.toStringAsFixed(1);
  }

  Future<void> _updateStatus(String newStatus) async {
    if (newStatus != 'aktif') {
      final hasActiveProgram = _patientPrograms.any(
        (p) => p['status'] == 'active',
      );
      if (hasActiveProgram) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Program Masih Aktif',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              'Pasien ini masih memiliki program diet yang aktif. Yakin ingin menutup seluruh perawatan pasien?',
              style: GoogleFonts.manrope(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Batal',
                  style: GoogleFonts.manrope(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Ya, Lanjutkan',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
        if (proceed != true) return;
      }
    }

    if (newStatus == 'aktif') {
      await _doUpdateStatus(newStatus, evaluasiAkhir: null);
      return;
    }
    // Jika status "berhasil", "meninggal", atau "dropout"
    await _showEvaluasiAkhirDialog(newStatus);
  }

  Future<void> _doUpdateStatus(
    String newStatus, {
    String? evaluasiAkhir,
    String? outcomeType,
  }) async {
    final rm = widget.pasien['rm'] as String? ?? '';
    await AuthService.updatePasienStatus(rm, newStatus);

    // Simpan evaluasi akhir jika ada
    if (evaluasiAkhir != null && evaluasiAkhir.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .where('rm', isEqualTo: rm)
          .get()
          .then((snap) async {
            if (snap.docs.isNotEmpty) {
              await snap.docs.first.reference.update({
                'evaluasi_akhir': evaluasiAkhir,
                'outcome_program': outcomeType ?? 'Tercapai',
                'tanggal_selesai': FieldValue.serverTimestamp(),
              });
            }
          });
    }

    // Notif ke Pasien
    final patientId = widget.pasien['uid'] as String? ?? '';
    final agName =
        (await AuthService.getLoggedInUser())?['name'] ?? 'Ahli Gizi';
    await FirebaseNotificationService.notifyStatusChanged(
      patientId: patientId,
      newStatus: newStatus,
      ahliGiziName: agName,
    );
    if (mounted) {
      setState(() => _status = newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status pasien diperbarui: ${newStatus.toUpperCase()}.',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showEvaluasiAkhirDialog(String status) async {
    final evaluasiCtrl = TextEditingController();

    List<String> outcomes;
    String selectedOutcome;

    if (status == 'meninggal') {
      outcomes = ['Pasien Meninggal'];
      selectedOutcome = 'Pasien Meninggal';
    } else if (status == 'dropout') {
      outcomes = ['Pasien Keluar Lebih Awal', 'Pindah Fasilitas Kesehatan'];
      selectedOutcome = 'Pasien Keluar Lebih Awal';
    } else {
      // berhasil
      outcomes = ['Tercapai', 'Belum Tercapai', 'Lainnya'];
      selectedOutcome = 'Tercapai';
    }

    String titleText = 'Evaluasi Akhir Program';
    if (status == 'meninggal') titleText = 'Laporan Pasien Meninggal';
    if (status == 'dropout') titleText = 'Laporan Pasien Dropout';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                status == 'berhasil'
                    ? Icons.assignment_turned_in_outlined
                    : Icons.info_outline,
                color: AppColors.secondary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                titleText,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sebelum menyelesaikan program, isi evaluasi akhir untuk dokumentasi laporan.',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Outcome Program',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...outcomes.map(
                  (o) => GestureDetector(
                    onTap: () => setDialogState(() => selectedOutcome = o),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selectedOutcome == o
                            ? AppColors.secondary.withValues(alpha: 0.1)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selectedOutcome == o
                              ? AppColors.secondary
                              : AppColors.divider,
                          width: selectedOutcome == o ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedOutcome == o
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: selectedOutcome == o
                                ? AppColors.secondary
                                : AppColors.textMuted,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            o,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: selectedOutcome == o
                                  ? AppColors.secondary
                                  : AppColors.textPrimary,
                              fontWeight: selectedOutcome == o
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Evaluasi & Kesimpulan',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: evaluasiCtrl,
                  maxLines: 4,
                  style: GoogleFonts.manrope(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: status == 'meninggal'
                        ? 'Contoh: Pasien meninggal dunia karena komplikasi gagal ginjal...'
                        : 'Contoh: Pasien berhasil mencapai target BB ideal. Kepatuhan diet 90%. Disarankan tetap menjaga pola makan...',
                    hintStyle: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.secondary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '* Minimal 10 karakter',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Batal',
                style: GoogleFonts.manrope(color: AppColors.textSecondary),
              ),
            ),
            StatefulBuilder(
              builder: (ctx2, _) => ElevatedButton.icon(
                onPressed: () {
                  if (evaluasiCtrl.text.trim().length < 10) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Evaluasi minimal 10 karakter.',
                          style: GoogleFonts.manrope(),
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  _doUpdateStatus(
                    status,
                    evaluasiAkhir: evaluasiCtrl.text.trim(),
                    outcomeType: selectedOutcome,
                  );
                },
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 18,
                ),
                label: Text(
                  'Konfirmasi Selesai',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAll() async {
    final hasTargetData =
        _checkedNutrients.isNotEmpty &&
        _targetCtrls.values.any((c) => c.text.trim().isNotEmpty);
    final hasAktualData =
        _checkedNutrients.isNotEmpty &&
        _aktualCtrls.values.any(
          (c) => c.text.trim().isNotEmpty && c.text.trim() != '0',
        );

    setState(() => _isSaving = true);
    try {
      final rm = widget.pasien['rm'] as String? ?? '';
      final patientId = widget.pasien['uid'] as String? ?? '';
      final String effectiveDiet = _selectedPatientProgram != null
          ? (_selectedPatientProgram!['therapyProgramName'] as String? ?? '')
          : (_selectedDietType == 'Diet Khusus/Lainnya'
                ? _customDietCtrl.text
                : (_selectedDietType ?? 'Diet Normal'));

      // Prepare target AND aktual nutrients map
      Map<String, dynamic> targetNutrientsToSave = {};
      Map<String, dynamic> aktualNutrientsToSave = {};
      _checkedNutrients.forEach((key, checked) {
        if (checked) {
          final targetVal =
              double.tryParse(_targetCtrls[key]?.text ?? '0') ?? 0.0;
          targetNutrientsToSave[key] = {
            'target': targetVal,
            'aktual': double.tryParse(_aktualCtrls[key]?.text ?? '0') ?? 0.0,
          };
          aktualNutrientsToSave[key] =
              double.tryParse(_aktualCtrls[key]?.text ?? '0') ?? 0.0;
        }
      });

      // 1a. Jika belum ada program tapi ada diet baru dipilih, pastikan buat program di collection baru
      if (_selectedPatientProgram == null && _selectedDietType != null) {
        final currentUser = await AuthService.getLoggedInUser();
        final String createdBy = currentUser?['uid'] ?? 'unknown_ag';

        final newProg = await AuthService.addPatientTherapyProgram(
          patientId: patientId,
          patientRm: rm,
          therapyProgramName: effectiveDiet,
          therapyProgramId: '',
          createdBy: createdBy,
        );
        if (newProg['patientProgramId'] != null) {
          _selectedPatientProgram = newProg;
          if (mounted) {
            setState(() {
              _patientPrograms.insert(0, newProg);
            });
          }
        }
      }

      // 1b. Jika sekarang sudah ada program (baik yang sudah ada, atau yang baru dibuat di atas)
      if (_selectedPatientProgram != null) {
        String patientProgramId =
            _selectedPatientProgram!['patientProgramId'] as String? ?? '';
        String therapyProgramId =
            _selectedPatientProgram!['therapyProgramId'] as String? ?? '';

        // Jika ini program virtual dari onboarding, buat program aslinya dulu
        if (patientProgramId.startsWith('initial_onboarding')) {
          final String oldProgramId = patientProgramId;
          final currentUser = await AuthService.getLoggedInUser();
          final String createdBy = currentUser?['uid'] ?? 'unknown_ag';

          final newProg = await AuthService.addPatientTherapyProgram(
            patientId: patientId,
            patientRm: rm,
            therapyProgramName: effectiveDiet,
            therapyProgramId: '',
            createdBy: createdBy,
          );
          if (newProg['patientProgramId'] != null) {
            patientProgramId = newProg['patientProgramId'];
            // Update state agar program virtual diganti yang asli
            if (mounted) {
              setState(() {
                _selectedPatientProgram = newProg;
                _patientPrograms = _patientPrograms
                    .where((p) => p['patientProgramId'] != oldProgramId)
                    .toList();
                _patientPrograms.insert(0, newProg);
              });
            }
          }
        }

        await AuthService.saveNutritionTarget(
          patientProgramId: patientProgramId,
          patientId: patientId,
          patientRm: rm,
          therapyProgramId: therapyProgramId,
          nutrientItems: targetNutrientsToSave,
          catatan: _catatanNutrisiCtrl.text,
        );
      }

      // 1b. Tetap save ke nutrition_plans (backward compat)
      await AuthService.saveNutrisiPerDiet(
        rmPasien: rm,
        dietType: effectiveDiet,
        targetNutrients: targetNutrientsToSave,
        aktualNutrients: aktualNutrientsToSave,
        catatan: _catatanNutrisiCtrl.text,
      );

      // 2. Simpan data klinis ke model pasien
      await AuthService.updateClinicalData(
        rm: rm,
        diagnosis: _diagnosisCtrl.text,
        catatanKlinis: _catatanNutrisiCtrl.text,
        terapiDiet: effectiveDiet,
      );

      // Simpan status gizi manual
      await FirebaseFirestore.instance
          .collection('users')
          .where('rm', isEqualTo: rm)
          .get()
          .then((value) {
            if (value.docs.isNotEmpty) {
              value.docs.first.reference.update({
                'status_gizi_manual': _statusGiziManual,
                'imt_manual': _imtManualCtrl.text.trim(),
              });
            }
          });

      // 2b. Simpan diagnosis ke program yang aktif (per-program)
      if (_selectedPatientProgram != null) {
        final pid = _selectedPatientProgram!['patientProgramId'] as String?;
        if (pid != null && !pid.startsWith('initial_onboarding')) {
          await AuthService.updateProgramDiagnosis(
            patientProgramId: pid,
            diagnosis: _diagnosisCtrl.text,
          );
          // Update local state agar langsung sinkron
          if (mounted) {
            setState(() {
              final idx = _patientPrograms.indexWhere(
                (p) => p['patientProgramId'] == pid,
              );
              if (idx != -1) {
                _patientPrograms[idx] = {
                  ..._patientPrograms[idx],
                  'diagnosis': _diagnosisCtrl.text,
                };
                _selectedPatientProgram = _patientPrograms[idx];
              }
            });
          }
        }
      }

      // 2c. Simpan catatan evaluasi harian
      if (_evaluasiHarianCtrl.text.isNotEmpty) {
        final currentAg =
            (await AuthService.getLoggedInUser())?['name'] ?? 'Ahli Gizi';
        await AuthService.saveCatatanEvaluasi(
          rmPasien: rm,
          catatan: _evaluasiHarianCtrl.text,
          agName: currentAg,
        );
      }

      // 3. Simpan target diet (text summary legacy)
      await AuthService.saveTargetDietPasien(
        rm: rm,
        targetDiet: _targetCtrl.text,
        catatanEvaluasi: _catatanNutrisiCtrl.text,
      );

      // 4. Kirim notifikasi ke pasien: target nutrisi diperbarui
      if (patientId.isNotEmpty && _selectedPatientProgram != null) {
        final agName =
            (await AuthService.getLoggedInUser())?['name'] ?? 'Ahli Gizi';
        final progName =
            _selectedPatientProgram!['therapyProgramName'] as String? ??
            effectiveDiet;
        await FirebaseNotificationService.createNotification(
          userId: patientId,
          role: 'pasien',
          title: 'Target Nutrisi Diperbarui',
          message:
              'Ahli Gizi $agName telah memperbarui target nutrisi untuk program "$progName". '
              'Silakan cek tab Catatan Makan untuk melihat target terbaru Anda.',
          type: 'target',
          relatedId:
              _selectedPatientProgram!['patientProgramId'] as String? ?? '',
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Data pasien berhasil disimpan!',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}', style: GoogleFonts.manrope()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }



  Widget _buildEvaluasiSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.monitor_weight_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Penilaian Status Gizi Akhir',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _statusGiziManual,
            hint: Text(
              'Pilih status gizi pasien...',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            items: _statusGiziOptions
                .map(
                  (v) => DropdownMenuItem(
                    value: v,
                    child: Text(v, style: GoogleFonts.manrope(fontSize: 13)),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _statusGiziManual = v),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          
          if (AgeCalculator.calculateAge(widget.pasien['birthdate']) != null && ((AgeCalculator.calculateAge(widget.pasien['birthdate'])!['years']! * 12) + AgeCalculator.calculateAge(widget.pasien['birthdate'])!['months']!) < 216) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.child_care, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Status Gizi Anak (IMT/U)', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _imtManualCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Contoh: 18.5',
                hintStyle: GoogleFonts.manrope(fontSize: 13, color: AppColors.textMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.divider)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.divider)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
              ),
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String get _dietLabel {
    if (_patientPrograms.isEmpty)
      return widget.pasien['diet_type'] as String? ?? 'Normal';
    final active = _patientPrograms
        .where((p) => p['status'] == 'active')
        .map((p) => p['therapyProgramName'] as String)
        .toList();
    if (active.isEmpty) {
      final completed = _patientPrograms
          .where((p) => p['status'] == 'completed')
          .map((p) => p['therapyProgramName'] as String)
          .toList();
      return completed.isNotEmpty
          ? completed.join(', ')
          : (widget.pasien['diet_type'] as String? ?? 'Normal');
    }
    return active.join(', ');
  }

  Color get _statusColor {
    switch (_status) {
      case 'berhasil':
        return AppColors.secondary;
      case 'meninggal':
        return AppColors.textSecondary;
      case 'dropout':
        return AppColors.red;
      default:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Pasien',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          // ---Â ---Â --- Info Pasien ---Â ---Â ---
          _buildPasienCard(),
          const SizedBox(height: 12),
          _buildInfoGrid(),
          const SizedBox(height: 16),

          // ---Â ---Â --- Program Terapi Diet Pasien ---Â ---Â ---
          _buildPatientProgramsSection(),
          const SizedBox(height: 24),

          // ---Â ---Â --- Clinical Info ---Â ---Â ---
          _buildSectionLabel('Kondisi Klinis Pasien'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _buildDiagnosisAutocompleteField(),
                const SizedBox(height: 12),
                _buildNutrisiField(
                  'Catatan / Evaluasi Klinis',
                  _catatanNutrisiCtrl,
                  'Ketik catatan...',
                  '',
                  keyboardType: TextInputType.multiline,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ---Â ---Â --- Terapi Diet Selection (hanya tampil jika belum ada program dipilih) ---Â ---Â ---
          if (_selectedPatientProgram == null) ...[
            _buildSectionLabel('Pilih Terapi Diet'),
            const SizedBox(height: 8),
            _buildTerapiDietDropdown(),
            if (_selectedDietType == 'Diet Khusus/Lainnya') ...[
              const SizedBox(height: 12),
              _buildTextArea(_customDietCtrl, 'Ketik nama diet khusus...', 1),
            ],
            const SizedBox(height: 24),
          ],

          // ---Â ---Â --- Banner: Program yang sedang diedit ---Â ---Â ---
          if (_selectedPatientProgram != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondary,
                    AppColors.secondary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_note_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sedang mengedit program:',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          _selectedPatientProgram!['therapyProgramName']
                                  as String? ??
                              '-',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _selectedPatientProgram!['status'] == 'active'
                          ? 'Aktif'
                          : _selectedPatientProgram!['status'] == 'completed'
                          ? 'Selesai'
                          : 'Nonaktif',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ---Â ---Â --- NUTRISI SECTION ---Â ---Â ---
          _buildNutrisiSection(),
          const SizedBox(height: 24),

          // ---Â ---Â --- CAPAIAN GIZI SECTION ---Â ---Â ---
          _buildCapaianGiziSection(),
          const SizedBox(height: 24),

          // ---Â ---Â --- RIWAYAT CATATAN MAKANAN ---Â ---Â ---
          _buildRiwayatMakanSection(),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final patientId = widget.pasien['uid'] as String?;
                if (patientId == null || patientId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ID Pasien tidak ditemukan.')),
                  );
                  return;
                }

                // Tampilkan indikator loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );

                await FirebaseNotificationService.createNotification(
                  userId: patientId,
                  role: 'pasien',
                  title: 'Pengingat dari Ahli Gizi',
                  message:
                      'Halo! Ahli gizi Anda mengingatkan untuk segera mengisi catatan makan hari ini. Yuk, isi sekarang agar perkembangan Anda dapat dipantau.',
                  type: 'alert_log',
                );

                if (context.mounted) {
                  Navigator.pop(context); // Tutup loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Pengingat berhasil dikirim ke pasien.',
                        style: GoogleFonts.manrope(),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              icon: const Icon(
                Icons.notifications_active_outlined,
                size: 18,
                color: Colors.white,
              ),
              label: Text(
                'Kirim Pengingat Catatan Makan',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 16),

          // --- Catatan Evaluasi Harian (dengan kunci dinamis & Status Gizi) ---
          _buildSectionLabel('Catatan Evaluasi Pasien (Harian)'),
          const SizedBox(height: 8),
          _buildEvaluasiSection(),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        LaporanHarianAGScreen(pasien: widget.pasien),
                  ),
                );
              },
              icon: const Icon(
                Icons.bar_chart_rounded,
                size: 18,
                color: Colors.white,
              ),
              label: Text(
                'Laporan Harian',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ---Â---Â--- Ubah Status ---Â---Â---
          _buildSectionLabel('Ubah Status Pasien'),
          const SizedBox(height: 8),
          _buildStatusButtons(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---
  // WIDGET BUILDERS
  // ---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---

  Widget _buildPasienCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (widget.pasien['name'] as String? ?? 'P')
                    .substring(0, 1)
                    .toUpperCase(),
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _statusColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.pasien['name'] ?? '-',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'RM: ${widget.pasien['rm'] ?? '-'}',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildChip(_dietLabel, AppColors.secondary),
                    const SizedBox(width: 6),
                    _buildChip(_status.toUpperCase(), _statusColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid() {
    // Cek consent: bisa dari base64 (web) atau dari file path (mobile)
    final bool hasConsent =
        widget.pasien['inform_consent_signed'] == true &&
        (((widget.pasien['consent_signature_base64'] as String?) ?? '')
                .isNotEmpty ||
            ((widget.pasien['consent_signature_path'] as String?) ?? '')
                .isNotEmpty);

    final String? base64Sig =
        widget.pasien['consent_signature_base64'] as String?;
    final String? filePath = widget.pasien['consent_signature_path'] as String?;
    final String? signedAt = widget.pasien['consent_signed_at'] as String?;

    final ageMap = AgeCalculator.calculateAge(widget.pasien['birthdate']);
    final kondisi = AgeCalculator.getKondisi(ageMap);
    final imt = AgeCalculator.calculateIMT(
      widget.pasien['weight'],
      widget.pasien['height'],
    );

    final bbStr =
        widget.pasien['weight'] != null &&
            widget.pasien['weight'].toString().isNotEmpty
        ? '${widget.pasien['weight']} kg'
        : '-';
    final tbStr =
        widget.pasien['height'] != null &&
            widget.pasien['height'].toString().isNotEmpty
        ? '${widget.pasien['height']} cm'
        : '-';
    final genderStr = widget.pasien['gender'] ?? '-';
    final umurStr = AgeCalculator.formatAge(ageMap);

    Widget contactRow = _buildInfoRow(
      'No. Telepon / WA',
      widget.pasien['phone'] ?? '-',
      trailing:
          widget.pasien['phone'] != null && widget.pasien['phone'].isNotEmpty
          ? GestureDetector(
              onTap: () async {
                String phone = widget.pasien['phone'].replaceAll(
                  RegExp(r'\D'),
                  '',
                );
                if (phone.startsWith('0')) {
                  phone = '62${phone.substring(1)}';
                }
                final url = Uri.parse('https://wa.me/$phone');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.chat, size: 16, color: Colors.white),
              ),
            )
          : null,
    );

    Widget emailRow = _buildInfoRow('Email', widget.pasien['email'] ?? '-');

    List<Widget> infoRows = [];

    if (kondisi == 'A') {
      infoRows = [
        _buildInfoRow('Berat Badan', bbStr),
        _buildInfoRow('Tinggi Badan', tbStr),
        _buildInfoRow('Jenis Kelamin', genderStr),
        _buildInfoRow('Umur', umurStr),
        contactRow,
        emailRow,
      ];
    } else if (kondisi == 'B') {
      infoRows = [
        _buildInfoRow('Berat Badan', bbStr),
        _buildInfoRow('Tinggi Badan', tbStr),
        _buildInfoRow('Umur', umurStr),
        _buildInfoRow('Jenis Kelamin', genderStr),
        contactRow,
        emailRow,
      ];
    } else {
      infoRows = [
        _buildInfoRow('Berat Badan', bbStr),
        _buildInfoRow('Tinggi Badan', tbStr),
        _buildInfoRow('IMT', imt ?? 'Belum tersedia'),
        _buildInfoRow('Umur', umurStr),
        _buildInfoRow('Jenis Kelamin', genderStr),
        contactRow,
        emailRow,
      ];
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: infoRows),
        ),
        const SizedBox(height: 12),
        // ---Â---Â--- Informed Consent Card ---Â---Â---
        _buildConsentCard(hasConsent, base64Sig, filePath, signedAt),
      ],
    );
  }

  Widget _buildConsentCard(
    bool hasConsent,
    String? base64Sig,
    String? filePath,
    String? signedAt,
  ) {
    if (!hasConsent) {
      // Belum ada consent
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.accent,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Pasien belum menandatangani informed consent.',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Format tanggal signed
    String signedDateStr = '';
    if (signedAt != null && signedAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(signedAt).toLocal();
        signedDateStr = '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informed Consent',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (signedDateStr.isNotEmpty)
                      Text(
                        'Ditandatangani: $signedDateStr',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified,
                      color: AppColors.primaryDark,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ditandatangani',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _showConsentDialog(base64Sig, filePath, signedDateStr),
                  icon: const Icon(
                    Icons.visibility_outlined,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                  label: Text(
                    'Lihat',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.secondary),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _downloadConsent(
                    widget.pasien['consent_doc_base64'] as String?,
                    base64Sig,
                    filePath,
                    widget.pasien['rm'] ?? 'pasien',
                  ),
                  icon: const Icon(
                    Icons.download_outlined,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Download',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showConsentDialog(
    String? base64Sig,
    String? filePath,
    String signedDate,
  ) {
    final String? consentDocB64 =
        widget.pasien['consent_doc_base64'] as String?;

    Widget imageWidget;
    if (base64Sig != null && base64Sig.isNotEmpty) {
      final bytes = base64Decode(base64Sig);
      imageWidget = Image.memory(bytes, fit: BoxFit.contain);
    } else if (filePath != null && filePath.isNotEmpty && !kIsWeb) {
      imageWidget = Image.file(File(filePath), fit: BoxFit.contain);
    } else {
      imageWidget = Center(
        child: Text(
          'Tanda tangan tidak tersedia.',
          style: GoogleFonts.manrope(color: AppColors.textSecondary),
        ),
      );
    }

    // Isi dokumen consent lengkap (teks)
    final consentPoints = [
      'Saya bersedia untuk mengisi catatan makan harian secara jujur dan tepat waktu.',
      'Saya memahami bahwa apabila tidak mengisi catatan makan selama 3 (tiga) hari berturut-turut, saya akan dinyatakan GUGUR dari program dan tidak dapat menggunakan aplikasi hingga dikonfirmasi ulang oleh ahli gizi.',
      'Saya bersedia memberikan data kesehatan yang akurat, termasuk berat badan dan tinggi badan secara berkala.',
      'Saya memahami bahwa data saya akan digunakan untuk keperluan pemantauan gizi dan tidak akan disebarluaskan kepada pihak ketiga tanpa izin.',
      'Saya berhak untuk mengundurkan diri dari program dengan memberitahukan ahli gizi terlebih dahulu.',
      'Saya memahami bahwa rekomendasi dalam aplikasi ini bersifat edukatif dan tidak menggantikan konsultasi medis langsung.',
    ];

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 640,
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.assignment_turned_in,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informed Consent Monitoring Diet',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Informed Consent - ${widget.pasien['name'] ?? ''}',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Body - dokumen lengkap
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status badge
                      if (signedDate.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified,
                                color: AppColors.primaryDark,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Disetujui & ditandatangani pada: $signedDate',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Info pasien
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DATA PASIEN',
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _consentInfoRow(
                              'Nama Lengkap',
                              widget.pasien['name'] ?? '-',
                            ),
                            _consentInfoRow(
                              'No. Rekam Medis',
                              widget.pasien['rm'] ?? '-',
                            ),
                            _consentInfoRow(
                              'Tanggal Tanda Tangan',
                              signedDate.isEmpty ? '-' : signedDate,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Judul dokumen
                      Center(
                        child: Text(
                          'INFORMED CONSENT MONITORING DIET',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Isi consent
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saya dengan ini menyatakan bahwa saya telah memahami dan menyetujui untuk mengikuti Program Diet Klinik yang diselenggarakan oleh Naksihat.',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Saya memahami bahwa program ini melibatkan pemantauan asupan makanan, berat badan, tinggi badan, dan parameter gizi lainnya oleh ahli gizi yang telah ditunjuk.',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...consentPoints.asMap().entries.map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      child: Text(
                                        '${e.key + 1}.',
                                        style: GoogleFonts.manrope(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        e.value,
                                        style: GoogleFonts.manrope(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Dengan menandatangani dokumen ini, saya menyatakan bahwa saya telah membaca, memahami, dan menyetujui seluruh ketentuan di atas.',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Status persetujuan (checkbox)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Saya telah membaca dan menyetujui seluruh ketentuan di atas',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tanda tangan
                      Text(
                        'TANDA TANGAN PASIEN',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.all(10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageWidget,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 13,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tanda tangan digital pasien - ${widget.pasien['name'] ?? ''}',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Footer - tombol download
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: AppColors.divider),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Tutup',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _downloadConsent(
                            consentDocB64,
                            base64Sig,
                            filePath,
                            widget.pasien['rm'] ?? 'pasien',
                          );
                        },
                        icon: const Icon(
                          Icons.download_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Download Dokumen',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _consentInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadConsent(
    String? consentDocB64,
    String? base64Sig,
    String? filePath,
    String rm,
  ) async {
    await _regenerateConsent();
  }

  Widget _buildTerapiDietDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDietType,
          isExpanded: true,
          hint: Text(
            'Pilih Terapi Diet...',
            style: GoogleFonts.manrope(fontSize: 14),
          ),
          items: _terapiDietList
              .map(
                (d) => DropdownMenuItem(
                  value: d,
                  child: Text(d, style: GoogleFonts.manrope(fontSize: 14)),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() {
                _selectedDietType = v;
                _loadNutrisi();
              });
            }
          },
        ),
      ),
    );
  }

  Future<void> _copyLastTarget() async {
    try {
      final previousPrograms = _patientPrograms
          .where(
            (p) =>
                p['patientProgramId'] !=
                    _selectedPatientProgram?['patientProgramId'] &&
                !p['patientProgramId'].toString().startsWith('initial'),
          )
          .toList();

      if (previousPrograms.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Belum ada riwayat program sebelumnya.',
              style: GoogleFonts.manrope(),
            ),
          ),
        );
        return;
      }

      final lastProgId = previousPrograms.first['patientProgramId'];
      final nutritionTarget = await AuthService.getNutritionTarget(lastProgId);

      if (!mounted) return;
      if (nutritionTarget == null ||
          (nutritionTarget['nutrientItems'] as Map?)?.isEmpty == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Program sebelumnya tidak memiliki target nutrisi.',
              style: GoogleFonts.manrope(),
            ),
          ),
        );
        return;
      }

      final nutrientItems = (nutritionTarget['nutrientItems'] as Map)
          .cast<String, dynamic>();
      setState(() {
        nutrientItems.forEach((key, val) {
          if (!_targetCtrls.containsKey(key))
            _targetCtrls[key] = TextEditingController();
          _targetCtrls[key]!.text = _fmtNum(val['target']);
          _checkedNutrients[key] = true;
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Berhasil menyalin target nutrisi terakhir.',
            style: GoogleFonts.manrope(),
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyalin: $e', style: GoogleFonts.manrope()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildNutrisiSection() {
    final List<String> allNutrients = _nutrientCategories.values
        .expand((e) => e)
        .toList();
    final List<String> availableNutrients = allNutrients
        .where((n) => !(_checkedNutrients[n] ?? false))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: _buildSectionLabel('Target Gizi Harian')),
                  if (_selectedPatientProgram?['status'] == 'completed') ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Selesai',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            TextButton.icon(
              onPressed: _copyLastTarget,
              icon: const Icon(Icons.copy, size: 16, color: AppColors.primary),
              label: Text(
                'Salin Terakhir',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Dropdown to add nutrient
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: Text(
                'Tambah item gizi...',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              items: availableNutrients
                  .map(
                    (n) => DropdownMenuItem(
                      value: n,
                      child: Text(n, style: GoogleFonts.manrope(fontSize: 14)),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _checkedNutrients[val] = true;
                    if (!_targetCtrls.containsKey(val))
                      _targetCtrls[val] = TextEditingController();
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        // List of selected nutrients
        ..._checkedNutrients.entries.where((e) => e.value).map((entry) {
          final nutrient = entry.key;
          if (!_targetCtrls.containsKey(nutrient))
            _targetCtrls[nutrient] = TextEditingController();

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    nutrient,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _targetCtrls[nutrient],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Nilai...',
                      hintStyle: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _checkedNutrients[nutrient] = false;
                    });
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCapaianGiziSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Aktualisasi Gizi Harian'),
        const SizedBox(height: 4),
        Text(
          'Input manual oleh Ahli Gizi berdasarkan perhitungan dari catatan makan pasien.',
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        if (_checkedNutrients.values.every((v) => !v))
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'Pilih dan simpan target gizi terlebih dahulu, lalu isi aktualisasi di sini.',
              style: GoogleFonts.manrope(fontSize: 12, color: AppColors.accent),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: _checkedNutrients.entries.where((e) => e.value).map((
                e,
              ) {
                final nutrient = e.key;
                if (!_aktualCtrls.containsKey(nutrient)) {
                  _aktualCtrls[nutrient] = TextEditingController();
                }
                final target =
                    double.tryParse(_targetCtrls[nutrient]?.text ?? '0') ?? 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            nutrient,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (target > 0)
                            Text(
                              'Target: ${_fmtNum(target)}',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _aktualCtrls[nutrient],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Input aktualisasi $nutrient...',
                          hintStyle: GoogleFonts.manrope(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildRiwayatMakanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Riwayat Catatan Makanan (7 Hari Terakhir)'),
        const SizedBox(height: 8),
        if (_missedDays > 0)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.accent,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _missedDays >= 3
                        ? 'Pasien tidak mengisi catatan makan selama $_missedDays hari terakhir. Segera hubungi pasien.'
                        : 'Pasien tidak mengisi catatan makan selama $_missedDays hari terakhir.',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (_riwayatMakan.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(
              'Belum ada catatan makanan yang diinput pasien.',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          ..._riwayatMakan.map((log) {
            final dateStr = log['date'] as String? ?? '';
            String displayDate = '';
            if (dateStr.isNotEmpty) {
              try {
                final dt = DateTime.parse(dateStr);
                displayDate = '${dt.day}/${dt.month}/${dt.year}';
              } catch (_) {}
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Tanggal: $displayDate',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                          if (log['diet_type'] != null &&
                              (log['diet_type'] as String? ?? '')
                                  .isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                log['diet_type'],
                                style: GoogleFonts.manrope(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (log['berat_badan'] != null)
                        Text(
                          'BB: ${log['berat_badan']} kg',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 16),
                  _buildMealLogItem('Pagi', log['meal_pagi']),
                  _buildMealLogItem('Selingan Pagi', log['selingan_pagi']),
                  _buildMealLogItem('Siang', log['meal_siang']),
                  _buildMealLogItem('Selingan Sore', log['selingan_sore']),
                  _buildMealLogItem('Malam', log['meal_malam']),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildMealLogItem(String label, dynamic value) {
    final text = (value as String?) ?? '';
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisAutocompleteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Diagnosis (ICD 10)',
          style: GoogleFonts.manrope(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Autocomplete<String>(
          initialValue: TextEditingValue(text: _diagnosisCtrl.text),
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return _icd10List.where((String option) {
              return option.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              );
            });
          },
          onSelected: (String selection) {
            _diagnosisCtrl.text = selection;
          },
          fieldViewBuilder:
              (context, textEditingController, focusNode, onFieldSubmitted) {
                // Sinkronisasi controller utama dengan controller Autocomplete
                textEditingController.text = _diagnosisCtrl.text;
                textEditingController.addListener(() {
                  _diagnosisCtrl.text = textEditingController.text;
                });

                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ketik kode atau nama diagnosa...',
                    hintStyle: GoogleFonts.manrope(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    suffixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
                  onSubmitted: (value) {
                    onFieldSubmitted();
                  },
                );
              },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 6.0,
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: MediaQuery.of(context).size.width - 64,
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      return InkWell(
                        onTap: () {
                          onSelected(option);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppColors.background),
                            ),
                          ),
                          child: Text(
                            option,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNutrisiField(
    String label,
    TextEditingController ctrl,
    String hint,
    String suffix, {
    TextInputType keyboardType = const TextInputType.numberWithOptions(
      decimal: true,
      signed: false,
    ),
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLines: keyboardType == TextInputType.multiline ? null : 1,
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.manrope(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
            suffixText: suffix,
            suffixStyle: GoogleFonts.manrope(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatusButton('Aktif', 'aktif', AppColors.secondary),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatusButton(
                'Berhasil',
                'berhasil',
                AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatusButton(
                'Meninggal',
                'meninggal',
                AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatusButton('Dropout', 'dropout', AppColors.red),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 12,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveAll,
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_outlined, color: Colors.white, size: 20),
          label: Text(
            _isSaving ? 'MENYIMPAN...' : 'SIMPAN SEMUA DATA',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  // ---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---
  // HELPER WIDGETS
  // ---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---

  Widget _buildSectionLabel(String label) => Text(
    label,
    style: GoogleFonts.manrope(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
  );

  Widget _buildTextArea(TextEditingController ctrl, String hint, int maxLines) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: GoogleFonts.manrope(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.manrope(
            color: AppColors.textMuted,
            fontSize: 13,
            height: 1.5,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildStatusButton(String label, String status, Color color) {
    final isSelected = _status == status;
    return GestureDetector(
      onTap: () => _updateStatus(status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }

  // ---Â---Â--- PATIENT PROGRAMS SECTION ---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---Â---

  Widget _buildPatientProgramsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildSectionLabel('Program Terapi Diet Pasien')),
            TextButton.icon(
              onPressed: _showAddProgramDialog,
              icon: const Icon(
                Icons.add_circle_outline,
                size: 18,
                color: AppColors.secondary,
              ),
              label: Text(
                'Tambah',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoadingPrograms)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          )
        else if (_patientPrograms.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.assignment_outlined,
                  color: AppColors.textMuted,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Belum ada Program Terapi Diet.\nKlik "+ Tambah" untuk menambahkan.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _patientPrograms.map((program) {
                    final isSelected =
                        _selectedPatientProgram?['patientProgramId'] ==
                        program['patientProgramId'];
                    final status = program['status'] as String? ?? 'active';
                    final programName =
                        program['therapyProgramName'] as String? ?? '-';
                    Color statusColor;
                    String statusLabel;
                    switch (status) {
                      case 'active':
                        statusColor = AppColors.secondary;
                        statusLabel = 'Aktif';
                        break;
                      case 'completed':
                        statusColor = AppColors.secondary;
                        statusLabel = 'Selesai';
                        break;
                      default:
                        statusColor = AppColors.textSecondary;
                        statusLabel = 'Nonaktif';
                    }
                    return GestureDetector(
                      onTap: () => _selectProgram(program),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.secondary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.secondary
                                : AppColors.divider,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.secondary.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              programName,
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.2)
                                        : statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: GoogleFonts.manrope(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? Colors.white
                                          : statusColor,
                                    ),
                                  ),
                                ),
                                if (program['isInitial'] == true) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.2)
                                          : Colors.orange.withValues(
                                              alpha: 0.12,
                                            ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Program Awal',
                                      style: GoogleFonts.manrope(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.orange[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (_selectedPatientProgram != null) ...[
                const SizedBox(height: 12),
                _buildProgramStatusButtons(),
                const SizedBox(height: 8),
                _buildProgramPeriodInfo(),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildProgramStatusButtons() {
    final currentStatus =
        _selectedPatientProgram?['status'] as String? ?? 'active';
    final patientProgramId =
        _selectedPatientProgram?['patientProgramId'] as String? ?? '';
    return Row(
      children: [
        for (final s in [
          {'status': 'active', 'label': 'Aktif', 'color': AppColors.secondary},
          {
            'status': 'completed',
            'label': 'Selesai',
            'color': AppColors.secondary,
          },
          {
            'status': 'inactive',
            'label': 'Nonaktif',
            'color': AppColors.textSecondary,
          },
        ]) ...[
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final newStatus = s['status'] as String? ?? '';
                if (newStatus == currentStatus || patientProgramId.isEmpty)
                  return;
                await AuthService.updatePatientProgramStatus(
                  patientProgramId,
                  newStatus,
                );
                final idx = _patientPrograms.indexWhere(
                  (p) => p['patientProgramId'] == patientProgramId,
                );
                if (idx != -1 && mounted) {
                  setState(() {
                    _patientPrograms[idx] = {
                      ..._patientPrograms[idx],
                      'status': newStatus,
                    };
                    _selectedPatientProgram = _patientPrograms[idx];
                  });

                  final hasActive = _patientPrograms.any(
                    (p) => p['status'] == 'active',
                  );
                  if (!hasActive && _status == 'aktif') {
                    final proceed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Semua Program Selesai',
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        content: Text(
                          'Semua program diet telah selesai. Apakah Anda ingin menandai perawatan pasien ini sebagai Berhasil/Lulus?',
                          style: GoogleFonts.manrope(fontSize: 14),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(
                              'Tidak',
                              style: GoogleFonts.manrope(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Ya, Luluskan',
                              style: GoogleFonts.manrope(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (proceed == true && mounted) {
                      _updateStatus('berhasil');
                    }
                  }
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: currentStatus == (s['status'] as String? ?? '')
                      ? (s['color'] as Color)
                      : (s['color'] as Color).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    s['label'] as String? ?? '',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: currentStatus == (s['status'] as String? ?? '')
                          ? Colors.white
                          : s['color'] as Color,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (s !=
              [
                {
                  'status': 'active',
                  'label': 'Aktif',
                  'color': AppColors.secondary,
                },
                {
                  'status': 'completed',
                  'label': 'Selesai',
                  'color': AppColors.secondary,
                },
                {
                  'status': 'inactive',
                  'label': 'Nonaktif',
                  'color': AppColors.textSecondary,
                },
              ].last)
            const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildProgramPeriodInfo() {
    final prog = _selectedPatientProgram;
    if (prog == null) return const SizedBox.shrink();

    final startDateStr = prog['startDate'] as String? ?? '';
    final endDateStr = prog['endDate'] as String? ?? '';
    final notes = prog['notes'] as String? ?? '';
    final isSelesai = prog['status'] == 'completed';

    int? remainingDays;
    if (endDateStr.isNotEmpty) {
      try {
        final endDt = DateTime.parse(endDateStr).toLocal();
        final now = DateTime.now();
        final diff = endDt
            .difference(DateTime(now.year, now.month, now.day))
            .inDays;
        remainingDays = diff;
      } catch (_) {}
    }

    String fmtDate(String d) {
      if (d.isEmpty) return '-';
      try {
        final dt = DateTime.parse(d).toLocal();
        return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (_) {
        return d;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isSelesai && remainingDays != null && remainingDays < 0)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              border: Border.all(color: Colors.orange),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Periode program ini telah berakhir.',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Apakah Anda ingin melanjutkan program diet pasien ini atau menyelesaikannya secara permanen?',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showEditPeriodDialog(prog),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(
                          'Lanjutkan Program',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Selesaikan Program?'),
                              content: const Text(
                                'Tindakan ini akan menandai program ini selesai dan menjadi arsip permanen. Anda yakin?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Batal'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text(
                                    'Selesaikan',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await AuthService.updatePatientProgramStatus(
                              prog['patientProgramId'],
                              'completed',
                            );
                            _loadInitialData();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Program telah diselesaikan.'),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(
                          'Selesaikan',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Periode Program',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isSelesai)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Telah Selesai',
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[700],
                            ),
                          ),
                        )
                      else if (remainingDays != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: remainingDays < 0
                                ? Colors.red.withValues(alpha: 0.1)
                                : remainingDays <= 3
                                ? Colors.orange.withValues(alpha: 0.15)
                                : AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            remainingDays < 0
                                ? 'Telah Berakhir'
                                : remainingDays == 0
                                ? 'Hari Terakhir'
                                : 'Sisa $remainingDays hari',
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: remainingDays < 0
                                  ? Colors.red[700]
                                  : remainingDays <= 3
                                  ? Colors.orange[800]
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (!isSelesai)
                    TextButton.icon(
                      onPressed: () => _showEditPeriodDialog(prog),
                      icon: const Icon(
                        Icons.edit_calendar,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        'Atur Periode',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow('Mulai', fmtDate(startDateStr)),
                  ),
                  Expanded(
                    child: _buildInfoRow('Selesai', fmtDate(endDateStr)),
                  ),
                ],
              ),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Catatan Periode:',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  notes,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showEditPeriodDialog(Map<String, dynamic> program) async {
    DateTime? selectedStartDate;
    DateTime? selectedEndDate;
    final notesCtrl = TextEditingController(
      text: program['notes'] as String? ?? '',
    );

    if (program['startDate'] != null) {
      try {
        selectedStartDate = DateTime.parse(
          program['startDate'] as String? ?? '',
        ).toLocal();
      } catch (_) {}
    } else {
      selectedStartDate = DateTime.now();
    }
    if (program['endDate'] != null) {
      try {
        selectedEndDate = DateTime.parse(
          program['endDate'] as String? ?? '',
        ).toLocal();
      } catch (_) {}
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Atur Periode Diet',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tanggal Mulai',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final dt = await showDatePicker(
                      context: ctx,
                      initialDate: selectedStartDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (dt != null) setDlgState(() => selectedStartDate = dt);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedStartDate != null
                              ? '${selectedStartDate!.day}/${selectedStartDate!.month}/${selectedStartDate!.year}'
                              : 'Pilih Tanggal',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tanggal Selesai (Opsional)',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final dt = await showDatePicker(
                      context: ctx,
                      initialDate:
                          selectedEndDate ??
                          selectedStartDate ??
                          DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (dt != null) setDlgState(() => selectedEndDate = dt);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedEndDate != null
                              ? '${selectedEndDate!.day}/${selectedEndDate!.month}/${selectedEndDate!.year}'
                              : 'Pilih Tanggal',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (selectedEndDate != null)
                          GestureDetector(
                            onTap: () =>
                                setDlgState(() => selectedEndDate = null),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.red,
                            ),
                          )
                        else
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Catatan Periode',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  style: GoogleFonts.manrope(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Misal: Target turun 2kg dalam 2 minggu...',
                    hintStyle: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Batal',
                style: GoogleFonts.manrope(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: selectedStartDate == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      String patientProgramId =
                          program['patientProgramId'] as String? ?? '';

                      // [BARU] Auto-create virtual program if it doesn't exist yet
                      if (patientProgramId.startsWith('initial_onboarding')) {
                        final currentUser = await AuthService.getLoggedInUser();
                        final createdBy = currentUser?['uid'] ?? 'unknown_ag';
                        final rm = widget.pasien['rm'] ?? '';
                        final patientId = widget.pasien['uid'] ?? '';
                        final currentDiet =
                            program['therapyProgramName'] as String?;
                        final effectiveDiet =
                            (currentDiet != null &&
                                currentDiet.isNotEmpty &&
                                currentDiet != '-')
                            ? currentDiet
                            : ((widget.pasien['diet_type'] as String?)
                                              ?.isNotEmpty ==
                                          true &&
                                      widget.pasien['diet_type'] != '-'
                                  ? widget.pasien['diet_type'] as String
                                  : 'Diet Normal');
                        final newProg =
                            await AuthService.addPatientTherapyProgram(
                              patientId: patientId,
                              patientRm: rm,
                              therapyProgramName: effectiveDiet,
                              therapyProgramId: '',
                              createdBy: createdBy,
                            );

                        if (newProg['patientProgramId'] != null) {
                          patientProgramId = newProg['patientProgramId'];
                          if (mounted) {
                            setState(() {
                              _selectedPatientProgram = newProg;
                              _patientPrograms = _patientPrograms
                                  .where(
                                    (p) => !p['patientProgramId']
                                        .toString()
                                        .startsWith('initial'),
                                  )
                                  .toList();
                              _patientPrograms.insert(0, newProg);
                            });

                            // Construct current nutrients
                            Map<String, dynamic> currentNutrients = {};
                            _checkedNutrients.forEach((key, checked) {
                              if (checked) {
                                final tVal =
                                    double.tryParse(
                                      _targetCtrls[key]?.text ?? '0',
                                    ) ??
                                    0.0;
                                final aVal =
                                    double.tryParse(
                                      _aktualCtrls[key]?.text ?? '0',
                                    ) ??
                                    0.0;
                                currentNutrients[key] = {
                                  'target': tVal,
                                  'aktual': aVal,
                                };
                              }
                            });

                            // Auto-save the targets to the newly created program
                            AuthService.saveNutritionTarget(
                              patientProgramId: patientProgramId,
                              patientId: patientId,
                              patientRm: rm,
                              therapyProgramId: '',
                              nutrientItems: currentNutrients,
                              createdBy: createdBy,
                            );
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Gagal membuat program. Coba lagi.',
                                  style: GoogleFonts.manrope(),
                                ),
                              ),
                            );
                          }
                          return;
                        }
                      }

                      final success =
                          await AuthService.updatePatientProgramPeriod(
                            patientProgramId: patientProgramId,
                            startDate: selectedStartDate!.toIso8601String(),
                            endDate: selectedEndDate?.toIso8601String(),
                            notes: notesCtrl.text,
                          );

                      if (success && mounted) {
                        // Update local state
                        setState(() {
                          final idx = _patientPrograms.indexWhere(
                            (p) => p['patientProgramId'] == patientProgramId,
                          );
                          if (idx != -1) {
                            _patientPrograms[idx] = {
                              ..._patientPrograms[idx],
                              'startDate': selectedStartDate!.toIso8601String(),
                              'endDate': selectedEndDate?.toIso8601String(),
                              'notes': notesCtrl.text,
                            };
                            _selectedPatientProgram = _patientPrograms[idx];
                          }
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Periode diet berhasil diperbarui.',
                              style: GoogleFonts.manrope(),
                            ),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              child: Text(
                'Simpan',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddProgramDialog() async {
    String? selectedTherapyId;
    String? selectedTherapyName;
    final notesCtrl = TextEditingController();
    final List<Map<String, dynamic>> available = _availableTherapyPrograms;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Tambah Program Terapi Diet',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Program',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: Text(
                      'Pilih program terapi...',
                      style: GoogleFonts.manrope(fontSize: 13),
                    ),
                    value: selectedTherapyId,
                    items: available
                        .map(
                          (p) => DropdownMenuItem(
                            value:
                                p['id'] as String? ??
                                p['name'] as String? ??
                                '',
                            child: Text(
                              p['name'] as String? ?? '',
                              style: GoogleFonts.manrope(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setDlgState(() {
                        selectedTherapyId = v;
                        final found = available.firstWhere(
                          (p) => (p['id'] ?? p['name']) == v,
                          orElse: () => {},
                        );
                        selectedTherapyName = found['name'] as String?;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Catatan (opsional)',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                style: GoogleFonts.manrope(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Catatan program...',
                  hintStyle: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Batal',
                style: GoogleFonts.manrope(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: selectedTherapyId == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      setState(() => _isLoadingPrograms = true);
                      final patientId = widget.pasien['uid'] as String? ?? '';
                      final rm = widget.pasien['rm'] as String? ?? '';
                      final loggedIn = await AuthService.getLoggedInUser();
                      final result = await AuthService.addPatientTherapyProgram(
                        patientId: patientId,
                        patientRm: rm,
                        therapyProgramId: selectedTherapyId!,
                        therapyProgramName:
                            selectedTherapyName ?? selectedTherapyId!,
                        createdBy: loggedIn?['uid'] ?? '',
                        notes: notesCtrl.text,
                      );
                      if (result['success'] == true) {
                        final newProgramId =
                            result['patientProgramId'] as String?;

                        // Kirim notifikasi ke pasien: program baru ditambahkan
                        if (patientId.isNotEmpty) {
                          final agName =
                              loggedIn?['name'] as String? ?? 'Ahli Gizi';
                          final pName =
                              selectedTherapyName ??
                              selectedTherapyId ??
                              'Program Baru';
                          await FirebaseNotificationService.createNotification(
                            userId: patientId,
                            role: 'pasien',
                            title: 'Program Diet Baru Ditambahkan',
                            message:
                                'Ahli Gizi $agName telah menambahkan program diet baru "$pName" untuk Anda. '
                                'Buka beranda untuk melihat detail program.',
                            type: 'info',
                            relatedId: newProgramId ?? '',
                          );
                        }

                        await _loadInitialData();
                        // [FIX Bug 2] Auto-select ke program BARU yang ditambahkan,
                        // bukan ke active.first (yang menyebabkan program lama seolah hilang)
                        if (newProgramId != null && mounted) {
                          final newProg = _patientPrograms.firstWhere(
                            (p) => p['patientProgramId'] == newProgramId,
                            orElse: () => _patientPrograms.isNotEmpty
                                ? _patientPrograms.first
                                : <String, dynamic>{},
                          );
                          if (newProg.isNotEmpty) {
                            setState(() => _selectedPatientProgram = newProg);
                            await _loadNutrisiForProgram(newProg);
                          }
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result['message'] ??
                                    'Gagal menambahkan program.',
                                style: GoogleFonts.manrope(),
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          setState(() => _isLoadingPrograms = false);
                        }
                      }
                    },
              child: Text(
                'Tambahkan',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    notesCtrl.dispose();
  }
}
