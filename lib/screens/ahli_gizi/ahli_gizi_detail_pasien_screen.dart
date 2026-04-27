import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../grafik_harian_screen.dart';

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

  // ── Existing controllers ──
  final _evaluasiCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();

  // ── Nutrition Target controllers ──
  final _kaloriTargetCtrl = TextEditingController();
  final _proteinTargetCtrl = TextEditingController();
  final _lemakTargetCtrl = TextEditingController();
  final _karboTargetCtrl = TextEditingController();

  // ── Nutrition Actual controllers ──
  final _kaloriAktualCtrl = TextEditingController();
  final _proteinAktualCtrl = TextEditingController();
  final _lemakAktualCtrl = TextEditingController();
  final _karboAktualCtrl = TextEditingController();

  // ── Other monitoring controllers ──
  final _seratAktualCtrl = TextEditingController();
  final _seratTargetCtrl = TextEditingController();
  final _hidrasiAktualCtrl = TextEditingController();
  final _hidrasiTargetCtrl = TextEditingController();
  final _catatanNutrisiCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _status = widget.pasien['status'] ?? 'aktif';
    _targetCtrl.text = widget.pasien['target_diet'] ?? '';
    _evaluasiCtrl.text = widget.pasien['catatan_evaluasi'] ?? '';
    _loadNutrisi();
  }

  @override
  void dispose() {
    _evaluasiCtrl.dispose();
    _targetCtrl.dispose();
    _kaloriTargetCtrl.dispose();
    _proteinTargetCtrl.dispose();
    _lemakTargetCtrl.dispose();
    _karboTargetCtrl.dispose();
    _kaloriAktualCtrl.dispose();
    _proteinAktualCtrl.dispose();
    _lemakAktualCtrl.dispose();
    _karboAktualCtrl.dispose();
    _seratAktualCtrl.dispose();
    _seratTargetCtrl.dispose();
    _hidrasiAktualCtrl.dispose();
    _hidrasiTargetCtrl.dispose();
    _catatanNutrisiCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadNutrisi() async {
    final rm = widget.pasien['rm'] as String;
    final nutrisi = await AuthService.getNutrisiPasien(rm);
    if (mounted && nutrisi != null) {
      setState(() {
        _kaloriTargetCtrl.text = _fmtNum(nutrisi['kalori_target']);
        _proteinTargetCtrl.text = _fmtNum(nutrisi['protein_target']);
        _lemakTargetCtrl.text = _fmtNum(nutrisi['lemak_target']);
        _karboTargetCtrl.text = _fmtNum(nutrisi['karbo_target']);
        _kaloriAktualCtrl.text = _fmtNum(nutrisi['kalori_aktual']);
        _proteinAktualCtrl.text = _fmtNum(nutrisi['protein_aktual']);
        _lemakAktualCtrl.text = _fmtNum(nutrisi['lemak_aktual']);
        _karboAktualCtrl.text = _fmtNum(nutrisi['karbo_aktual']);
        _seratAktualCtrl.text = _fmtNum(nutrisi['serat_aktual']);
        _seratTargetCtrl.text = _fmtNum(nutrisi['serat_target']);
        _hidrasiAktualCtrl.text = _fmtNum(nutrisi['hidrasi_aktual']);
        _hidrasiTargetCtrl.text = _fmtNum(nutrisi['hidrasi_target']);
        _catatanNutrisiCtrl.text = nutrisi['catatan'] ?? '';
      });
    }
    
    final logs = await AuthService.getMealLogsForPasien(rm, days: 7);
    if (mounted) {
      setState(() {
        _riwayatMakan = logs;
      });
    }
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

      // Parse nutrition values
      final kaloriTarget = double.tryParse(_kaloriTargetCtrl.text) ?? 0;
      final proteinTarget = double.tryParse(_proteinTargetCtrl.text) ?? 0;
      final lemakTarget = double.tryParse(_lemakTargetCtrl.text) ?? 0;
      final karboTarget = double.tryParse(_karboTargetCtrl.text) ?? 0;
      final kaloriAktual = double.tryParse(_kaloriAktualCtrl.text) ?? 0;
      final proteinAktual = double.tryParse(_proteinAktualCtrl.text) ?? 0;
      final lemakAktual = double.tryParse(_lemakAktualCtrl.text) ?? 0;
      final karboAktual = double.tryParse(_karboAktualCtrl.text) ?? 0;
      final seratAktual = double.tryParse(_seratAktualCtrl.text) ?? 0;
      final seratTarget = double.tryParse(_seratTargetCtrl.text) ?? 30;
      final hidrasiAktual = double.tryParse(_hidrasiAktualCtrl.text) ?? 0;
      final hidrasiTarget = double.tryParse(_hidrasiTargetCtrl.text) ?? 2.5;

      // 1. Simpan data nutrisi
      await AuthService.saveNutrisiPasien(
        rmPasien: rm,
        energiTarget: kaloriTarget,
        proteinTarget: proteinTarget,
        lemakTarget: lemakTarget,
        karboTarget: karboTarget,
        energiAktual: kaloriAktual,
        proteinAktual: proteinAktual,
        lemakAktual: lemakAktual,
        karboAktual: karboAktual,
        seratAktual: seratAktual,
        seratTarget: seratTarget,
        hidrasiAktual: hidrasiAktual,
        hidrasiTarget: hidrasiTarget,
        catatan: _catatanNutrisiCtrl.text,
      );

      // 2. Simpan target diet & CPPT
      await AuthService.saveTargetDietPasien(
        rm: rm,
        targetDiet: _targetCtrl.text,
        catatanEvaluasi: _evaluasiCtrl.text,
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

            // ── Target Diet ──
            _buildSectionLabel('Target Diet Pasien'),
            const SizedBox(height: 8),
            _buildTextArea(_targetCtrl,
                'Tuliskan target diet yang ingin dicapai pasien...', 3),
            const SizedBox(height: 16),

            // ── Catatan Evaluasi CPPT ──
            _buildSectionLabel('Catatan Evaluasi (CPPT)'),
            const SizedBox(height: 8),
            _buildTextArea(
                _evaluasiCtrl, 'Ketik evaluasi perkembangan diet pasien...', 5),
            const SizedBox(height: 24),

            // ── NUTRISI SECTION ──
            _buildNutrisiSection(),
            const SizedBox(height: 24),
            
            // ── RIWAYAT CATATAN MAKANAN ──
            _buildRiwayatMakanSection(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => GrafikHarianScreen(
                    rmPasien: widget.pasien['rm'],
                    namaPasien: widget.pasien['name'],
                  )));
                },
                icon: const Icon(Icons.show_chart, size: 18, color: AppColors.primary),
                label: Text('Lihat Grafik Perkembangan Pasien', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: AppColors.primary)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildInfoRow('Jenis Kelamin', widget.pasien['gender'] ?? '-'),
          _buildInfoRow('Tanggal Lahir', widget.pasien['birthdate'] ?? '-'),
          _buildInfoRow('No. Telepon / WA', widget.pasien['phone'] ?? '-'),
          _buildInfoRow(
              'Berat Badan', '${widget.pasien['weight'] ?? '-'} kg'),
          _buildInfoRow(
              'Tinggi Badan', '${widget.pasien['height'] ?? '-'} cm'),
          _buildInfoRow('Email', widget.pasien['email'] ?? '-'),
        ],
      ),
    );
  }

  Widget _buildNutrisiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header nutrisi ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD1FAE5), Color(0xFFECFDF5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_dining,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Data Nutrisi Pasien',
                      style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark)),
                  Text('Target & Realisasi Harian (diisi Ahli Gizi)',
                      style: GoogleFonts.manrope(
                          fontSize: 12, color: AppColors.primary)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Sub-section: Target Harian ──
        _buildSubSectionLabel(
            'TARGET HARIAN', 'Kebutuhan nutrisi sesuai kondisi pasien'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: _buildNutrisiField(
                          'Kalori Target', _kaloriTargetCtrl, '2000', 'kkal')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildNutrisiField(
                          'Protein Target', _proteinTargetCtrl, '75', 'g')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _buildNutrisiField(
                          'Lemak Target', _lemakTargetCtrl, '65', 'g')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildNutrisiField(
                          'Karbo Target', _karboTargetCtrl, '300', 'g')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Sub-section: Realisasi Aktual ──
        _buildSubSectionLabel('REALISASI AKTUAL',
            'Penilaian asupan berdasarkan catatan makan pasien'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: _buildNutrisiField(
                          'Kalori Aktual', _kaloriAktualCtrl, '0', 'kkal')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildNutrisiField(
                          'Protein Aktual', _proteinAktualCtrl, '0', 'g')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _buildNutrisiField(
                          'Lemak Aktual', _lemakAktualCtrl, '0', 'g')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildNutrisiField(
                          'Karbo Aktual', _karboAktualCtrl, '0', 'g')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Sub-section: Monitoring Lainnya ──
        _buildSubSectionLabel(
            'MONITORING LAINNYA', 'Serat dan hidrasi pasien'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: _buildNutrisiField(
                          'Serat Aktual', _seratAktualCtrl, '0', 'g')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildNutrisiField(
                          'Target Serat', _seratTargetCtrl, '30', 'g')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _buildNutrisiField(
                          'Hidrasi Aktual', _hidrasiAktualCtrl, '0', 'L')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildNutrisiField(
                          'Target Hidrasi', _hidrasiTargetCtrl, '2.5', 'L')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Catatan untuk pasien (tampil di beranda) ──
        _buildSubSectionLabel('CATATAN UNTUK PASIEN',
            'Pesan ini akan tampil di Beranda pasien'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: TextField(
            controller: _catatanNutrisiCtrl,
            maxLines: 4,
            style:
                GoogleFonts.manrope(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText:
                  'Contoh: "Asupan protein Anda sudah baik! Coba tambahkan sayuran hijau untuk memenuhi kebutuhan serat dan vitamin."',
              hintStyle: GoogleFonts.manrope(
                  color: AppColors.textMuted, fontSize: 13, height: 1.5),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
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
      String hint, String suffix) {
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
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true, signed: false),
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
    return Row(
      children: [
        Expanded(
            child:
                _buildStatusButton('Aktif', 'aktif', AppColors.primary)),
        const SizedBox(width: 8),
        Expanded(
            child: _buildStatusButton(
                'Berhasil', 'berhasil', const Color(0xFF0284C7))),
        const SizedBox(width: 8),
        Expanded(
            child: _buildStatusButton(
                'Meninggal', 'meninggal', const Color(0xFF6B7280))),
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

  Widget _buildSubSectionLabel(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(width: 3, height: 18, color: AppColors.primary,
            margin: const EdgeInsets.only(right: 8)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.textMuted)),
            Text(subtitle,
                style: GoogleFonts.manrope(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }

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

  Widget _buildInfoRow(String label, String value) {
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
