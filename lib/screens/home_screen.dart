import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import 'catatan_screen.dart';
import 'pilih_ahli_gizi_screen.dart';
import 'pilih_jenis_diet_screen.dart';
import 'edukasi_screen.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _nutrisi; // legacy/global nutrisi
  List<Map<String, dynamic>> _nutrisiPerDiet = []; // per-diet nutrisi
  List<Map<String, dynamic>> _bbHistory = [];
  Map<String, dynamic>? _lastMealLog; // catatan makan terakhir
  String _ahliGiziName = ''; // nama ahli gizi aktif
  bool _isLoading = true;
  int _dietPageIndex = 0;
  final PageController _dietPageCtrl = PageController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _dietPageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = await AuthService.getLoggedInUser();
    Map<String, dynamic>? nutrisi;
    List<Map<String, dynamic>> nutrisiPerDiet = [];
    List<Map<String, dynamic>> bbHistory = [];
    Map<String, dynamic>? lastMealLog;
    String ahliGiziName = '';

    if (user != null && user['rm'] != null) {
      final rm = user['rm'] as String;
      nutrisi = await AuthService.getNutrisiPasien(rm);
      nutrisiPerDiet = await AuthService.getAllNutrisiPasien(rm);

      // Load fresh user data for bb_history
      final freshUser = await AuthService.getPasienByRm(rm);
      bbHistory = AuthService.getBBTBHistory(freshUser ?? user);

      // Load catatan makan terakhir
      final mealLogs = await AuthService.getMealLogsForPasien(rm);
      if (mealLogs.isNotEmpty) {
        mealLogs.sort((a, b) {
          final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(2000);
          final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(2000);
          return dateB.compareTo(dateA);
        });
        lastMealLog = mealLogs.first;
      }

      // Load nama ahli gizi
      final nip = (user['ahli_gizi_nip'] ?? user['selected_ahli_gizi_nip']) as String? ?? '';
      if (nip.isNotEmpty) {
        final allAG = await AuthService.getAllAhliGizi();
        try {
          final ag = allAG.firstWhere((a) => a['nip'] == nip);
          ahliGiziName = ag['name'] as String? ?? '';
        } catch (_) {}
      }
    }
    if (mounted) {
      setState(() {
        _user = user;
        _nutrisi = nutrisi;
        _nutrisiPerDiet = nutrisiPerDiet;
        _bbHistory = bbHistory;
        _lastMealLog = lastMealLog;
        _ahliGiziName = ahliGiziName;
        _isLoading = false;
      });
    }
  }

  // ── Getters nutrisi (dari halaman diet aktif saat ini) ──
  Map<String, dynamic>? get _currentDietNutrisi =>
      _nutrisiPerDiet.isNotEmpty ? _nutrisiPerDiet[_dietPageIndex] : _nutrisi;

  double get _kaloriTarget => (_currentDietNutrisi?['kalori_target'] as num?)?.toDouble() ?? 0;
  double get _kaloriAktual => (_currentDietNutrisi?['kalori_aktual'] as num?)?.toDouble() ?? 0;
  double get _kaloriPercent => _kaloriTarget > 0 ? (_kaloriAktual / _kaloriTarget).clamp(0.0, 1.0) : 0.0;

  double get _proteinTarget => (_currentDietNutrisi?['protein_target'] as num?)?.toDouble() ?? 0;
  double get _proteinAktual => (_currentDietNutrisi?['protein_aktual'] as num?)?.toDouble() ?? 0;
  double get _proteinPercent => _proteinTarget > 0 ? (_proteinAktual / _proteinTarget).clamp(0.0, 1.0) : 0.0;

  double get _lemakTarget => (_currentDietNutrisi?['lemak_target'] as num?)?.toDouble() ?? 0;
  double get _lemakAktual => (_currentDietNutrisi?['lemak_aktual'] as num?)?.toDouble() ?? 0;
  double get _lemakPercent => _lemakTarget > 0 ? (_lemakAktual / _lemakTarget).clamp(0.0, 1.0) : 0.0;

  double get _karboTarget => (_currentDietNutrisi?['karbo_target'] as num?)?.toDouble() ?? 0;
  double get _karboAktual => (_currentDietNutrisi?['karbo_aktual'] as num?)?.toDouble() ?? 0;
  double get _karboPercent => _karboTarget > 0 ? (_karboAktual / _karboTarget).clamp(0.0, 1.0) : 0.0;

  double get _seratAktual => (_currentDietNutrisi?['serat_aktual'] as num?)?.toDouble() ?? 0;
  double get _seratTarget => (_currentDietNutrisi?['serat_target'] as num?)?.toDouble() ?? 30;
  double get _hidrasiAktual => (_currentDietNutrisi?['hidrasi_aktual'] as num?)?.toDouble() ?? 0;
  double get _hidrasiTarget => (_currentDietNutrisi?['hidrasi_target'] as num?)?.toDouble() ?? 2.5;

  // ── BB/TB dari histori terakhir ──
  double get _bbTerakhir {
    if (_bbHistory.isNotEmpty) {
      return double.tryParse(_bbHistory.first['weight']?.toString() ?? '') ?? 0.0;
    }
    return double.tryParse(_user?['weight']?.toString() ?? '') ?? 0.0;
  }

  double get _tbTerakhir {
    if (_bbHistory.isNotEmpty) {
      return double.tryParse(_bbHistory.first['height']?.toString() ?? '') ?? 0.0;
    }
    return double.tryParse(_user?['height']?.toString() ?? '') ?? 0.0;
  }

  // ── Evaluasi ahli gizi dari nutrisi per diet (diet pertama/aktif) ──
  String get _evaluasiAhliGizi {
    if (_nutrisiPerDiet.isNotEmpty) {
      return _currentDietNutrisi?['evaluasi_ahli_gizi'] ?? '';
    }
    return _user?['catatan_evaluasi'] ?? '';
  }

  // ── Daftar diet aktif pasien ──
  List<String> get _dietList {
    final raw = _user?['diet_types'];
    if (raw is List && raw.isNotEmpty) return raw.cast<String>();
    final single = _user?['diet_type'] as String? ?? '';
    return single.isEmpty ? [] : [single];
  }

  String _fmt(double val) =>
      val == val.truncateToDouble() ? val.toInt().toString() : val.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadData,
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(context),
                  // ── Quick Actions (Pilih/Ganti Diet & Ahli Gizi) ──
                  _buildQuickActions(context),
                  // ── BB/TB Harian ──
                  _buildBBTBCard(),
                  // ── Diet Swipeable Cards ──
                  _buildDietSection(),
                  // ── Evaluasi Ahli Gizi ──
                  if (_evaluasiAhliGizi.isNotEmpty) _buildEvaluasiCard(),
                  // ── Catatan Makan Terakhir ──
                  if (_lastMealLog != null) _buildLastMealCard(),
                  if (_currentDietNutrisi != null) _buildNutritionSummary(),
                  _buildReminderCard(context),
                  _buildEdukasiCard(context),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            // FAB Catatan Makan
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton.extended(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CatatanScreen()),
                  );
                  _loadData(); // refresh setelah kembali
                },
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
                label: Text('Catat Makan', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildNoDataState() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.monitor_heart_outlined,
                size: 52, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'Belum Ada Data Nutrisi',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Ahli gizi Anda belum menginput target dan realisasi nutrisi harian. Hubungi ahli gizi Anda melalui tab Profil.',
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, color: AppColors.primary, size: 18),
            label: Text('Perbarui Data',
                style: GoogleFonts.manrope(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Actions: Ganti Ahli Gizi / Diet ───────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PilihJenisDietScreen(isFromProfil: true)),
          );
          _loadData();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ]
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Program Diet Baru', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text('Pilih diet & Ahli Gizi Anda', style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }


  // ── BB/TB Card ──────────────────────────────────────────────────────────────
  Widget _buildBBTBCard() {
    final bmi = _tbTerakhir > 0 ? _bbTerakhir / ((_tbTerakhir / 100) * (_tbTerakhir / 100)) : 0.0;
    final bmiLabel = bmi == 0 ? '-' : bmi < 18.5 ? 'Kurus' : bmi < 25 ? 'Normal' : bmi < 30 ? 'Gemuk' : 'Obesitas';
    final bmiColor = bmi == 0 ? AppColors.textMuted : bmi < 18.5 ? const Color(0xFF0284C7) : bmi < 25 ? AppColors.primary : bmi < 30 ? const Color(0xFFD97706) : const Color(0xFFDC2626);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.monitor_weight_outlined, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text('Data Fisik Terakhir', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: bmiColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(bmiLabel, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: bmiColor)),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildPhysCard('BB', '${_fmt(_bbTerakhir)} kg', Icons.fitness_center)),
          const SizedBox(width: 10),
          Expanded(child: _buildPhysCard('TB', '${_fmt(_tbTerakhir)} cm', Icons.height)),
          const SizedBox(width: 10),
          Expanded(child: _buildPhysCard('IMT', bmi > 0 ? _fmt(bmi) : '-', Icons.calculate_outlined)),
        ]),
      ]),
    );
  }

  Widget _buildPhysCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        Text(label, style: GoogleFonts.manrope(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
      ]),
    );
  }

  // ── Diet Swipeable Section ─────────────────────────────────────────
  Widget _buildDietSection() {
    if (_nutrisiPerDiet.isNotEmpty) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(children: [
            Text('PROGRAM DIET', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.2)),
            const Spacer(),
            if (_nutrisiPerDiet.length > 1)
              Text('geser →', style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textMuted)),
          ]),
        ),
        SizedBox(
          height: 290,
          child: PageView.builder(
            controller: _dietPageCtrl,
            itemCount: _nutrisiPerDiet.length,
            onPageChanged: (idx) => setState(() => _dietPageIndex = idx),
            itemBuilder: (ctx, idx) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildDietCard(_nutrisiPerDiet[idx], idx),
            ),
          ),
        ),
        if (_nutrisiPerDiet.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(
              _nutrisiPerDiet.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _dietPageIndex ? 20 : 8, height: 8,
                decoration: BoxDecoration(color: i == _dietPageIndex ? AppColors.primary : AppColors.divider, borderRadius: BorderRadius.circular(4)),
              ),
            )),
          ),
      ]);
    }
    return _currentDietNutrisi == null ? _buildNoDataState() : _buildCalorieRing();
  }

  Widget _buildDietCard(Map<String, dynamic> n, int idx) {
    final dietName = n['diet_type'] as String? ?? 'Diet ${idx + 1}';
    final kT = (n['kalori_target'] as num?)?.toDouble() ?? 0;
    final kA = (n['kalori_aktual'] as num?)?.toDouble() ?? 0;
    final kPct = kT > 0 ? (kA / kT).clamp(0.0, 1.0) : 0.0;
    final pA = (n['protein_aktual'] as num?)?.toDouble() ?? 0;
    final pT = (n['protein_target'] as num?)?.toDouble() ?? 0;
    final lA = (n['lemak_aktual'] as num?)?.toDouble() ?? 0;
    final lT = (n['lemak_target'] as num?)?.toDouble() ?? 0;
    final cA = (n['karbo_aktual'] as num?)?.toDouble() ?? 0;
    final cT = (n['karbo_target'] as num?)?.toDouble() ?? 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
            child: Text(dietName, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          const Spacer(),
          Text('${(kPct * 100).toInt()}% terpenuhi', style: GoogleFonts.manrope(fontSize: 11, color: Colors.white.withValues(alpha: 0.85))),
        ]),
        const SizedBox(height: 14),
        Text('${_fmt(kA)} / ${_fmt(kT)} kkal', style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 4),
        Text('Kalori Aktual / Target', style: GoogleFonts.manrope(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: kPct, backgroundColor: Colors.white.withValues(alpha: 0.25), color: Colors.white, minHeight: 8)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _buildMiniNutri('Protein', pA, pT, 'g')),
          Expanded(child: _buildMiniNutri('Lemak', lA, lT, 'g')),
          Expanded(child: _buildMiniNutri('Karbo', cA, cT, 'g')),
        ]),
        if ((n['catatan'] as String? ?? '').isNotEmpty) ...[const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Text(n['catatan'] as String, style: GoogleFonts.manrope(fontSize: 11, color: Colors.white, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ]),
    );
  }

  Widget _buildMiniNutri(String label, double aktual, double target, String unit) {
    final pct = target > 0 ? (aktual / target).clamp(0.0, 1.0) : 0.0;
    return Column(children: [
      Text(label, style: GoogleFonts.manrope(fontSize: 10, color: Colors.white.withValues(alpha: 0.7))),
      const SizedBox(height: 4),
      Text('${_fmt(aktual)}$unit', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(height: 4),
      ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: pct, backgroundColor: Colors.white.withValues(alpha: 0.2), color: Colors.white.withValues(alpha: 0.85), minHeight: 4)),
    ]);
  }

  // ── Evaluasi Ahli Gizi Card ────────────────────────────────────────
  Widget _buildEvaluasiCard() {
    final dietType = _currentDietNutrisi?['diet_type'] as String? ?? '';
    final ahliGizi = _ahliGiziName.isNotEmpty ? _ahliGiziName : 'Ahli Gizi';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(9)),
                  child: const Icon(Icons.assignment_turned_in_outlined, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Evaluasi Ahli Gizi', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                      if (dietType.isNotEmpty)
                        Text(dietType, style: GoogleFonts.manrope(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                // Badge nama AG
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    ahliGizi.split(',').first.split(' ').first,
                    style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                  ),
                ),
              ],
            ),
          ),
          // Body teks evaluasi
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _evaluasiAhliGizi,
              style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textPrimary, height: 1.7),
            ),
          ),
        ],
      ),
    );
  }

  // ── Catatan Makan Terakhir ──────────────────────────────────────────
  Widget _buildLastMealCard() {
    final log = _lastMealLog!;
    final date = DateTime.tryParse(log['date'] ?? '') ?? DateTime.now();
    final dateStr = '${date.day}/${date.month}/${date.year}';
    final bb = (log['berat_badan'] as num?)?.toDouble();
    final tb = (log['tinggi_badan'] as num?)?.toDouble();

    final sessions = [
      {'label': 'Pagi', 'icon': Icons.wb_sunny_outlined, 'color': const Color(0xFFF59E0B), 'bg': const Color(0xFFFEF3C7), 'meal': log['meal_pagi'] ?? '', 'jam': log['jam_pagi'] ?? ''},
      {'label': 'Selingan Pagi', 'icon': Icons.local_cafe_outlined, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFEDE9FE), 'meal': log['selingan_pagi'] ?? '', 'jam': log['jam_selingan_pagi'] ?? ''},
      {'label': 'Siang', 'icon': Icons.wb_cloudy_outlined, 'color': const Color(0xFF0284C7), 'bg': const Color(0xFFDBEAFE), 'meal': log['meal_siang'] ?? '', 'jam': log['jam_siang'] ?? ''},
      {'label': 'Selingan Sore', 'icon': Icons.local_pizza_outlined, 'color': const Color(0xFFEA580C), 'bg': const Color(0xFFFEF0E8), 'meal': log['selingan_sore'] ?? '', 'jam': log['jam_selingan_sore'] ?? ''},
      {'label': 'Malam', 'icon': Icons.nightlight_outlined, 'color': const Color(0xFF1D4ED8), 'bg': const Color(0xFFDBEAFE), 'meal': log['meal_malam'] ?? '', 'jam': log['jam_malam'] ?? ''},
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(9)),
                  child: const Icon(Icons.restaurant_outlined, color: Color(0xFF2563EB), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Catatan Makan Terakhir', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      Text(dateStr, style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                // BB/TB dari log
                if (bb != null && tb != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      '${bb.toStringAsFixed(1)} kg • ${tb.toStringAsFixed(0)} cm',
                      style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                    ),
                  ),
              ],
            ),
          ),

          // Sesi makan
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              children: sessions.map((s) {
                final meal = s['meal'] as String;
                final jam = s['jam'] as String;
                if (meal.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: s['bg'] as Color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(s['icon'] as IconData, color: s['color'] as Color, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(s['label'] as String, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                                if (jam.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Text(jam, style: GoogleFonts.manrope(fontSize: 10, color: AppColors.textMuted)),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(meal, style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final firstName = (_user?['name'] as String? ?? '').split(' ').first;
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, $firstName 👋',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Pantau nutrisimu hari ini',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'PASIEN',
                  style: GoogleFonts.manrope(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tidak ada notifikasi baru.', style: GoogleFonts.manrope()),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieRing() {
    final isComplete = _kaloriPercent >= 1.0;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: CircularPercentIndicator(
          radius: 90,
          lineWidth: 12,
          percent: _kaloriPercent,
          backgroundColor: AppColors.divider,
          progressColor:
              isComplete ? const Color(0xFF059669) : AppColors.primary,
          circularStrokeCap: CircularStrokeCap.round,
          center: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'HARI INI',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                _fmt(_kaloriAktual),
                style: GoogleFonts.manrope(
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
              Text(
                'Kkal dikonsumsi',
                style: GoogleFonts.manrope(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                'Target: ${_fmt(_kaloriTarget)} Kkal',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionSummary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(9)
                ),
                child: const Icon(Icons.analytics_outlined, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Target & Capaian Nutrisi',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildNutrientRow(
              'PROTEIN',
              _proteinPercent,
              AppColors.protein,
              '${_fmt(_proteinAktual)}g / ${_fmt(_proteinTarget)}g'),
          const SizedBox(height: 12),
          _buildNutrientRow(
              'LEMAK SEHAT',
              _lemakPercent,
              AppColors.fat,
              '${_fmt(_lemakAktual)}g / ${_fmt(_lemakTarget)}g'),
          const SizedBox(height: 12),
          _buildNutrientRow(
              'KARBOHIDRAT',
              _karboPercent,
              AppColors.carb,
              '${_fmt(_karboAktual)}g / ${_fmt(_karboTarget)}g'),
        ],
      ),
    );
  }

  Widget _buildEdukasiCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.2))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(9)),
                  child: const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Edukasi & Leaflet', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                      Text('Artikel rekomendasi ahli', style: GoogleFonts.manrope(fontSize: 11, color: AppColors.primary)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EdukasiScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text('Lihat', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildLeafletItem(
                  'Panduan Gizi Seimbang',
                  'Tips mengatur asupan makanan sehat.',
                  Icons.local_dining_outlined,
                ),
                const SizedBox(height: 12),
                _buildLeafletItem(
                  'Mengenal Indeks Glikemik',
                  'Pilih karbohidrat yang tepat.',
                  Icons.monitor_heart_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeafletItem(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.textSecondary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle, style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 16),
      ],
    );
  }

  Widget _buildNutrientRow(
      String label, double percent, Color color, String caption) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              caption,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearPercentIndicator(
          padding: EdgeInsets.zero,
          lineHeight: 8,
          percent: min(percent, 1.0),
          backgroundColor: AppColors.divider,
          progressColor: color,
          barRadius: const Radius.circular(4),
        ),
      ],
    );
  }

  Widget _buildDailyTargetChart() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grafik Target Harian',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1.2, // 120% max
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        );
                        String text;
                        switch (value.toInt()) {
                          case 0: text = 'Kalori'; break;
                          case 1: text = 'Protein'; break;
                          case 2: text = 'Lemak'; break;
                          case 3: text = 'Karbo'; break;
                          default: text = ''; break;
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(text, style: style),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text('${(value * 100).toInt()}%', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: _kaloriPercent, color: AppColors.primary, width: 16, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: _proteinPercent, color: AppColors.protein, width: 16, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: _lemakPercent, color: AppColors.fat, width: 16, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: _karboPercent, color: AppColors.carb, width: 16, borderRadius: BorderRadius.circular(4))]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.restaurant_menu_outlined,
                  color: Color(0xFFF59E0B), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Jangan lupa catat makan hari ini!',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CatatanScreen()),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                'Catat',
                style: GoogleFonts.manrope(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Kode lama dihapus
}
