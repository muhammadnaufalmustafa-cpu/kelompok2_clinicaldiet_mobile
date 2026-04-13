import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final pasien = await AuthService.getAllPasien();
    if (mounted) {
      setState(() {
        _user = user;
        _allPasien = pasien;
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
                  Text('Selamat Datang 👋',
                      style: GoogleFonts.manrope(
                          fontSize: 13, color: AppColors.textSecondary)),
                  Text(_user?['name'] ?? 'Ahli Gizi',
                      style: GoogleFonts.manrope(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ],
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _user?['specialization'] ?? 'Ahli Gizi',
                    style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0284C7)),
                  ),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        const SizedBox(width: 10),
                        Expanded(
                            child: _buildStatCard(
                                'Berhasil', _berhasilCount,
                                const Color(0xFF0284C7),
                                Icons.check_circle_outline)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _buildStatCard(
                                'Meninggal', _meninggalCount,
                                const Color(0xFF6B7280),
                                Icons.info_outline)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Pasien aktif list
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Pasien Aktif',
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
                  Text('RM: ${pasien['rm'] ?? '-'} • ${pasien['diet_type'] ?? 'Normal'}',
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
}
