import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import 'ahli_gizi_detail_pasien_screen.dart';

class AhliGiziDashboardScreen extends StatefulWidget {
  const AhliGiziDashboardScreen({super.key});

  @override
  State<AhliGiziDashboardScreen> createState() =>
      _AhliGiziDashboardScreenState();
}

class _AhliGiziDashboardScreenState extends State<AhliGiziDashboardScreen> {
  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _allPasien = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await AuthService.getLoggedInUser();
    final allPasien = await AuthService.getAllPasien();
    
    // FILTER: Hanya ambil pasien yang memilih Ahli Gizi ini
    final myPasien = allPasien.where((p) => 
      p['role'] == 'pasien' && 
      p['selected_ahli_gizi_nip'] == user?['nip']
    ).toList();

    if (mounted) {
      setState(() {
        _user = user;
        _allPasien = myPasien;
        _isLoading = false;
      });
    }
  }

  int get _aktifCount =>
      _allPasien.where((p) => (p['status'] ?? 'aktif') == 'aktif').length;
  int get _berhasilCount =>
      _allPasien.where((p) => p['status'] == 'berhasil').length;
  int get _meninggalCount =>
      _allPasien.where((p) => p['status'] == 'meninggal').length;
  int get _dropoutCount =>
      _allPasien.where((p) => p['status'] == 'dropout').length;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: Color(0xFF0284C7))),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: const Color(0xFF0284C7),
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // AppBar
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.white,
              elevation: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Clinical Diet',
                      style: GoogleFonts.manrope(
                          fontSize: 13, color: AppColors.textSecondary)),
                  Text(_user?['name'] ?? 'Ahli Gizi',
                      style: GoogleFonts.manrope(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ],
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Banner
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat Datang, ${_user?['name'] ?? 'Ahli Gizi'}! 👋',
                            style: GoogleFonts.manrope(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pantau dan kelola program diet pasien Anda hari ini. Pastikan untuk mengevaluasi target gizi mereka secara berkala untuk mencapai hasil yang maksimal.',
                            style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.9),
                                height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stats cards
                    Text('Ringkasan Pasien',
                        style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _buildStatCard(
                                'Aktif', _aktifCount,
                                AppColors.primary, Icons.person_outlined)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _buildStatCard(
                                'Berhasil', _berhasilCount,
                                const Color(0xFF0284C7),
                                Icons.check_circle_outline)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                            child: _buildStatCard(
                                'Meninggal', _meninggalCount,
                                const Color(0xFF6B7280),
                                Icons.info_outline)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _buildStatCard(
                                'Gagal/Drop', _dropoutCount,
                                const Color(0xFFDC2626),
                                Icons.cancel_outlined)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Chart overview
                    Text('Grafik Status Pasien',
                        style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (_allPasien.length.toDouble() + 2),
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
                                    fontSize: 12,
                                  );
                                  String text;
                                  switch (value.toInt()) {
                                    case 0:
                                      text = 'Aktif';
                                      break;
                                    case 1:
                                      text = 'Berhasil';
                                      break;
                                    case 2:
                                      text = 'Meninggal';
                                      break;
                                    case 3:
                                      text = 'Gagal';
                                      break;
                                    default:
                                      text = '';
                                      break;
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(text, style: style),
                                  );
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                          barGroups: [
                            BarChartGroupData(x: 0, barRods: [
                              BarChartRodData(toY: _aktifCount.toDouble(), color: AppColors.primary, width: 22, borderRadius: BorderRadius.circular(4)),
                            ]),
                            BarChartGroupData(x: 1, barRods: [
                              BarChartRodData(toY: _berhasilCount.toDouble(), color: const Color(0xFF0284C7), width: 22, borderRadius: BorderRadius.circular(4)),
                            ]),
                            BarChartGroupData(x: 2, barRods: [
                              BarChartRodData(toY: _meninggalCount.toDouble(), color: const Color(0xFF6B7280), width: 22, borderRadius: BorderRadius.circular(4)),
                            ]),
                            BarChartGroupData(x: 3, barRods: [
                              BarChartRodData(toY: _dropoutCount.toDouble(), color: const Color(0xFFDC2626), width: 22, borderRadius: BorderRadius.circular(4)),
                            ]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Pasien list
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Daftar Pasien Aktif',
                            style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        Text('$_aktifCount pasien',
                            style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_allPasien.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.people_outline,
                                  size: 48, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              Text('Belum ada pasien terdaftar.',
                                  style: GoogleFonts.manrope(
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._allPasien
                          .where((p) => (p['status'] ?? 'aktif') == 'aktif')
                          .map((pasien) => _buildPasienCard(pasien)),
                          
                    const SizedBox(height: 24),
                    _buildUlasanSection(),

                    const SizedBox(height: 80), // spacing
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text('$count',
              style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: color)),
          Text(label,
              style: GoogleFonts.manrope(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildPasienCard(Map<String, dynamic> pasien) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AhliGiziDetailPasienScreen(pasien: pasien),
          ),
        ).then((_) => _loadData());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  (pasien['name'] as String? ?? 'P')
                      .substring(0, 1)
                      .toUpperCase(),
                  style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pasien['name'] ?? '-',
                      style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text('RM: ${pasien['rm'] ?? '-'} • Diet: ${pasien['diet_type'] != null && pasien['diet_type'] != '' ? pasien['diet_type'] : 'Belum Dipilih'}',
                      style: GoogleFonts.manrope(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUlasanSection() {
    List reviews = _user?['reviews'] ?? [];
    if (reviews.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ulasan Terbaru dari Pasien',
            style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        ...reviews.take(3).map((r) {
          final rating = (r['rating'] as num?)?.toDouble() ?? 5.0;
          final dtStr = r['tanggal'] as String? ?? '';
          String dtShow = '';
          if (dtStr.isNotEmpty) {
            try {
              final d = DateTime.parse(dtStr);
              dtShow = '${d.day}/${d.month}/${d.year}';
            } catch (_) {}
          }
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r['pasienName'] ?? 'Pasien', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 13)),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFF59E0B), size: 14),
                        const SizedBox(width: 4),
                        Text(rating.toStringAsFixed(1), style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                if (dtShow.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(dtShow, style: GoogleFonts.manrope(fontSize: 10, color: AppColors.textMuted)),
                ],
                if ((r['ulasan'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text('"${r['ulasan']}"', style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                ]
              ],
            ),
          );
        }),
      ],
    );
  }
}
