import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/age_calculator.dart';
import '../services/notification_service.dart';

class ExportService {
  /// Hitung status gizi berdasarkan IMT
  static String _hitungStatusGizi(dynamic weight, dynamic height) {
    final imt = AgeCalculator.calculateIMT(weight, height);
    if (imt == null) return '-';
    final imtVal = double.tryParse(imt.toString()) ?? 0;
    if (imtVal < 18.5) return 'Kurang ($imt)';
    if (imtVal < 25.0) return 'Normal ($imt)';
    if (imtVal < 30.0) return 'Gemuk/Lebih ($imt)';
    return 'Obesitas ($imt)';
  }

  /// Ekspor daftar pasien yang difilter ke format Excel (.xlsx)
  static Future<bool> exportPasienToExcel({
    required List<Map<String, dynamic>> pasienList,
    required Map<String, dynamic> ahliGizi,
    required String monthYearStr,
  }) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Laporan Bulanan'];
      excel.setDefaultSheet('Laporan Bulanan');

      // Style Header
      CellStyle headerStyle = CellStyle(
        bold: true,
        fontFamily: getFontFamily(FontFamily.Calibri),
      );

      // Header Kolom (15 Kolom)
      final headers = [
        'No',
        'No RM',
        'Nama Pasien',
        'No HP',
        'Tanggal Lahir',
        'Jenis Kelamin',
        'Berat Badan (kg)',
        'Tinggi Badan (cm)',
        'Status Gizi (IMT)',
        'Diagnosis Medis',
        'Terapi Diet',
        'Status Program',
        'Nama Ahli Gizi',
        'Rating Pasien',
        'Evaluasi Akhir Ahli Gizi',
        'Catatan Evaluasi Terakhir',
      ];

      for (int i = 0; i < headers.length; i++) {
        var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Ambil reviews array dari ahliGizi untuk mencari rating per pasien
      final reviews = (ahliGizi['reviews'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      // Isi Data
      for (int i = 0; i < pasienList.length; i++) {
        final p = pasienList[i];
        final rm = p['rm']?.toString() ?? '-';

        // Terapi diet
        final dietStr = () {
          final raw = p['diet_types'];
          if (raw is List && raw.isNotEmpty) return raw.cast<String>().join(', ');
          return p['diet_type'] as String? ?? '-';
        }();

        // Status gizi dihitung dari IMT (BB/TB)
        final statusGizi = _hitungStatusGizi(p['weight'], p['height']);

        // Status program
        final statusPasien = p['status']?.toString() ?? 'aktif';
        final statusProgram = () {
          switch (statusPasien) {
            case 'berhasil': return 'Selesai/Berhasil';
            case 'dropout': return 'Dropout';
            case 'meninggal': return 'Meninggal';
            case 'aktif': return 'Aktif';
            default: return statusPasien;
          }
        }();

        // Rating dari reviews
        String ratingStr = 'Belum ada rating';
        try {
          final review = reviews.firstWhere((r) => r['pasienRm'] == rm);
          final ratingVal = review['rating'];
          if (ratingVal != null) {
            ratingStr = '$ratingVal ★';
          }
        } catch (_) {}

        // Evaluasi akhir (diisi saat klik "Berhasil")
        final evaluasiAkhir = p['evaluasi_akhir']?.toString() ?? '-';
        final outcomeProgram = p['outcome_program']?.toString() ?? '';
        final keteranganFinal = evaluasiAkhir == '-'
            ? '-'
            : (outcomeProgram.isNotEmpty ? '[$outcomeProgram] $evaluasiAkhir' : evaluasiAkhir);

        // Point 7: Catatan evaluasi terakhir (yang paling update)
        final catEval = p['catatan_evaluasi_terakhir'] as Map<String, dynamic>?;
        final catatanEvaluasiStr = catEval != null ? (catEval['catatan']?.toString() ?? '-') : '-';

        final rowData = [
          (i + 1).toString(),                        // No
          rm,                                         // No RM
          p['name']?.toString() ?? '-',              // Nama Pasien
          p['phone']?.toString() ?? '-',             // No HP
          p['birthdate']?.toString() ?? '-',         // Tanggal Lahir
          p['gender']?.toString() ?? '-',            // Jenis Kelamin
          p['weight']?.toString() ?? '-',            // Berat Badan
          p['height']?.toString() ?? '-',            // Tinggi Badan
          statusGizi,                                 // Status Gizi (auto dari IMT)
          p['diagnosis']?.toString() ?? '-',         // Diagnosis Medis
          dietStr,                                    // Terapi Diet
          statusProgram,                              // Status Program
          ahliGizi['name']?.toString() ?? '-',       // Nama Ahli Gizi
          ratingStr,                                  // Rating Pasien
          keteranganFinal,                            // Evaluasi Akhir
          catatanEvaluasiStr,                         // Catatan Evaluasi Terakhir
        ];

        for (int c = 0; c < rowData.length; c++) {
          var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: i + 1));
          cell.value = TextCellValue(rowData[c]);
        }
      }

      // Simpan File
      final fileBytes = excel.encode();
      if (fileBytes == null) return false;

      final timestamp = '${DateTime.now().hour}${DateTime.now().minute}${DateTime.now().second}';
      final fileName = 'Laporan_Pasien_${ahliGizi['name']?.toString().replaceAll(" ", "_")}_${monthYearStr}_$timestamp.xlsx';

      if (kIsWeb) {
        // Web: Share via browser download
        await Share.shareXFiles(
          [XFile.fromData(Uint8List.fromList(fileBytes), name: fileName, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
          text: 'Laporan Pasien Bulanan',
        );
        return true;
      }

      // Android / iOS: Simpan ke storage lokal
      File? finalFile;
      if (Platform.isAndroid) {
        try {
          final downloadDir = Directory('/storage/emulated/0/Download');
          if (await downloadDir.exists()) {
            finalFile = File('${downloadDir.path}/$fileName');
            await finalFile.writeAsBytes(fileBytes);
          }
        } catch (_) {}
      }

      if (finalFile == null) {
        final directory = await getTemporaryDirectory();
        finalFile = File('${directory.path}/$fileName');
        await finalFile.writeAsBytes(fileBytes);
      }

      try {
        await NotificationService().showInstantNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: 'Unduhan Berhasil 📊',
          body: 'Laporan $fileName berhasil disimpan. Ketuk untuk membuka.',
          payload: finalFile.path,
        );
      } catch (_) {}
      
      // Buka file langsung
      OpenFilex.open(finalFile.path);

      return true;
    } catch (e) {
      return false;
    }
  }
}
