import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/web_download.dart';
import '../../utils/age_calculator.dart';
import 'laporan_pasien_screen.dart';
import 'laporan_harian_ag_screen.dart';

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

  // ── Existing controllers ──
  final _targetCtrl = TextEditingController();

  // ── Clinical Inputs ──
  final _diagnosisCtrl = TextEditingController();
  final _catatanNutrisiCtrl = TextEditingController();
  final _customDietCtrl = TextEditingController();

  static const List<String> _terapiDietList = [
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
    'Diet Khusus/Lainnya'
  ];

  // ── Dynamic Nutrition Target controllers & state ──
  final Map<String, TextEditingController> _targetCtrls = {};
  final Map<String, TextEditingController> _aktualCtrls = {};
  final Map<String, bool> _checkedNutrients = {};

  static const Map<String, List<String>> _nutrientCategories = {
    'Makronutrien dan Cairan': [
      'Energi (kkal)', 'Protein (g)', 'Lemak (g)', 'Karbohidrat (g)', 'Serat (g)', 'Air (ml)'
    ],
    'Mineral': [
      'Kalsium (mg)', 'Fosfor (mg)', 'Magnesium (mg)', 'Besi (mg)', 'Iodium (mcg)',
      'Seng (mg)', 'Selenium (mcg)', 'Mangan (mg)', 'Fluor (mg)', 'Kromium (mcg)',
      'Kalium (mg)', 'Natrium (mg)', 'Klor (mg)', 'Tembaga (mcg)'
    ],
    'Vitamin': [
      'Vitamin A / Vit A (RE)', 'Vitamin D (mcg)', 'Vitamin E (mcg)', 'Vitamin K (mcg)',
      'Vitamin B1 (mg)', 'Vitamin B2 (mg)', 'Vitamin B3 (mg)', 'Vitamin B5 / Pantotenat (mg)',
      'Vitamin B6 (mg)', 'Folat (mcg)', 'Vitamin B12 (mcg)', 'Biotin (mcg)', 'Kolin (mg)', 'Vitamin C (mg)'
    ]
  };

  @override
  void initState() {
    super.initState();
    _status = widget.pasien['status'] ?? 'aktif';
    _targetCtrl.text = widget.pasien['target_diet'] ?? '';
    // Set default diet ke diet pertama pasien
    final diets = _getDietList();
    if (diets.isNotEmpty) _selectedDietType = diets.first;
    _loadNutrisi();
  }

  @override
  void dispose() {
    _targetCtrl.dispose();
    _diagnosisCtrl.dispose();
    _catatanNutrisiCtrl.dispose();
    for (var c in _targetCtrls.values) { c.dispose(); }
    for (var c in _aktualCtrls.values) { c.dispose(); }
    super.dispose();
  }

  List<String> _getDietList() {
    final raw = widget.pasien['diet_types'];
    if (raw is List && raw.isNotEmpty) return raw.cast<String>();
    final single = widget.pasien['diet_type'] as String? ?? '';
    return single.isEmpty ? ['(Belum ada diet)'] : [single];
  }

  Future<void> _loadNutrisi() async {
    final rm = widget.pasien['rm'] as String;
    
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
          
      final nutrisiDiet = await AuthService.getNutrisiPasienPerDiet(rm, effectiveDiet);
      if (mounted && nutrisiDiet != null) {
        setState(() {
          final Map<String, dynamic>? targetNutrients = nutrisiDiet['target_nutrients'];
          _checkedNutrients.clear();
          
          if (targetNutrients != null) {
            targetNutrients.forEach((key, val) {
              _checkedNutrients[key] = true;
              if (!_targetCtrls.containsKey(key)) _targetCtrls[key] = TextEditingController();
              _targetCtrls[key]!.text = _fmtNum(val['target']);
              // Load aktual yang sudah diinput AG sebelumnya
              if (!_aktualCtrls.containsKey(key)) _aktualCtrls[key] = TextEditingController();
              final aktualVal = (val['aktual'] as num?)?.toDouble() ?? 0.0;
              _aktualCtrls[key]!.text = aktualVal > 0 ? _fmtNum(aktualVal) : '';
            });
          }
        });
      }
    }

    final logs = await AuthService.getMealLogsForPasien(rm, days: 7);
    if (mounted) setState(() => _riwayatMakan = logs);
  }


  String _fmtNum(dynamic val) {
    if (val == null) return '';
    final d = (val as num).toDouble();
    return d == d.truncateToDouble() ? d.toInt().toString() : d.toStringAsFixed(1);
  }

  Future<void> _updateStatus(String newStatus) async {
    await AuthService.updatePasienStatus(
        widget.pasien['rm'] as String, newStatus);
    if (mounted) {
      setState(() => _status = newStatus);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Status pasien diperbarui: $newStatus.',
            style: GoogleFonts.manrope()),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _saveAll() async {
    setState(() => _isSaving = true);
    try {
      final rm = widget.pasien['rm'] as String;
      final String effectiveDiet = _selectedDietType == 'Diet Khusus/Lainnya' 
          ? _customDietCtrl.text 
          : (_selectedDietType ?? 'Diet Normal');

      // Prepare target AND aktual nutrients map
      Map<String, dynamic> targetNutrientsToSave = {};
      Map<String, dynamic> aktualNutrientsToSave = {};
      _checkedNutrients.forEach((key, checked) {
        if (checked) {
          final targetVal = double.tryParse(_targetCtrls[key]?.text ?? '0') ?? 0.0;
          targetNutrientsToSave[key] = {
            'target': targetVal,
            'aktual': double.tryParse(_aktualCtrls[key]?.text ?? '0') ?? 0.0,
          };
          aktualNutrientsToSave[key] = double.tryParse(_aktualCtrls[key]?.text ?? '0') ?? 0.0;
        }
      });

      // 1. Save Nutrisi Per Diet (Target + Aktualisasi dari AG)
      await AuthService.saveNutrisiPerDiet(
        rmPasien: rm,
        dietType: effectiveDiet,
        targetNutrients: targetNutrientsToSave,
        aktualNutrients: aktualNutrientsToSave,
        catatan: _catatanNutrisiCtrl.text,
      );

      // 2. Simpan data klinis ke model pasien (tanpa statusGizi)
      await AuthService.updateClinicalData(
        rm: rm,
        diagnosis: _diagnosisCtrl.text,
        catatanKlinis: _catatanNutrisiCtrl.text,
        terapiDiet: effectiveDiet,
      );

      // 3. Simpan target diet (text summary legacy)
      await AuthService.saveTargetDietPasien(
        rm: rm,
        targetDiet: _targetCtrl.text,
        catatanEvaluasi: _catatanNutrisiCtrl.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Data pasien berhasil disimpan! ✓',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${e.toString()}', style: GoogleFonts.manrope()),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String get _dietLabel => widget.pasien['diet_type'] ?? 'Normal';

  Color get _statusColor {
    switch (_status) {
      case 'berhasil':
        return const Color(0xFF0284C7);
      case 'meninggal':
        return const Color(0xFF6B7280);
      case 'dropout':
        return const Color(0xFFDC2626);
      default:
        return AppColors.primary;
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
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Detail Pasien',
            style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info Pasien ──
            _buildPasienCard(),
            const SizedBox(height: 12),
            _buildInfoGrid(),
            const SizedBox(height: 16),

            // ── Clinical Info ──
            _buildSectionLabel('Kondisi Klinis Pasien'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  _buildNutrisiField(
                      'Diagnosis (ICD 10)', _diagnosisCtrl, 'Ketik diagnosis...', '',
                      keyboardType: TextInputType.text),
                  const SizedBox(height: 12),
                  _buildNutrisiField('Catatan / Evaluasi Klinis',
                      _catatanNutrisiCtrl, 'Ketik catatan...', '',
                      keyboardType: TextInputType.multiline),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Terapi Diet Selection ──
            _buildSectionLabel('Pilih Terapi Diet'),
            const SizedBox(height: 8),
            _buildTerapiDietDropdown(),
            if (_selectedDietType == 'Diet Khusus/Lainnya') ...[
              const SizedBox(height: 12),
              _buildTextArea(_customDietCtrl, 'Ketik nama diet khusus...', 1),
            ],
            const SizedBox(height: 24),



            // ── NUTRISI SECTION ──
            _buildNutrisiSection(),
            const SizedBox(height: 24),

            // ── CAPAIAN GIZI SECTION ──
            _buildCapaianGiziSection(),
            const SizedBox(height: 24),
            
            // ── RIWAYAT CATATAN MAKANAN ──
            _buildRiwayatMakanSection(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => LaporanHarianAGScreen(
                        pasien: widget.pasien,
                      )));
                    },
                    icon: const Icon(Icons.bar_chart_rounded, size: 18, color: Colors.white),
                    label: Text('Laporan Harian', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => LaporanPasienScreen(pasien: widget.pasien)));
                    },
                    icon: const Icon(Icons.summarize_outlined, size: 18, color: AppColors.primary),
                    label: Text('Laporan Bulanan', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Ubah Status ──
            _buildSectionLabel('Ubah Status Pasien'),
            const SizedBox(height: 8),
            _buildStatusButtons(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WIDGET BUILDERS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPasienCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
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
                    color: _statusColor),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.pasien['name'] ?? '-',
                    style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                Text('RM: ${widget.pasien['rm'] ?? '-'}',
                    style: GoogleFonts.manrope(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildChip(_dietLabel, AppColors.primary),
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
    final bool hasConsent = widget.pasien['inform_consent_signed'] == true &&
        (((widget.pasien['consent_signature_base64'] as String?) ?? '').isNotEmpty ||
         ((widget.pasien['consent_signature_path'] as String?) ?? '').isNotEmpty);

    final String? base64Sig = widget.pasien['consent_signature_base64'] as String?;
    final String? filePath = widget.pasien['consent_signature_path'] as String?;
    final String? signedAt = widget.pasien['consent_signed_at'] as String?;

    final ageMap = AgeCalculator.calculateAge(widget.pasien['birthdate']);
    final kondisi = AgeCalculator.getKondisi(ageMap);
    final imt = AgeCalculator.calculateIMT(widget.pasien['weight'], widget.pasien['height']);
    
    final bbStr = widget.pasien['weight'] != null && widget.pasien['weight'].toString().isNotEmpty ? '${widget.pasien['weight']} kg' : '-';
    final tbStr = widget.pasien['height'] != null && widget.pasien['height'].toString().isNotEmpty ? '${widget.pasien['height']} cm' : '-';
    final genderStr = widget.pasien['gender'] ?? '-';
    final umurStr = AgeCalculator.formatAge(ageMap);

    Widget contactRow = _buildInfoRow('No. Telepon / WA', widget.pasien['phone'] ?? '-', trailing: widget.pasien['phone'] != null && widget.pasien['phone'].isNotEmpty ? GestureDetector(
      onTap: () async {
        String phone = widget.pasien['phone'].replaceAll(RegExp(r'\D'), '');
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
        decoration: BoxDecoration(color: const Color(0xFF25D366), borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.chat, size: 16, color: Colors.white),
      ),
    ) : null);
    
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
              color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: infoRows,
          ),
        ),
        const SizedBox(height: 12),
        // ── Informed Consent Card ──
        _buildConsentCard(hasConsent, base64Sig, filePath, signedAt),
      ],
    );
  }

  Widget _buildConsentCard(bool hasConsent, String? base64Sig, String? filePath, String? signedAt) {
    if (!hasConsent) {
      // Belum ada consent
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFCD34D)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Pasien belum menandatangani informed consent.',
                style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF92400E), fontWeight: FontWeight.w500),
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
                child: const Icon(Icons.assignment_turned_in_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Informed Consent',
                        style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    if (signedDateStr.isNotEmpty)
                      Text('Ditandatangani: $signedDateStr',
                          style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, color: Color(0xFF16A34A), size: 14),
                    const SizedBox(width: 4),
                    Text('Ditandatangani', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A))),
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
                  onPressed: () => _showConsentDialog(base64Sig, filePath, signedDateStr),
                  icon: const Icon(Icons.visibility_outlined, size: 16, color: AppColors.primary),
                  label: Text('Lihat', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _downloadConsent(widget.pasien['consent_doc_base64'] as String?, base64Sig, filePath, widget.pasien['rm'] ?? 'pasien'),
                  icon: const Icon(Icons.download_outlined, size: 16, color: Colors.white),
                  label: Text('Download', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  void _showConsentDialog(String? base64Sig, String? filePath, String signedDate) {
    final String? consentDocB64 = widget.pasien['consent_doc_base64'] as String?;


    Widget imageWidget;
    if (base64Sig != null && base64Sig.isNotEmpty) {
      final bytes = base64Decode(base64Sig);
      imageWidget = Image.memory(bytes, fit: BoxFit.contain);
    } else if (filePath != null && filePath.isNotEmpty && !kIsWeb) {
      imageWidget = Image.file(File(filePath), fit: BoxFit.contain);
    } else {
      imageWidget = Center(
        child: Text('Tanda tangan tidak tersedia.', style: GoogleFonts.manrope(color: AppColors.textSecondary)),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.assignment_turned_in, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Surat Persetujuan Program Diet',
                              style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                          Text('Informed Consent — ${widget.pasien['name'] ?? ''}',
                              style: GoogleFonts.manrope(fontSize: 11, color: Colors.white.withValues(alpha: 0.85))),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Body — dokumen lengkap
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
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified, color: Color(0xFF16A34A), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Disetujui & ditandatangani pada: $signedDate',
                                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A)),
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
                          color: const Color(0xFFF1FAF5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBBF0D4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DATA PASIEN', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 1.2)),
                            const SizedBox(height: 8),
                            _consentInfoRow('Nama Lengkap', widget.pasien['name'] ?? '-'),
                            _consentInfoRow('No. Rekam Medis', widget.pasien['rm'] ?? '-'),
                            _consentInfoRow('Tanggal Tanda Tangan', signedDate.isEmpty ? '-' : signedDate),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Judul dokumen
                      Center(
                        child: Text('SURAT PERSETUJUAN PROGRAM DIET',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: 0.5)),
                      ),
                      const SizedBox(height: 14),

                      // Isi consent
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saya dengan ini menyatakan bahwa saya telah memahami dan menyetujui untuk mengikuti Program Diet Klinik yang diselenggarakan oleh Clinical Diet.',
                              style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Saya memahami bahwa program ini melibatkan pemantauan asupan makanan, berat badan, tinggi badan, dan parameter gizi lainnya oleh ahli gizi yang telah ditunjuk.',
                              style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
                            ),
                            const SizedBox(height: 10),
                            ...consentPoints.asMap().entries.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    child: Text('${e.key + 1}.', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                  ),
                                  Expanded(
                                    child: Text(e.value, style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
                                  ),
                                ],
                              ),
                            )),
                            const SizedBox(height: 8),
                            Text(
                              'Dengan menandatangani dokumen ini, saya menyatakan bahwa saya telah membaca, memahami, dan menyetujui seluruh ketentuan di atas.',
                              style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Status persetujuan (checkbox)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 22, height: 22,
                              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                              child: const Icon(Icons.check, color: Colors.white, size: 14),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Saya telah membaca dan menyetujui seluruh ketentuan di atas',
                                style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tanda tangan
                      Text('TANDA TANGAN PASIEN',
                          style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
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
                          const Icon(Icons.info_outline, size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text('Tanda tangan digital pasien — ${widget.pasien['name'] ?? ''}',
                              style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Footer — tombol download
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: AppColors.divider),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Tutup', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _downloadConsent(consentDocB64, base64Sig, filePath, widget.pasien['rm'] ?? 'pasien');
                        },
                        icon: const Icon(Icons.download_outlined, size: 16, color: Colors.white),
                        label: Text('Download Dokumen', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            child: Text(label, style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadConsent(String? consentDocB64, String? base64Sig, String? filePath, String rm) async {
    if (kIsWeb) {
      if (consentDocB64 != null && consentDocB64.isNotEmpty) {
        // Download dokumen HTML lengkap (isi + centang + tanda tangan)
        String htmlContent;
        try {
          htmlContent = utf8.decode(base64Decode(consentDocB64));
        } catch (_) {
          htmlContent = String.fromCharCodes(base64Decode(consentDocB64));
        }

        try {
          final ByteData logoData = await rootBundle.load('assets/images/icon.png');
          final String logoBase64 = base64Encode(logoData.buffer.asUint8List());
          final String logoImg = '<img src="data:image/png;base64,$logoBase64" class="logo-img" alt="Logo" style="height: 28px; margin-right: 8px;">';

          // Ganti string rusak / lama dengan logo asli dan perbaiki styling headline
          htmlContent = htmlContent.replaceAllMapped(
            RegExp(r'<div class="logo-title">.*?Clinical Diet<\/div>'),
            (match) => '<div class="logo-title" style="display: flex; align-items: center; justify-content: center; font-size: 22px; font-weight: 800; color: #3B7A57; letter-spacing: 1px; margin-bottom: 4px; font-family: \'Manrope\', sans-serif;">$logoImg Clinical Diet</div>'
          );
          
          // Tambahkan import font jika belum ada
          if (!htmlContent.contains('Manrope')) {
             htmlContent = htmlContent.replaceFirst('<style>', '<link href="https://fonts.googleapis.com/css2?family=Manrope:wght@400;500;600;700;800&display=swap" rel="stylesheet">\n  <style>');
          }
        } catch (_) {}

        downloadHtmlFileOnWeb(htmlContent, 'informed_consent_$rm.html');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Dokumen informed_consent_$rm.html berhasil diunduh.', style: GoogleFonts.manrope()),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      } else if (base64Sig != null && base64Sig.isNotEmpty) {
        // Fallback: download hanya gambar tanda tangan
        downloadFileOnWeb(base64Sig, 'ttd_consent_$rm.png');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Tanda tangan berhasil diunduh sebagai ttd_consent_$rm.png', style: GoogleFonts.manrope()),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Data informed consent tidak tersedia.', style: GoogleFonts.manrope()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } else {
      if (filePath == null || filePath.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('File tanda tangan tidak tersedia.', style: GoogleFonts.manrope()),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('File tersimpan di: $filePath', style: GoogleFonts.manrope()),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Widget _buildTerapiDietDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDietType,
          isExpanded: true,
          hint: Text('Pilih Terapi Diet...', style: GoogleFonts.manrope(fontSize: 14)),
          items: _terapiDietList.map((d) => DropdownMenuItem(value: d, child: Text(d, style: GoogleFonts.manrope(fontSize: 14)))).toList(),
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

  Widget _buildNutrisiSection() {
    final List<String> allNutrients = _nutrientCategories.values.expand((e) => e).toList();
    final List<String> availableNutrients = allNutrients.where((n) => !(_checkedNutrients[n] ?? false)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Target Gizi Harian'),
        const SizedBox(height: 12),
        
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
              hint: Text('Tambah item gizi...', style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textSecondary)),
              items: availableNutrients.map((n) => DropdownMenuItem(value: n, child: Text(n, style: GoogleFonts.manrope(fontSize: 14)))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _checkedNutrients[val] = true;
                    if (!_targetCtrls.containsKey(val)) _targetCtrls[val] = TextEditingController();
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
          if (!_targetCtrls.containsKey(nutrient)) _targetCtrls[nutrient] = TextEditingController();
          
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
                  child: Text(nutrient, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _targetCtrls[nutrient],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'Nilai...',
                      hintStyle: GoogleFonts.manrope(fontSize: 12, color: AppColors.textMuted),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
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
          style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 12),
        if (_checkedNutrients.values.every((v) => !v))
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
            ),
            child: Text(
              'Pilih dan simpan target gizi terlebih dahulu, lalu isi aktualisasi di sini.',
              style: GoogleFonts.manrope(fontSize: 12, color: Colors.orange[800]),
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
              children: _checkedNutrients.entries.where((e) => e.value).map((e) {
                final nutrient = e.key;
                if (!_aktualCtrls.containsKey(nutrient)) {
                  _aktualCtrls[nutrient] = TextEditingController();
                }
                final target = double.tryParse(_targetCtrls[nutrient]?.text ?? '0') ?? 0.0;

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
                            style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          if (target > 0)
                            Text(
                              'Target: ${_fmtNum(target)}',
                              style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _aktualCtrls[nutrient],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Input aktualisasi $nutrient...',
                          hintStyle: GoogleFonts.manrope(color: AppColors.textMuted, fontSize: 13),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      Text('Tanggal: $displayDate', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary)),
                      if (log['berat_badan'] != null)
                        Text('BB: ${log['berat_badan']} kg', style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textSecondary)),
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
            child: Text('$label:', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(text, style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrisiField(String label, TextEditingController ctrl,
      String hint, String suffix,
      {TextInputType keyboardType =
          const TextInputType.numberWithOptions(decimal: true, signed: false)}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.manrope(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLines: keyboardType == TextInputType.multiline ? null : 1,
          style: GoogleFonts.manrope(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.manrope(color: AppColors.textMuted, fontSize: 13),
            suffixText: suffix,
            suffixStyle: GoogleFonts.manrope(
                color: AppColors.textSecondary, fontSize: 12),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                child:
                    _buildStatusButton('Aktif', 'aktif', AppColors.primary)),
            const SizedBox(width: 8),
            Expanded(
                child: _buildStatusButton(
                    'Berhasil', 'berhasil', const Color(0xFF0284C7))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: _buildStatusButton(
                    'Meninggal', 'meninggal', const Color(0xFF6B7280))),
            const SizedBox(width: 8),
            Expanded(
                child: _buildStatusButton(
                    'Dropout', 'dropout', const Color(0xFFDC2626))),
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
          top: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveAll,
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save_outlined, color: Colors.white, size: 20),
          label: Text(
            _isSaving ? 'MENYIMPAN...' : 'SIMPAN SEMUA DATA',
            style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPER WIDGETS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) => Text(label,
      style: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary));


  Widget _buildTextArea(
      TextEditingController ctrl, String hint, int maxLines) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style:
            GoogleFonts.manrope(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.manrope(
              color: AppColors.textMuted, fontSize: 13, height: 1.5),
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
      child: Text(label,
          style: GoogleFonts.manrope(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
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
            child: Text(label,
                style: GoogleFonts.manrope(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
              child: Text(value,
                  style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary))),
          if (trailing != null) trailing,
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
          child: Text(label,
              style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : color)),
        ),
      ),
    );
  }
}
