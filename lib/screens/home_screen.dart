import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(context),
                _buildCalorieRing(),
                _buildNutritionSummary(),
                _buildReminderCard(),
                _buildDailyReport(),
                _buildBottomStats(),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // FAB
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton(
              onPressed: () {},
              backgroundColor: AppColors.primary,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
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
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.monitor_heart_outlined,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                'ClinicalDiet',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'PASIEN',
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.notifications_outlined,
                  color: AppColors.textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieRing() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: CircularPercentIndicator(
          radius: 90,
          lineWidth: 12,
          percent: 0.78,
          backgroundColor: AppColors.divider,
          progressColor: AppColors.primary,
          circularStrokeCap: CircularStrokeCap.round,
          center: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'HARI INI',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '1.840',
                style: GoogleFonts.poppins(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
              Text(
                'Kkal dikonsumsi',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textSecondary,
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
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildNutrientRow('PROTEIN', 1.0, AppColors.protein, '110% dari target'),
          const SizedBox(height: 10),
          _buildNutrientRow('LEMAK SEHAT', 0.72, AppColors.fat, '72% dari target'),
          const SizedBox(height: 10),
          _buildNutrientRow('KARBOHIDRAT', 0.92, AppColors.carb, '92% dari target'),
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
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              caption,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
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

  Widget _buildReminderCard() {
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
                'Anda belum mencatat camilan sore hari ini!',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                'Catat',
                style: GoogleFonts.poppins(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyReport() {
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
                const Icon(Icons.assignment_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Laporan Harian',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'ANALISIS KLINIS',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Asupan protein Anda sedikit di atas target, sangat baik untuk pemulihan otot. Namun, pertimbangkan menambah lemak sehat seperti alpukat pada makan malam untuk mencapai keseimbangan lipid.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildReportStat('Asupan Serat', '24g / 30g'),
                ),
                Expanded(
                  child: _buildReportStat('Hidrasi', '1,8L / 2,5L'),
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
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
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
          Expanded(child: _buildStatChip(Icons.biotech_outlined, '82g', 'PROTEIN NETTO')),
          const SizedBox(width: 12),
          Expanded(child: _buildStatChip(Icons.water_drop_outlined, '12g', 'LEMAK JENUH')),
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
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
