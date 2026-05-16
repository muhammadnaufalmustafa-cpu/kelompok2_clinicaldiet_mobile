import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';

/// Laporan Harian untuk Ahli Gizi — berisi rekap catatan makan & data gizi pasien
/// per bulan (isi sama dengan Laporan Bulanan lama).
class LaporanHarianAGScreen extends StatefulWidget {
  final Map<String, dynamic> pasien;
  const LaporanHarianAGScreen({super.key, required this.pasien});

  @override
  State<LaporanHarianAGScreen> createState() => _LaporanHarianAGScreenState();
}

class _LaporanHarianAGScreenState extends State<LaporanHarianAGScreen> {
  bool _isLoading = true;
  bool _isExporting = false;
  List<Map<String, dynamic>> _mealLogs = [];
  List<Map<String, dynamic>> _nutrisiPerDiet = [];

  // Filter
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  DateTime? _selectedSpecificDate;

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

      if (_selectedSpecificDate != null) {
        return date.day == _selectedSpecificDate!.day &&
            date.month == _selectedSpecificDate!.month &&
            date.year == _selectedSpecificDate!.year;
      }

      return date.month == _selectedMonth && date.year == _selectedYear;
    }).toList()
      ..sort((a, b) {
        final dA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(2000);
        final dB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(2000);
        return dA.compareTo(dB);
      });
  }

  /// Generate HTML-Word document string (.doc)
  String _buildReportWordDoc() {
    final p = widget.pasien;
    final logs = _filteredLogs;
    final periodStr = _selectedSpecificDate != null
        ? '${_selectedSpecificDate!.day} ${_bulanNames[_selectedSpecificDate!.month]} ${_selectedSpecificDate!.year}'
        : '${_bulanNames[_selectedMonth]} $_selectedYear';

    final diets = () {
      final raw = p['diet_types'];
      if (raw is List && raw.isNotEmpty) return raw.cast<String>().join(', ');
      return p['diet_type'] as String? ?? '-';
    }();

    // ─── Nutrisi rows ───
    final nutrisiRows = StringBuffer();
    for (final n in _nutrisiPerDiet) {
      final dt = n['diet_type'] ?? '-';
      final targetNutrients = n['target_nutrients'] as Map<String, dynamic>?;
      nutrisiRows.write('<tr><td colspan="3" style="background:#e8f5e9;font-weight:bold;padding:6px 10px;">$dt</td></tr>');
      if (targetNutrients == null || targetNutrients.isEmpty) {
        nutrisiRows.write('<tr><td colspan="3" style="padding:4px 10px;color:#888;font-style:italic;">Belum ada target nutrisi</td></tr>');
      } else {
        targetNutrients.forEach((key, val) {
          final target = (val['target'] as num?)?.toStringAsFixed(1) ?? '0';
          final aktual = (val['aktual'] as num?)?.toStringAsFixed(1) ?? '0';
          final pct = double.tryParse(target) != null && double.parse(target) > 0
              ? ((double.tryParse(aktual) ?? 0) / double.parse(target) * 100).toInt()
              : 0;
          final isOk = pct >= 80 && pct <= 120;
          final badge = '<span style="background:${isOk ? '#d1fae5' : '#fee2e2'};color:${isOk ? '#065f46' : '#991b1b'};border-radius:4px;padding:1px 6px;font-size:10px;">$pct%</span>';
          nutrisiRows.write('<tr><td style="padding:4px 10px;">$key</td><td style="padding:4px 10px;text-align:center;">$aktual / $target</td><td style="padding:4px 10px;text-align:center;">$badge</td></tr>');
        });
      }
    }

    // ─── Meal log rows ───
    final mealRows = StringBuffer();
    if (logs.isEmpty) {
      mealRows.write('<tr><td colspan="2" style="padding:12px;text-align:center;color:#888;font-style:italic;">Tidak ada data catatan makan pada periode ini</td></tr>');
    } else {
      for (final log in logs) {
        final date = DateTime.tryParse(log['date'] ?? '');
        final dateStr = date != null
            ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
            : '-';
        final bb = (log['berat_badan'] as num?)?.toStringAsFixed(1) ?? '-';
        final tb = (log['tinggi_badan'] as num?)?.toStringAsFixed(0) ?? '-';

        final meals = StringBuffer();
        void addMeal(String label, String? val) {
          if ((val ?? '').isNotEmpty) {
            meals.write('<b>$label:</b> $val<br>');
          }
        }
        addMeal('Pagi', log['meal_pagi'] as String?);
        addMeal('Selingan Pagi', log['selingan_pagi'] as String?);
        addMeal('Siang', log['meal_siang'] as String?);
        addMeal('Selingan Sore', log['selingan_sore'] as String?);
        addMeal('Malam', log['meal_malam'] as String?);

        mealRows.write('''
          <tr>
            <td style="padding:8px 10px;vertical-align:top;white-space:nowrap;">
              <b style="color:#0284c7;">$dateStr</b><br>
              <span style="font-size:11px;color:#64748b;">BB: ${bb}kg &middot; TB: ${tb}cm</span>
            </td>
            <td style="padding:8px 10px;">${meals.toString().isEmpty ? '<i style="color:#aaa;">-</i>' : meals.toString()}</td>
          </tr>
        ''');
      }
    }

    final now = DateTime.now();
    final createdStr = '${now.day.toString().padLeft(2,'0')}/${now.month.toString().padLeft(2,'0')}/${now.year} '
        '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';

    return '''
<html xmlns:o="urn:schemas-microsoft-com:office:office"
      xmlns:w="urn:schemas-microsoft-com:office:word"
      xmlns="http://www.w3.org/TR/REC-html40">
<head>
  <meta charset="UTF-8">
  <title>Laporan Harian - ${p['name'] ?? ''}</title>
  <!--[if gte mso 9]><xml><w:WordDocument><w:View>Print</w:View><w:Zoom>100</w:Zoom></w:WordDocument></xml><![endif]-->
  <style>
    body { font-family: "Times New Roman", serif; font-size: 12pt; margin: 2cm; }
    h1 { font-size: 16pt; text-align: center; margin-bottom: 4px; }
    h2 { font-size: 13pt; border-bottom: 2px solid #3B7A57; color: #3B7A57; padding-bottom: 4px; margin-top: 20px; }
    table { width: 100%; border-collapse: collapse; margin-bottom: 16px; }
    th { background: #3B7A57; color: white; padding: 7px 10px; text-align: left; }
    td { border: 1px solid #ddd; font-size: 11pt; }
    .info-table td { border: none; padding: 4px 8px; }
    .info-table td:first-child { color: #555; width: 170px; }
    .footer { margin-top: 24px; font-size: 10pt; color: #888; text-align: center; border-top: 1px solid #eee; padding-top: 8px; }
  </style>
</head>
<body>
  <h1>LAPORAN HARIAN PASIEN</h1>
  <p style="text-align:center;color:#555;margin-top:0;">Periode: $periodStr</p>

  <h2>Informasi Pasien</h2>
  <table class="info-table">
    <tr><td>Nama</td><td>: ${p['name'] ?? '-'}</td></tr>
    <tr><td>No. Rekam Medis</td><td>: ${p['rm'] ?? '-'}</td></tr>
    <tr><td>Tanggal Lahir</td><td>: ${p['birthdate'] ?? '-'}</td></tr>
    <tr><td>Jenis Kelamin</td><td>: ${p['gender'] ?? '-'}</td></tr>
    <tr><td>Diagnosis</td><td>: ${p['diagnosis'] ?? '-'}</td></tr>
    <tr><td>Status Gizi</td><td>: ${p['status_gizi'] ?? '-'}</td></tr>
    <tr><td>Terapi Diet</td><td>: $diets</td></tr>
    ${(p['target_diet'] as String? ?? '').isNotEmpty ? '<tr><td>Target Diet</td><td>: ${p['target_diet']}</td></tr>' : ''}
    ${(p['catatan_klinis'] as String? ?? '').isNotEmpty ? '<tr><td>Catatan Klinis</td><td>: ${p['catatan_klinis']}</td></tr>' : ''}
  </table>

  ${_nutrisiPerDiet.isNotEmpty ? '''
  <h2>Target &amp; Capaian Gizi Harian</h2>
  <table>
    <tr>
      <th>Parameter</th>
      <th style="text-align:center;">Capaian / Target</th>
      <th style="text-align:center;">%</th>
    </tr>
    ${nutrisiRows.toString()}
  </table>
  ''' : ''}

  <h2>Rekap Catatan Makan (${logs.length} entri)</h2>
  <table>
    <tr>
      <th style="width:130px;">Tanggal</th>
      <th>Catatan Makan</th>
    </tr>
    ${mealRows.toString()}
  </table>

  <div class="footer">
    Laporan dicetak otomatis oleh Sistem Gizi Klinik RSUD Natuna &mdash; $createdStr
  </div>
</body>
</html>
''';
  }

  Future<void> _exportLaporan() async {
    setState(() => _isExporting = true);
    try {
      final docContent = _buildReportWordDoc();
      final periodStr = _selectedSpecificDate != null
          ? '${_selectedSpecificDate!.day}_${_selectedSpecificDate!.month}_${_selectedSpecificDate!.year}'
          : '${_selectedMonth}_$_selectedYear';
      final fileName =
          'Laporan_Harian_${widget.pasien['rm']}_$periodStr.doc';
      if (kIsWeb) {
        // Di web: share sebagai plain text fallback
        await Share.share(docContent,
            subject: 'Laporan Harian ${widget.pasien['name']} - $periodStr');
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsString(docContent, flush: true);
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/msword')],
          subject: 'Laporan Harian ${widget.pasien['name']} - $periodStr',
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
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Laporan Harian Pasien',
            style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 15)),
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary))
                : const Icon(Icons.share_outlined, color: AppColors.primary),
            onPressed: _isExporting ? null : _exportLaporan,
            tooltip: 'Ekspor & Bagikan Laporan',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
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
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedMonth,
                    isExpanded: true,
                    items: months
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(_bulanNames[m],
                                  style: GoogleFonts.manrope(fontSize: 14)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _selectedMonth = v!;
                      _selectedSpecificDate = null;
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedYear,
                  items: [now.year - 1, now.year, now.year + 1]
                      .map((y) => DropdownMenuItem(
                            value: y,
                            child: Text('$y',
                                style: GoogleFonts.manrope(fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _selectedYear = v!;
                    _selectedSpecificDate = null;
                  }),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedSpecificDate ?? now,
                firstDate: DateTime(now.year - 1),
                lastDate: now,
              );
              if (picked != null) {
                setState(() {
                  _selectedSpecificDate = picked;
                  _selectedMonth = picked.month;
                  _selectedYear = picked.year;
                });
              }
            },
            child: Row(
              children: [
                Icon(Icons.event_note_outlined,
                    size: 20,
                    color: _selectedSpecificDate != null
                        ? AppColors.primary
                        : AppColors.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedSpecificDate == null
                        ? 'Pilih Tanggal Spesifik (Opsional)'
                        : 'Tanggal: ${_selectedSpecificDate!.day} ${_bulanNames[_selectedSpecificDate!.month]} ${_selectedSpecificDate!.year}',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: _selectedSpecificDate != null
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: _selectedSpecificDate != null
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                if (_selectedSpecificDate != null)
                  GestureDetector(
                    onTap: () => setState(() => _selectedSpecificDate = null),
                    child: const Icon(Icons.close, size: 16, color: Colors.red),
                  ),
              ],
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
    final periodStr = _selectedSpecificDate != null
        ? '${_selectedSpecificDate!.day} ${_bulanNames[_selectedSpecificDate!.month]}'
        : '${_bulanNames[_selectedMonth]} $_selectedYear';

    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle),
                child: Text(
                  (p['name'] as String? ?? 'P').substring(0, 1).toUpperCase(),
                  style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['name'] ?? '-',
                        style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    Text('No. RM: ${p['rm'] ?? '-'}',
                        style: GoogleFonts.manrope(
                            fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(periodStr,
                    style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          _infoRow('Diagnosis', p['diagnosis'] ?? '-'),
          _infoRow('Status Gizi', p['status_gizi'] ?? '-'),
          _infoRow('Terapi Diet', diets),
          if ((p['target_diet'] as String? ?? '').isNotEmpty)
            _infoRow('Target Diet', p['target_diet']),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 90,
                child: Text('$label:',
                    style: GoogleFonts.manrope(
                        fontSize: 12, color: Colors.white70))),
            Expanded(
                child: Text(value,
                    style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white))),
          ],
        ),
      );

  Widget _buildNutrisiSummaryCard() {
    if (_nutrisiPerDiet.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.analytics_outlined,
                color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text('Target & Capaian Gizi',
                style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 12),
          ..._nutrisiPerDiet.map((n) {
            final dietName = n['diet_type'] as String? ?? '-';
            final targetNutrients =
                n['target_nutrients'] as Map<String, dynamic>? ?? {};
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(dietName,
                      style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark)),
                ),
                if (targetNutrients.isEmpty)
                  Text('(Belum ada target nutrisi)',
                      style: GoogleFonts.manrope(
                          fontSize: 12, color: AppColors.textMuted))
                else
                  ...targetNutrients.entries.map((e) {
                    final target =
                        (e.value['target'] as num?)?.toDouble() ?? 0;
                    final aktual =
                        (e.value['aktual'] as num?)?.toDouble() ?? 0;
                    final pct =
                        target > 0 ? (aktual / target).clamp(0.0, 1.2) : 0.0;
                    final isOk = pct >= 0.8 && pct <= 1.2;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Expanded(
                            flex: 3,
                            child: Text(e.key,
                                style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: AppColors.textSecondary))),
                        Expanded(
                            flex: 2,
                            child: Text(
                              '${aktual.toStringAsFixed(1)} / ${target.toStringAsFixed(1)}',
                              style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                            )),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOk
                                ? const Color(0xFFD1FAE5)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${(pct * 100).toInt()}%',
                              style: GoogleFonts.manrope(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isOk
                                      ? const Color(0xFF065F46)
                                      : const Color(0xFF991B1B))),
                        ),
                      ]),
                    );
                  }),
                const SizedBox(height: 8),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCatatanMakanCard() {
    final logs = _filteredLogs;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.restaurant_outlined,
                color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text('Rekap Catatan Makan',
                style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8)),
              child: Text('${logs.length} entri',
                  style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark)),
            ),
          ]),
          const SizedBox(height: 12),
          if (logs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 48,
                        color: AppColors.textMuted.withValues(alpha: 0.5)),
                    const SizedBox(height: 8),
                    Text('Tidak ada catatan makan\npada periode ini.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                            fontSize: 13, color: AppColors.textMuted)),
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
                      Text(dateStr,
                          style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0284C7))),
                      const Spacer(),
                      if (bb != null && tb != null)
                        Text('BB: ${bb}kg · TB: ${tb}cm',
                            style: GoogleFonts.manrope(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                    ]),
                    const SizedBox(height: 6),
                    ...[
                      ('Pagi', log['meal_pagi']),
                      ('Selingan Pagi', log['selingan_pagi']),
                      ('Siang', log['meal_siang']),
                      ('Selingan Sore', log['selingan_sore']),
                      ('Malam', log['meal_malam']),
                    ]
                        .where((e) => (e.$2 as String? ?? '').isNotEmpty)
                        .map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      color: AppColors.textPrimary),
                                  children: [
                                    TextSpan(
                                        text: '${e.$1}: ',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary)),
                                    TextSpan(text: e.$2 as String),
                                  ],
                                ),
                              ),
                            )),
                  ],
                ),
              );
            }),
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
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.share_outlined, size: 20),
        label: Text(
          _isExporting ? 'Menyiapkan laporan...' : 'Ekspor & Bagikan Laporan',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }
}
