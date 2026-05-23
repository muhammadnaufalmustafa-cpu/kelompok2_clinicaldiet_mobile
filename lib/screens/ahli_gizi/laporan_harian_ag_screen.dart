import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';

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
  List<Map<String, dynamic>> _patientPrograms = [];

  // Filter
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  DateTime? _selectedSpecificDate = DateTime.now();

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
    List<Map<String, dynamic>> programs = await AuthService.getPatientTherapyProgramsByRm(rm);
    
    // Fallback jika tidak ada program spesifik
    if (programs.isEmpty) {
      final raw = widget.pasien['diet_types'];
      List<String> dietList = [];
      if (raw is List && raw.isNotEmpty) {
        dietList = raw.cast<String>();
      } else {
        final single = widget.pasien['diet_type'] as String? ?? '';
        if (single.isNotEmpty && single != '(Belum ada diet)') {
          dietList = [single];
        }
      }
      for (var d in dietList) {
        programs.add({
          'therapyProgramName': d,
          'patientProgramId': 'legacy_$d',
          'diagnosis': widget.pasien['diagnosis'] ?? '-',
          'catatan_klinis': widget.pasien['catatan_klinis'] ?? '-',
        });
      }
    }

    if (mounted) {
      setState(() {
        _mealLogs = logs;
        _nutrisiPerDiet = nutrisi;
        _patientPrograms = programs;
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
  String _buildReportWordDoc(String logoNatunaBase64, String logoKarsBase64) {
    final p = widget.pasien;
    final logs = _filteredLogs;
    final periodStr = _selectedSpecificDate != null
        ? '${_selectedSpecificDate!.day} ${_bulanNames[_selectedSpecificDate!.month]} ${_selectedSpecificDate!.year}'
        : '${_bulanNames[_selectedMonth]} $_selectedYear';

    final programBlocks = StringBuffer();

    for (int i = 0; i < _patientPrograms.length; i++) {
      var prog = _patientPrograms[i];
      final progName = prog['therapyProgramName'] as String? ?? '-';
      final progId = prog['patientProgramId'] as String? ?? '';
      final diagnosis = prog['diagnosis']?.toString() ?? '-';
      final catatanKlinis = prog['catatan_klinis']?.toString() ?? '-';

      programBlocks.write('<h2 style="margin-top: 30px; padding-top: 10px; color: #1e3a8a; border-bottom: 2px solid #1e3a8a;">Program: $progName</h2>');

      // Informasi Klinis Program
      programBlocks.write('<table border="0" cellpadding="4" cellspacing="0" style="margin-bottom: 15px;">');
      programBlocks.write('<tr><td width="150" style="color: #555;">Diagnosis Medis</td><td>: <b>$diagnosis</b></td></tr>');
      if (catatanKlinis.isNotEmpty && catatanKlinis != '-') {
        programBlocks.write('<tr><td width="150" style="color: #555; vertical-align: top;">Catatan Klinis</td><td style="vertical-align: top;">: $catatanKlinis</td></tr>');
      }
      programBlocks.write('</table>');

      // Nutrisi Program
      final progNutrisi = _nutrisiPerDiet.where((n) => n['diet_type'] == progName).toList();
      if (progNutrisi.isNotEmpty) {
        programBlocks.write('<h3 style="font-size: 12pt; color: #333; margin-bottom: 5px;">Target &amp; Capaian Gizi</h3>');
        programBlocks.write('<table border="1" cellpadding="6" cellspacing="0" width="100%" style="border-collapse: collapse; margin-bottom: 15px; font-size: 11pt;">');
        programBlocks.write('<tr style="background-color: #3B7A57; color: white;"><th width="45%" style="text-align: left;">Parameter</th><th width="35%" style="text-align: center;">Capaian / Target</th><th width="20%" style="text-align: center;">%</th></tr>');
        for (final n in progNutrisi) {
          final targetNutrients = n['target_nutrients'] as Map<String, dynamic>?;
          if (targetNutrients == null || targetNutrients.isEmpty) {
            programBlocks.write('<tr><td colspan="3" style="color: #888; font-style: italic; text-align: center;">Belum ada target nutrisi</td></tr>');
          } else {
            targetNutrients.forEach((key, val) {
              final target = (val['target'] as num?)?.toStringAsFixed(1) ?? '0';
              final aktual = (val['aktual'] as num?)?.toStringAsFixed(1) ?? '0';
              final pct = double.tryParse(target) != null && double.parse(target) > 0
                  ? ((double.tryParse(aktual) ?? 0) / double.parse(target) * 100).toInt()
                  : 0;
              final isOk = pct >= 80 && pct <= 120;
              final bgColor = isOk ? '#d1fae5' : '#fee2e2';
              final textColor = isOk ? '#065f46' : '#991b1b';
              programBlocks.write('<tr>');
              programBlocks.write('<td>$key</td>');
              programBlocks.write('<td align="center">$aktual / $target</td>');
              programBlocks.write('<td align="center" style="background-color: $bgColor; color: $textColor; font-weight: bold;">$pct%</td>');
              programBlocks.write('</tr>');
            });
          }
        }
        programBlocks.write('</table>');
      }

      // Meal Logs Program
      final progLogs = logs.where((l) => l['patientProgramId'] == progId || l['diet_type'] == progName).toList();
      programBlocks.write('<h3 style="font-size: 12pt; color: #333; margin-bottom: 5px;">Rekap Catatan Makan (${progLogs.length} entri)</h3>');
      programBlocks.write('<table border="1" cellpadding="6" cellspacing="0" width="100%" style="border-collapse: collapse; font-size: 11pt;">');
      programBlocks.write('<tr style="background-color: #3B7A57; color: white;"><th width="25%" style="text-align: left;">Tanggal</th><th width="75%" style="text-align: left;">Catatan Makan</th></tr>');
      if (progLogs.isEmpty) {
        programBlocks.write('<tr><td colspan="2" style="text-align: center; color: #888; font-style: italic;">Tidak ada data catatan makan untuk program ini</td></tr>');
      } else {
        for (final log in progLogs) {
          final date = DateTime.tryParse(log['date'] ?? '');
          final dateStr = date != null ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}' : '-';
          final bb = (log['berat_badan'] as num?)?.toStringAsFixed(1) ?? '-';
          final tb = (log['tinggi_badan'] as num?)?.toStringAsFixed(0) ?? '-';

          final meals = StringBuffer();
          void addMeal(String label, String? val) {
            if ((val ?? '').isNotEmpty) meals.write('<b>$label:</b> $val<br>');
          }
          addMeal('Pagi', log['meal_pagi'] as String?);
          addMeal('Selingan Pagi', log['selingan_pagi'] as String?);
          addMeal('Siang', log['meal_siang'] as String?);
          addMeal('Selingan Sore', log['selingan_sore'] as String?);
          addMeal('Malam', log['meal_malam'] as String?);

          programBlocks.write('<tr>');
          programBlocks.write('<td style="vertical-align: top;">');
          programBlocks.write('<b style="color: #0284c7;">$dateStr</b><br><span style="font-size: 10pt; color: #555;">BB: ${bb}kg<br>TB: ${tb}cm</span>');
          programBlocks.write('</td>');
          programBlocks.write('<td style="vertical-align: top;">${meals.toString().isEmpty ? '<i style="color:#aaa;">-</i>' : meals.toString()}</td>');
          programBlocks.write('</tr>');
        }
      }
      programBlocks.write('</table>');
      
      // Pembatas antar program jika belum program terakhir
      if (i < _patientPrograms.length - 1) {
        programBlocks.write('<hr style="border: 1px solid #ccc; margin-top: 30px;" />');
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
    body { font-family: "Times New Roman", serif; font-size: 12pt; margin: 1cm; }
    h1 { font-size: 16pt; text-align: center; margin-bottom: 4px; }
    h2 { font-size: 13pt; color: #3B7A57; padding-bottom: 4px; margin-top: 20px; }
    table { border-collapse: collapse; margin-bottom: 16px; }
    th { padding: 7px 10px; }
    td { font-size: 11pt; }
    .info-table td { border: none; padding: 4px 8px; }
    .info-table td:first-child { color: #555; width: 170px; }
    .footer { margin-top: 24px; font-size: 10pt; color: #888; text-align: center; border-top: 1px solid #eee; padding-top: 8px; }
  </style>
</head>
<body>
  <div style="text-align:center; margin-bottom: 20px; border-bottom: 3px solid #3B7A57; padding-bottom: 10px;">
    <table style="width: 100%; border: none; margin-bottom: 0;">
      <tr>
        <td style="width: 15%; text-align: left; border: none;">
          <img src="data:image/png;base64,$logoNatunaBase64" alt="Logo Natuna" height="70" />
        </td>
        <td style="width: 70%; text-align: center; border: none; vertical-align: middle;">
          <h1 style="margin: 0; font-size: 16pt;">PEMERINTAH KABUPATEN NATUNA</h1>
          <h1 style="margin: 4px 0; font-size: 18pt;">RUMAH SAKIT UMUM DAERAH NATUNA</h1>
          <p style="margin: 0; font-size: 10pt; color: #555;">Jl. Ali Murtopo, Ranai - Kab. Natuna, Kepulauan Riau</p>
        </td>
        <td style="width: 15%; text-align: right; border: none;">
          <img src="data:image/png;base64,$logoKarsBase64" alt="Logo KARS" height="70" />
        </td>
      </tr>
    </table>
    <div style="margin-top: 15px;">
      <h1 style="margin: 0; font-size: 14pt; color: #3B7A57;">LAPORAN HARIAN PASIEN</h1>
    </div>
  </div>
  <p style="text-align:center;color:#555;margin-top:0;">Periode: $periodStr</p>

  <h2>Informasi Pasien</h2>
  <table class="info-table">
    <tr><td>Nama</td><td>: ${p['name'] ?? '-'}</td></tr>
    <tr><td>No. Rekam Medis</td><td>: ${p['rm'] ?? '-'}</td></tr>
    <tr><td>Tanggal Lahir</td><td>: ${p['birthdate'] ?? '-'}</td></tr>
    <tr><td>Jenis Kelamin</td><td>: ${p['gender'] ?? '-'}</td></tr>
    <tr><td>Status Gizi</td><td>: ${p['status_gizi'] ?? '-'}</td></tr>
  </table>

  ${programBlocks.toString()}

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
      final logoNatunaData = await rootBundle.load('assets/images/logo_natuna.png');
      final logoKarsData = await rootBundle.load('assets/images/logo_kars.png');
      final logoNatunaBase64 = base64Encode(logoNatunaData.buffer.asUint8List());
      final logoKarsBase64 = base64Encode(logoKarsData.buffer.asUint8List());

      final docContent = _buildReportWordDoc(logoNatunaBase64, logoKarsBase64);
      final periodStr = _selectedSpecificDate != null
          ? '${_selectedSpecificDate!.day}_${_selectedSpecificDate!.month}_${_selectedSpecificDate!.year}'
          : '${_selectedMonth}_$_selectedYear';
      final timestamp = '${DateTime.now().hour}${DateTime.now().minute}${DateTime.now().second}';
      final fileName =
          'Laporan_Harian_${widget.pasien['rm']}_${periodStr}_$timestamp.doc';
      if (kIsWeb) {
        // Di web: share sebagai plain text fallback
        await Share.share(docContent,
            subject: 'Laporan Harian ${widget.pasien['name']} - $periodStr');
      } else {
        File? finalFile;
        if (Platform.isAndroid) {
          try {
            final downloadDir = Directory('/storage/emulated/0/Download');
            if (await downloadDir.exists()) {
              finalFile = File('${downloadDir.path}/$fileName');
            }
          } catch (_) {}
        }
        
        if (finalFile == null) {
          final dir = await getTemporaryDirectory();
          finalFile = File('${dir.path}/$fileName');
        }

        await finalFile.writeAsString(docContent, flush: true);

        try {
          await NotificationService().showInstantNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: 'Unduhan Laporan Harian Berhasil',
            body: 'Laporan $fileName berhasil disimpan. Ketuk untuk membuka.',
            payload: finalFile.path,
          );
        } catch (_) {}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Laporan berhasil disimpan: $fileName', style: GoogleFonts.manrope()),
            backgroundColor: AppColors.primary,
            action: SnackBarAction(
              label: 'Buka File',
              textColor: Colors.white,
              onPressed: () {
                OpenFilex.open(finalFile!.path);
              },
            ),
          ));
        }
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
                        ..._patientPrograms.map((prog) => _buildProgramCard(prog)),
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
    final periodStr = _selectedSpecificDate != null
        ? '${_selectedSpecificDate!.day} ${_bulanNames[_selectedSpecificDate!.month]}'
        : '${_bulanNames[_selectedMonth]} $_selectedYear';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondary, AppColors.secondary.withValues(alpha: 0.8)],
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
          _infoRow('Status Gizi', p['status_gizi'] ?? '-'),
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

  Widget _programInfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 105,
                child: Text(label,
                    style: GoogleFonts.manrope(
                        fontSize: 12, color: AppColors.textSecondary))),
            Expanded(
                child: Text(value,
                    style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary))),
          ],
        ),
      );

  Widget _buildProgramCard(Map<String, dynamic> prog) {
    final progName = prog['therapyProgramName'] as String? ?? '-';
    final progId = prog['patientProgramId'] as String? ?? '';
    final diagnosis = prog['diagnosis']?.toString() ?? '-';
    final catatanKlinis = prog['catatan_klinis']?.toString() ?? '-';

    final progNutrisi = _nutrisiPerDiet.where((n) => n['diet_type'] == progName).toList();
    final progLogs = _filteredLogs.where((l) => l['patientProgramId'] == progId || l['diet_type'] == progName).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Program
          Row(
            children: [
              const Icon(Icons.bookmark, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Program: $progName',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),

          // Klinis Program
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _programInfoRow('Diagnosis', diagnosis),
                if (catatanKlinis.isNotEmpty && catatanKlinis != '-')
                  _programInfoRow('Catatan Klinis', catatanKlinis),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Nutrisi Program
          if (progNutrisi.isNotEmpty) ...[
            Row(children: [
              const Icon(Icons.analytics_outlined, color: AppColors.secondary, size: 16),
              const SizedBox(width: 6),
              Text('Target & Capaian Gizi',
                  style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ]),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: progNutrisi.map((n) {
                  final targetNutrients = n['target_nutrients'] as Map<String, dynamic>? ?? {};
                  if (targetNutrients.isEmpty) {
                    return Text('(Belum ada target nutrisi)',
                        style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textMuted));
                  }
                  return Column(
                    children: targetNutrients.entries.map((e) {
                      final target = (e.value['target'] as num?)?.toDouble() ?? 0;
                      final aktual = (e.value['aktual'] as num?)?.toDouble() ?? 0;
                      final pct = target > 0 ? (aktual / target).clamp(0.0, 1.2) : 0.0;
                      final isOk = pct >= 0.8 && pct <= 1.2;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          Expanded(
                              flex: 3,
                              child: Text('\u2022 ${e.key}',
                                  style: GoogleFonts.manrope(
                                      fontSize: 12, color: AppColors.textSecondary))),
                          Expanded(
                              flex: 3,
                              child: Text(
                                '${aktual.toStringAsFixed(1)} / ${target.toStringAsFixed(1)}',
                                style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary),
                              )),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isOk ? AppColors.primaryLight : AppColors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('${(pct * 100).toInt()}%',
                                style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: isOk ? AppColors.primaryDark : AppColors.red)),
                          ),
                        ]),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Meal Logs Program
          Row(children: [
            const Icon(Icons.restaurant_outlined, color: AppColors.secondary, size: 16),
            const SizedBox(width: 6),
            Text('Rekap Catatan Makan (${progLogs.length} entri)',
                style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 8),
          if (progLogs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Tidak ada catatan makan untuk program ini',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textMuted)),
            )
          else
            ...progLogs.map((log) {
              final date = DateTime.tryParse(log['date'] ?? '');
              final dateStr = date != null
                  ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                  : '-';
              final bb = (log['berat_badan'] as num?)?.toStringAsFixed(1);
              final tb = (log['tinggi_badan'] as num?)?.toStringAsFixed(0);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(dateStr,
                          style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary)),
                      const Spacer(),
                      if (bb != null && tb != null)
                        Text('BB: ${bb}kg · TB: ${tb}cm',
                            style: GoogleFonts.manrope(
                                fontSize: 10, color: AppColors.textSecondary)),
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
                                      fontSize: 11, color: AppColors.textPrimary),
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
            : const Icon(Icons.download_outlined, size: 20),
        label: Text(
          _isExporting ? 'Mengunduh laporan...' : 'Unduh Laporan (Word)',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
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
