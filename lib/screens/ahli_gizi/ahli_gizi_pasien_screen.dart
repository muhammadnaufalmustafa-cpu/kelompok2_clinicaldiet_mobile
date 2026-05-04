import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../utils/age_calculator.dart';
import 'ahli_gizi_detail_pasien_screen.dart';

class AhliGiziPasienScreen extends StatefulWidget {
  const AhliGiziPasienScreen({super.key});

  @override
  State<AhliGiziPasienScreen> createState() => _AhliGiziPasienScreenState();
}

class _AhliGiziPasienScreenState extends State<AhliGiziPasienScreen> {
  List<Map<String, dynamic>> _allPasien = [];
  List<Map<String, dynamic>> _filtered = [];
  final _searchCtrl = TextEditingController();
  String _filterStatus = 'Semua';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
        _allPasien = myPasien;
        _applyFilter();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _allPasien.where((p) {
        final matchSearch = (p['name'] as String? ?? '')
                .toLowerCase()
                .contains(query) ||
            (p['rm'] as String? ?? '').toLowerCase().contains(query);
        final status = p['status'] ?? 'aktif';
        final matchStatus =
            _filterStatus == 'Semua' || status == _filterStatus.toLowerCase();
        return matchSearch && matchStatus;
      }).toList();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
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
        title: Text('Daftar Pasien',
            style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0284C7)))
          : Column(
              children: [
                // Search + filter
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Cari nama atau RM...',
                          hintStyle: GoogleFonts.manrope(
                              color: AppColors.textMuted, fontSize: 14),
                          prefixIcon: const Icon(Icons.search,
                              color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: ['Semua', 'Aktif', 'Berhasil', 'Meninggal']
                            .map((s) => GestureDetector(
                                  onTap: () {
                                    setState(() => _filterStatus = s);
                                    _applyFilter();
                                  },
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _filterStatus == s
                                          ? const Color(0xFF0284C7)
                                          : AppColors.background,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(s,
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _filterStatus == s
                                              ? Colors.white
                                              : AppColors.textSecondary,
                                        )),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                // List
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline,
                                  size: 64, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              Text('Tidak ada pasien ditemukan.',
                                  style: GoogleFonts.manrope(
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: const Color(0xFF0284C7),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            itemBuilder: (ctx, i) {
                              final pasien = _filtered[i];
                              final status = pasien['status'] ?? 'aktif';
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AhliGiziDetailPasienScreen(
                                              pasien: pasien),
                                    ),
                                  ).then((_) => _loadData());
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: _statusColor(status)
                                              .withValues(alpha: 0.12),
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
                                                color:
                                                    _statusColor(status)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(pasien['name'] ?? '-',
                                                style: GoogleFonts.manrope(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: AppColors
                                                        .textPrimary)),
                                            Text(
                                                'RM: ${pasien['rm'] ?? '-'} • Diet: ${pasien['diet_type'] != null && pasien['diet_type'] != '' ? pasien['diet_type'] : 'Belum Dipilih'}',
                                                style: GoogleFonts.manrope(
                                                    fontSize: 12,
                                                    color: AppColors
                                                        .textSecondary)),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppColors.background,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('Umur: ${AgeCalculator.formatAge(AgeCalculator.calculateAge(pasien['birthdate']))}', style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                                                  const SizedBox(height: 2),
                                                  Text('BB: ${pasien['weight'] ?? '-'} kg | TB: ${pasien['height'] ?? '-'} cm', style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textSecondary)),
                                                  const SizedBox(height: 2),
                                                  Text('Jenis Kelamin: ${pasien['gender'] ?? '-'}', style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textSecondary)),
                                                  if (AgeCalculator.calculateIMT(pasien['weight'], pasien['height']) != null) ...[
                                                    const SizedBox(height: 2),
                                                    Text('IMT: ${AgeCalculator.calculateIMT(pasien['weight'], pasien['height'])}', style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textSecondary)),
                                                  ],
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _statusColor(status)
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: GoogleFonts.manrope(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: _statusColor(status)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
