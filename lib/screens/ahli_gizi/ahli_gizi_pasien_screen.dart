import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../utils/age_calculator.dart';
import 'ahli_gizi_detail_pasien_screen.dart';
import '../../services/export_service.dart';

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
  bool _isExporting = false;
  Map<String, dynamic>? _ahliGizi;

  // Filter untuk Laporan
  int _laporanMonth = DateTime.now().month;
  int _laporanYear = DateTime.now().year;

  final List<String> _bulanNames = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

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
    final myPasien = await AuthService.getPasienByAhliGiziNip(user?['nip'] ?? '');

    if (mounted) {
      setState(() {
        _ahliGizi = user;
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

  Future<void> _exportToExcel() async {
    if (_ahliGizi == null) return;

    // Gunakan SEMUA pasien (tanpa filter status/search) untuk laporan bulanan rekap
    final pasienUntukLaporan = _allPasien;

    if (pasienUntukLaporan.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Tidak ada data pasien untuk diekspor.', style: GoogleFonts.manrope()),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final bulanStr = _bulanNames[_laporanMonth];
    final monthYearStr = '${bulanStr}_$_laporanYear';

    setState(() => _isExporting = true);

    final errorMessage = await ExportService.exportPasienToExcel(
      pasienList: pasienUntukLaporan,
      ahliGizi: _ahliGizi!,
      monthYearStr: monthYearStr,
    );

    setState(() => _isExporting = false);

    if (mounted) {
      if (errorMessage == null) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(child: Text('Berhasil Diunduh', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 18))),
              ],
            ),
            content: Text(
              'File laporan bulanan (Excel) berhasil disiapkan dan siap dibagikan/disimpan.',
              style: GoogleFonts.manrope(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Tutup', style: GoogleFonts.manrope(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal membuat file Excel: $errorMessage', style: GoogleFonts.manrope()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'berhasil':
        return AppColors.secondary;
      case 'meninggal':
        return AppColors.textSecondary;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(12, (i) => i + 1).reversed.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Daftar Pasien',
            style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        actions: const [],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary))
          : Column(
              children: [
                // ─────────── Panel Rekap Laporan Bulanan ───────────
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.secondary, AppColors.secondary.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.summarize_outlined,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Rekap Laporan Bulanan',
                                    style: GoogleFonts.manrope(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                                Text(
                                  'Total ${_allPasien.length} pasien akan diekspor ke Excel',
                                  style: GoogleFonts.manrope(
                                      fontSize: 12, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Filter Bulan & Tahun
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined,
                                color: Colors.white70, size: 18),
                            const SizedBox(width: 8),
                            Text('Periode:',
                                style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(width: 8),
                            // Dropdown Bulan
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _laporanMonth,
                                  dropdownColor: AppColors.secondary,
                                  iconEnabledColor: Colors.white,
                                  style: GoogleFonts.manrope(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white),
                                  items: months
                                      .map((m) => DropdownMenuItem(
                                            value: m,
                                            child: Text(_bulanNames[m]),
                                          ))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _laporanMonth = v!),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Dropdown Tahun
                            DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _laporanYear,
                                dropdownColor: AppColors.secondary,
                                iconEnabledColor: Colors.white,
                                style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                                items: [now.year - 1, now.year, now.year + 1]
                                    .map((y) => DropdownMenuItem(
                                          value: y,
                                          child: Text('$y'),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _laporanYear = v!),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Tombol Export
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isExporting ? null : _exportToExcel,
                          icon: _isExporting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppColors.secondary))
                              : const Icon(Icons.file_download_outlined,
                                  size: 20, color: AppColors.secondary),
                          label: Text(
                            _isExporting
                                ? 'Membuat file Excel...'
                                : 'Cetak Laporan Rekap (.xlsx)',
                            style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary,
                                fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ─────────── Search + Filter Status ───────────
                Container(
                  color: Colors.white,
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _filterStatus == s
                                          ? AppColors.secondary
                                          : AppColors.background,
                                      borderRadius: BorderRadius.circular(20),
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

                // ─────────── Daftar Pasien ───────────
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
                          color: AppColors.secondary,
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
                                    borderRadius: BorderRadius.circular(14),
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
                                                color: _statusColor(status)),
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
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppColors.textPrimary)),
                                            Text(
                                                'RM: ${pasien['rm'] ?? '-'} • Diet: ${pasien['dynamic_active_diets'] ?? (pasien['diet_type'] != null && pasien['diet_type'] != '' ? pasien['diet_type'] : 'Belum Dipilih')}',
                                                style: GoogleFonts.manrope(
                                                    fontSize: 12,
                                                    color: AppColors
                                                        .textSecondary)),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppColors.background,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                      'Umur: ${AgeCalculator.formatAge(AgeCalculator.calculateAge(pasien['birthdate']))}',
                                                      style: GoogleFonts.manrope(
                                                          fontSize: 11,
                                                          color: AppColors
                                                              .textPrimary,
                                                          fontWeight:
                                                              FontWeight.w600)),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                      'BB: ${pasien['weight'] ?? '-'} kg | TB: ${pasien['height'] ?? '-'} cm',
                                                      style: GoogleFonts.manrope(
                                                          fontSize: 11,
                                                          color: AppColors
                                                              .textSecondary)),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                      'Jenis Kelamin: ${pasien['gender'] ?? '-'}',
                                                      style: GoogleFonts.manrope(
                                                          fontSize: 11,
                                                          color: AppColors
                                                              .textSecondary)),
                                                  if (AgeCalculator.calculateIMT(
                                                          pasien['weight'],
                                                          pasien['height']) !=
                                                      null) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                        'IMT: ${AgeCalculator.calculateIMT(pasien['weight'], pasien['height'])}',
                                                        style: GoogleFonts.manrope(
                                                            fontSize: 11,
                                                            color: AppColors
                                                                .textSecondary)),
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
