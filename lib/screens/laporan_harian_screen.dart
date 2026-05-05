import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class LaporanHarianScreen extends StatefulWidget {
  final String rmPasien;
  final String namaPasien;
  final String dietType;

  const LaporanHarianScreen({
    super.key,
    required this.rmPasien,
    required this.namaPasien,
    required this.dietType,
  });

  @override
  State<LaporanHarianScreen> createState() => _LaporanHarianScreenState();
}

class _LaporanHarianScreenState extends State<LaporanHarianScreen> {
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _nutritionData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    
    // Try to get from history first
    var data = await AuthService.getNutrisiHistoryForDate(
        widget.rmPasien, widget.dietType, dateKey);
    
    // If no history and selected date is today, get current latest plan
    if (data == null && dateKey == DateFormat('yyyy-MM-dd').format(DateTime.now())) {
      data = await AuthService.getNutrisiPasienPerDiet(widget.rmPasien, widget.dietType);
    }

    if (mounted) {
      setState(() {
        _nutritionData = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData();
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
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Laporan Capaian Gizi',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur download sedang disiapkan...')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _nutritionData == null
                    ? _buildEmptyState()
                    : _buildReportContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih Tanggal Laporan',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate),
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_late_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Tidak ada data untuk tanggal ini',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    final targets = _nutritionData!['target_nutrients'] as Map<String, dynamic>? ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 20),
          _buildChartSection(targets),
          const SizedBox(height: 20),
          _buildSummaryTable(targets),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person_outline, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.namaPasien,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Program: ${widget.dietType}',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
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

  Widget _buildChartSection(Map<String, dynamic> data) {
    // Nutrient keys to display
    final keys = [
      'Energi (kkal)',
      'Protein (g)',
      'Lemak (g)',
      'Karbohidrat (g)',
      'Air (ml)',
      'Natrium (mg)',
      'Kalium (mg)'
    ];

    final barGroups = <BarChartGroupData>[];
    double maxVal = 0;

    for (int i = 0; i < keys.length; i++) {
      final nutrient = keys[i];
      final target = (data[nutrient]?['target'] as num?)?.toDouble() ?? 0.0;
      final aktual = (data[nutrient]?['aktual'] as num?)?.toDouble() ?? 0.0;

      if (target > maxVal) maxVal = target;
      if (aktual > maxVal) maxVal = aktual;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: target,
              color: const Color(0xFF0284C7), // Blue for Target
              width: 12,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: aktual,
              color: const Color(0xFFF97316), // Orange for Aktual
              width: 12,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Visualisasi Target vs Aktual',
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                _buildLegendItem('Target', const Color(0xFF0284C7)),
                const SizedBox(width: 12),
                _buildLegendItem('Aktual', const Color(0xFFF97316)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          height: 300,
          padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.textPrimary,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${keys[groupIndex]}\n',
                      GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      children: [
                        TextSpan(
                          text: '${rod.toY.toStringAsFixed(1)}',
                          style: GoogleFonts.manrope(color: rod.color, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= keys.length) return const SizedBox();
                      final label = keys[idx].split(' ')[0];
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: Text(
                            label,
                            style: GoogleFonts.manrope(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox();
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                      );
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
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildSummaryTable(Map<String, dynamic> data) {
    final keys = [
      'Energi (kkal)',
      'Protein (g)',
      'Lemak (g)',
      'Karbohidrat (g)',
      'Air (ml)',
      'Natrium (mg)',
      'Kalium (mg)'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detail Capaian Gizi',
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              _buildTableHeader(),
              ...keys.map((k) => _buildTableRow(k, data[k])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Komponen', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary))),
          Expanded(flex: 2, child: Text('Target', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('Aktual', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary), textAlign: TextAlign.center)),
          Expanded(flex: 1, child: Text('%', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary), textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildTableRow(String label, dynamic values) {
    final target = (values?['target'] as num?)?.toDouble() ?? 0.0;
    final aktual = (values?['aktual'] as num?)?.toDouble() ?? 0.0;
    final pct = target > 0 ? (aktual / target * 100).toInt() : 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  label,
                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  target.toStringAsFixed(target % 1 == 0 ? 0 : 1),
                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  aktual.toStringAsFixed(aktual % 1 == 0 ? 0 : 1),
                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '$pct%',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: pct >= 100 ? Colors.green : (pct >= 80 ? AppColors.primary : Colors.orange),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        if (label != 'Kalium (mg)') const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}
