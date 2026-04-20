import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _nutrisi;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await AuthService.getLoggedInUser();
    Map<String, dynamic>? nutrisi;
    if (user != null && user['rm'] != null) {
      nutrisi = await AuthService.getNutrisiPasien(user['rm'] as String);
    }
    if (mounted) {
      setState(() {
        _user = user;
        _nutrisi = nutrisi;
        _isLoading = false;
      });
    }
  }

  // ── Getters nutrisi ──
  double get _kaloriTarget =>
      (_nutrisi?['kalori_target'] as num?)?.toDouble() ?? 0;
  double get _kaloriAktual =>
      (_nutrisi?['kalori_aktual'] as num?)?.toDouble() ?? 0;
  double get _kaloriPercent => _kaloriTarget > 0
      ? (_kaloriAktual / _kaloriTarget).clamp(0.0, 1.0)
      : 0.0;

  double get _proteinTarget =>
      (_nutrisi?['protein_target'] as num?)?.toDouble() ?? 0;
  double get _proteinAktual =>
      (_nutrisi?['protein_aktual'] as num?)?.toDouble() ?? 0;
  double get _proteinPercent => _proteinTarget > 0
      ? (_proteinAktual / _proteinTarget).clamp(0.0, 1.0)
      : 0.0;

  double get _lemakTarget =>
      (_nutrisi?['lemak_target'] as num?)?.toDouble() ?? 0;
  double get _lemakAktual =>
      (_nutrisi?['lemak_aktual'] as num?)?.toDouble() ?? 0;
  double get _lemakPercent => _lemakTarget > 0
      ? (_lemakAktual / _lemakTarget).clamp(0.0, 1.0)
      : 0.0;

  double get _karboTarget =>
      (_nutrisi?['karbo_target'] as num?)?.toDouble() ?? 0;
  double get _karboAktual =>
      (_nutrisi?['karbo_aktual'] as num?)?.toDouble() ?? 0;
  double get _karboPercent => _karboTarget > 0
      ? (_karboAktual / _karboTarget).clamp(0.0, 1.0)
      : 0.0;

  double get _seratAktual =>
      (_nutrisi?['serat_aktual'] as num?)?.toDouble() ?? 0;
  double get _seratTarget =>
      (_nutrisi?['serat_target'] as num?)?.toDouble() ?? 30;
  double get _hidrasiAktual =>
      (_nutrisi?['hidrasi_aktual'] as num?)?.toDouble() ?? 0;
  double get _hidrasiTarget =>
      (_nutrisi?['hidrasi_target'] as num?)?.toDouble() ?? 2.5;

  /// Format angka: tanpa desimal jika bulat, 1 desimal jika tidak.
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
                  _nutrisi == null
                      ? _buildNoDataState()
                      : _buildCalorieRing(),
                  if (_nutrisi != null) _buildNutritionSummary(),
                  _buildReminderCard(context),
                  if (_nutrisi != null) _buildDailyReport(),
                  if (_nutrisi != null) _buildBottomStats(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            // FAB
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Buka tab "Catatan" di bawah untuk mencatat makan.',
                        style: GoogleFonts.manrope(),
                      ),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                backgroundColor: AppColors.primary,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
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
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_outlined,
                    color: AppColors.textSecondary, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
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
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Vitalitas Harian',
            style: GoogleFonts.manrope(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildNutrientRow(
              'PROTEIN',
              _proteinPercent,
              AppColors.protein,
              '${_fmt(_proteinAktual)}g / ${_fmt(_proteinTarget)}g'),
          const SizedBox(height: 10),
          _buildNutrientRow(
              'LEMAK SEHAT',
              _lemakPercent,
              AppColors.fat,
              '${_fmt(_lemakAktual)}g / ${_fmt(_lemakTarget)}g'),
          const SizedBox(height: 10),
          _buildNutrientRow(
              'KARBOHIDRAT',
              _karboPercent,
              AppColors.carb,
              '${_fmt(_karboAktual)}g / ${_fmt(_karboTarget)}g'),
        ],
      ),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Buka tab "Catatan" untuk mencatat makan.',
                      style: GoogleFonts.manrope(),
                    ),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
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

  Widget _buildDailyReport() {
    final catatan = (_nutrisi?['catatan'] as String?) ?? '';
    final lastUpdated = _nutrisi?['updated_at'] as String?;
    String updatedStr = '';
    if (lastUpdated != null) {
      try {
        final dt = DateTime.parse(lastUpdated);
        updatedStr = '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_outlined,
                    color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Catatan Ahli Gizi',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            if (updatedStr.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'TERAKHIR DIPERBARUI: $updatedStr',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: AppColors.textMuted,
                ),
              ),
            ],
            const SizedBox(height: 8),
            catatan.isEmpty
                ? Text(
                    'Belum ada catatan dari ahli gizi.',
                    style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        height: 1.5),
                  )
                : Text(
                    catatan,
                    style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5),
                  ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildReportStat('Asupan Serat',
                      '${_fmt(_seratAktual)}g / ${_fmt(_seratTarget)}g'),
                ),
                Expanded(
                  child: _buildReportStat('Hidrasi',
                      '${_fmt(_hidrasiAktual)}L / ${_fmt(_hidrasiTarget)}L'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.manrope(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value,
              style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildBottomStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
              child: _buildStatChip(Icons.biotech_outlined,
                  '${_fmt(_proteinAktual)}g', 'PROTEIN AKTUAL')),
          const SizedBox(width: 12),
          Expanded(
              child: _buildStatChip(Icons.water_drop_outlined,
                  '${_fmt(_lemakAktual)}g', 'LEMAK AKTUAL')),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
