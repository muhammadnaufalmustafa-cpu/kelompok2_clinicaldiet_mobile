import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';

class LaporanPasienScreen extends StatefulWidget {
  final Map<String, dynamic> pasien;
  const LaporanPasienScreen({super.key, required this.pasien});

  @override
  State<LaporanPasienScreen> createState() => _LaporanPasienScreenState();
}

class _LaporanPasienScreenState extends State<LaporanPasienScreen> {
  bool _isLoading = true;
  bool _isExporting = false;
  List<Map<String, dynamic>> _mealLogs = [];
  List<Map<String, dynamic>> _nutrisiPerDiet = [];

  // Filter bulan
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<String> _bulanNames = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final rm = widget.pasien['rm'] as String;
    final logs = await AuthService.getMealLogsForPasien(rm, days: 90);
    final nutrisi = await AuthService.getAllNutrisiPasien(rm);
    if (mounted) {
      setState(() {
        _mealLogs = logs;
        _nutrisiPerDiet = nutrisi;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredLogs {
    return _mealLogs.where((log) {
      final date = DateTime.tryParse(log['date'] ?? '');
      if (date == null) return false;
      return date.month == _selectedMonth && date.year == _selectedYear;
    }).toList()
      ..sort((a, b) {
        final dA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(2000);
        final dB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(2000);
        return dA.compareTo(dB);
      });
  }

  String _buildReportText() {
    final p = widget.pasien;
    final logs = _filteredLogs;
    final buf = StringBuffer();

    buf.writeln('==============================');
    buf.writeln('   LAPORAN PERKEMBANGAN GIZI  ');
    buf.writeln('   ${_bulanNames[_selectedMonth]} $_selectedYear  ');
    buf.writeln('==============================');
    buf.writeln();

    // Info pasien
    buf.writeln('INFORMASI PASIEN');
    buf.writeln('----------------------------');
    buf.writeln('Nama       : ${p['name'] ?? '-'}');
    buf.writeln('No. RM     : ${p['rm'] ?? '-'}');
    buf.writeln('Usia/TTL   : ${p['birthdate'] ?? '-'}');
    buf.writeln('Jenis Kel. : ${p['gender'] ?? '-'}');
    buf.writeln('Diagnosis  : ${p['diagnosis'] ?? '-'}');
    buf.writeln('Status Gizi: ${p['status_gizi'] ?? '-'}');

    final diets = () {
      final raw = p['diet_types'];
      if (raw is List && raw.isNotEmpty) return raw.cast<String>().join(', ');
      return p['diet_type'] as String? ?? '-';
    }();
    buf.writeln('Terapi Diet: $diets');
    buf.writeln();

    // Target gizi
    if (_nutrisiPerDiet.isNotEmpty) {
      buf.writeln('TARGET GIZI HARIAN');
      buf.writeln('----------------------------');
      for (final n in _nutrisiPerDiet) {
        final dt = n['diet_type'] ?? '-';
        buf.writeln('[$dt]');
        final targetNutrients = n['target_nutrients'] as Map<String, dynamic>?;
        if (targetNutrients != null && targetNutrients.isNotEmpty) {
          targetNutrients.forEach((key, val) {
            final target = (val['target'] as num?)?.toStringAsFixed(1) ?? '0';
            final aktual = (val['aktual'] as num?)?.toStringAsFixed(1) ?? '0';
            buf.writeln('  $key: Target $target | Capaian $aktual');
          });
        } else {
          buf.writeln('  (Belum ada target nutrisi)');
        }
        buf.writeln();
      }
    }

    // Catatan klinis
    if ((p['catatan_klinis'] as String? ?? '').isNotEmpty) {
      buf.writeln('CATATAN KLINIS');
      buf.writeln('----------------------------');
      buf.writeln(p['catatan_klinis']);
      buf.writeln();
    }

    if ((p['target_diet'] as String? ?? '').isNotEmpty) {
      buf.writeln('TARGET DIET PASIEN');
      buf.writeln('----------------------------');
      buf.writeln(p['target_diet']);
      buf.writeln();
    }

    // Rekap catatan makan
    buf.writeln('REKAP CATATAN MAKAN (${logs.length} hari)');
    buf.writeln('----------------------------');
    if (logs.isEmpty) {
      buf.writeln('(Tidak ada data catatan makan pada bulan ini)');
    } else {
      for (final log in logs) {
        final date = DateTime.tryParse(log['date'] ?? '');
        final dateStr = date != null
            ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
            : '-';
        final bb = (log['berat_badan'] as num?)?.toStringAsFixed(1) ?? '-';
        final tb = (log['tinggi_badan'] as num?)?.toStringAsFixed(0) ?? '-';

        buf.writeln('Tanggal: $dateStr  |  BB: ${bb}kg  TB: ${tb}cm');
        if ((log['meal_pagi'] as String? ?? '').isNotEmpty)
          buf.writeln('  Pagi    : ${log['meal_pagi']}');
        if ((log['selingan_pagi'] as String? ?? '').isNotEmpty)
          buf.writeln('  Sel.Pagi: ${log['selingan_pagi']}');
        if ((log['meal_siang'] as String? ?? '').isNotEmpty)
          buf.writeln('  Siang   : ${log['meal_siang']}');
        if ((log['selingan_sore'] as String? ?? '').isNotEmpty)
          buf.writeln('  Sel.Sore: ${log['selingan_sore']}');
        if ((log['meal_malam'] as String? ?? '').isNotEmpty)
          buf.writeln('  Malam   : ${log['meal_malam']}');
        buf.writeln();
      }
    }

    buf.writeln('==============================');
    buf.writeln('Laporan dibuat otomatis oleh');
    buf.writeln('Sistem Gizi Klinik');
    buf.writeln('==============================');

    return buf.toString();
  }

  Future<void> _exportLaporan() async {
    setState(() => _isExporting = true);
    try {
      final text = _buildReportText();
      if (kIsWeb) {
        // On web, just show share dialog with text
        await Share.share(text, subject: 'Laporan Gizi ${widget.pasien['name']} - ${_bulanNames[_selectedMonth]} $_selectedYear');
      } else {
        final dir = await getTemporaryDirectory();
        final fileName = 'laporan_${widget.pasien['rm']}_${_selectedMonth}_$_selectedYear.txt';
        final file = File('${dir.path}/$fileName');
        await file.writeAsString(text, flush: true);
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Laporan Gizi ${widget.pasien['name']} - ${_bulanNames[_selectedMonth]} $_selectedYear',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal mengekspor: $e', style: GoogleFonts.manrope()),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
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
        title: Text('Laporan Perkembangan Pasien',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 15)),
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : const Icon(Icons.share_outlined, color: AppColors.primary),
            onPressed: _isExporting ? null : _exportLaporan,
            tooltip: 'Ekspor & Bagikan Laporan',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                _buildFilterBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderCard(),
                        const SizedBox(height: 16),
                        _buildNutrisiSummaryCard(),
                        const SizedBox(height: 16),
                        _buildCatatanMakanCard(),
                        const SizedBox(height: 16),
                        _buildExportButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterBar() {
    final now = DateTime.now();
    final months = List.generate(12, (i) => i + 1).reversed.toList();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedMonth,
                isExpanded: true,
                items: months.map((m) => DropdownMenuItem(
                  value: m,
                  child: Text(_bulanNames[m], style: GoogleFonts.manrope(fontSize: 14)),
                )).toList(),
                onChanged: (v) => setState(() => _selectedMonth = v!),
              ),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedYear,
              items: [now.year - 1, now.year, now.year + 1].map((y) => DropdownMenuItem(
                value: y,
                child: Text('$y', style: GoogleFonts.manrope(fontSize: 14)),
              )).toList(),
              onChanged: (v) => setState(() => _selectedYear = v!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    final p = widget.pasien;
    final diets = () {
      final raw = p['diet_types'];
      if (raw is List && raw.isNotEmpty) return raw.cast<String>().join('\n');
      return p['diet_type'] as String? ?? '-';
    }();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: Text(
                  (p['name'] as String? ?? 'P').substring(0, 1).toUpperCase(),
                  style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['name'] ?? '-', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    Text('No. RM: ${p['rm'] ?? '-'}', style: GoogleFonts.manrope(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(8)),
                child: Text('${_bulanNames[_selectedMonth]} $_selectedYear',
                    style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          _buildInfoRowWhite('Diagnosis', p['diagnosis'] ?? '-'),
          _buildInfoRowWhite('Status Gizi', p['status_gizi'] ?? '-'),
          _buildInfoRowWhite('Terapi Diet', diets),
          if ((p['target_diet'] as String? ?? '').isNotEmpty)
            _buildInfoRowWhite('Target Diet', p['target_diet']),
        ],
      ),
    );
  }

  Widget _buildInfoRowWhite(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text('$label:', style: GoogleFonts.manrope(fontSize: 12, color: Colors.white70))),
          Expanded(child: Text(value, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildNutrisiSummaryCard() {
    if (_nutrisiPerDiet.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.analytics_outlined, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text('Target & Capaian Gizi', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 12),
          ..._nutrisiPerDiet.map((n) {
            final dietName = n['diet_type'] as String? ?? '-';
            final targetNutrients = n['target_nutrients'] as Map<String, dynamic>? ?? {};
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                  child: Text(dietName, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                ),
                if (targetNutrients.isEmpty)
                  Text('(Belum ada target nutrisi)', style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textMuted))
                else
                  ...targetNutrients.entries.map((e) {
                    final target = (e.value['target'] as num?)?.toDouble() ?? 0;
                    final aktual = (e.value['aktual'] as num?)?.toDouble() ?? 0;
                    final pct = target > 0 ? (aktual / target).clamp(0.0, 1.0) : 0.0;
                    final isOk = pct >= 0.8 && pct <= 1.2;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Expanded(flex: 3, child: Text(e.key, style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textSecondary))),
                        Expanded(flex: 2, child: Text(
                          '${aktual.toStringAsFixed(1)} / ${target.toStringAsFixed(1)}',
                          style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        )),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOk ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${(pct * 100).toInt()}%',
                              style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700,
                                  color: isOk ? const Color(0xFF065F46) : const Color(0xFF991B1B))),
                        ),
                      ]),
                    );
                  }).toList(),
                const SizedBox(height: 8),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCatatanMakanCard() {
    final logs = _filteredLogs;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.restaurant_outlined, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text('Rekap Catatan Makan', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
              child: Text('${logs.length} hari', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
            ),
          ]),
          const SizedBox(height: 12),
          if (logs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
                    const SizedBox(height: 8),
                    Text('Tidak ada catatan makan\npada bulan ini.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textMuted)),
                  ],
                ),
              ),
            )
          else
            ...logs.map((log) {
              final date = DateTime.tryParse(log['date'] ?? '');
              final dateStr = date != null
                  ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                  : '-';
              final bb = (log['berat_badan'] as num?)?.toStringAsFixed(1);
              final tb = (log['tinggi_badan'] as num?)?.toStringAsFixed(0);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(dateStr, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      const Spacer(),
                      if (bb != null && tb != null)
                        Text('BB: ${bb}kg · TB: ${tb}cm',
                            style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textSecondary)),
                    ]),
                    const SizedBox(height: 6),
                    ...[
                      ('Pagi', log['meal_pagi']),
                      ('Selingan Pagi', log['selingan_pagi']),
                      ('Siang', log['meal_siang']),
                      ('Selingan Sore', log['selingan_sore']),
                      ('Malam', log['meal_malam']),
                    ].where((e) => (e.$2 as String? ?? '').isNotEmpty).map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textPrimary),
                          children: [
                            TextSpan(text: '${e.$1}: ', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                            TextSpan(text: e.$2 as String),
                          ],
                        ),
                      ),
                    )).toList(),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isExporting ? null : _exportLaporan,
        icon: _isExporting
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.share_outlined, size: 20),
        label: Text(
          _isExporting ? 'Menyiapkan laporan...' : 'Ekspor & Bagikan Laporan',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }
}
