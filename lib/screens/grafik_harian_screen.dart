import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class GrafikHarianScreen extends StatefulWidget {
  final String rmPasien;
  final String namaPasien;

  const GrafikHarianScreen({
    super.key,
    required this.rmPasien,
    required this.namaPasien,
  });

  @override
  State<GrafikHarianScreen> createState() => _GrafikHarianScreenState();
}

class _GrafikHarianScreenState extends State<GrafikHarianScreen> {
  List<Map<String, dynamic>> _mealLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final logs = await AuthService.getMealLogsForPasien(widget.rmPasien, days: 30);
    // Sort ascending by date for charts
    logs.sort((a, b) => DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));
    
    if (mounted) {
      setState(() {
        _mealLogs = logs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Grafik Perkembangan', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 16)),
            Text(widget.namaPasien, style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Tren Berat Badan (30 Hari)'),
            const SizedBox(height: 12),
            _buildLineChartBB(),
            const SizedBox(height: 32),
            _buildSectionTitle('Tingkat Kepatuhan Pengisian (30 Hari)'),
            const SizedBox(height: 12),
            _buildBarChartKepatuhan(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildLineChartBB() {
    // Filter logs that have valid berat_badan
    final validLogs = _mealLogs.where((log) => log['berat_badan'] != null).toList();
    if (validLogs.isEmpty) {
      return _buildEmptyState('Belum ada data berat badan yang dicatat.');
    }

    final spots = <FlSpot>[];
    double minBB = double.infinity;
    double maxBB = 0;

    for (int i = 0; i < validLogs.length; i++) {
      final bb = (validLogs[i]['berat_badan'] as num).toDouble();
      if (bb < minBB) minBB = bb;
      if (bb > maxBB) maxBB = bb;
      spots.add(FlSpot(i.toDouble(), bb));
    }

    if (minBB == double.infinity) minBB = 0;
    
    return Container(
      height: 250,
      padding: const EdgeInsets.only(right: 20, left: 10, top: 20, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= validLogs.length) return const SizedBox();
                  final date = DateTime.parse(validLogs[idx]['date']);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('${date.day}/${date.month}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}kg', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary));
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (validLogs.length - 1).toDouble(),
          minY: minBB > 10 ? minBB - 5 : 0,
          maxY: maxBB + 5,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primaryLight.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartKepatuhan() {
    if (_mealLogs.isEmpty) {
      return _buildEmptyState('Belum ada riwayat catatan makanan.');
    }

    final barGroups = <BarChartGroupData>[];
    
    for (int i = 0; i < _mealLogs.length; i++) {
      final log = _mealLogs[i];
      int filled = 0;
      if ((log['meal_pagi'] as String?)?.isNotEmpty == true) filled++;
      if ((log['selingan_pagi'] as String?)?.isNotEmpty == true) filled++;
      if ((log['meal_siang'] as String?)?.isNotEmpty == true) filled++;
      if ((log['selingan_sore'] as String?)?.isNotEmpty == true) filled++;
      if ((log['meal_malam'] as String?)?.isNotEmpty == true) filled++;
      
      final pct = (filled / 5) * 100;
      Color barColor = AppColors.primary;
      if (pct < 50) barColor = AppColors.red;
      else if (pct < 100) barColor = Colors.orange;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: pct,
              color: barColor,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            )
          ],
        )
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.only(right: 20, left: 10, top: 20, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= _mealLogs.length) return const SizedBox();
                  final date = DateTime.parse(_mealLogs[idx]['date']);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('${date.day}/${date.month}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}%', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary));
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          barGroups: barGroups,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        msg,
        style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      ),
    );
  }
}
