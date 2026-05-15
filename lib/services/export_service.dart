import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/age_calculator.dart';

class ExportService {
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

      // Header Kolom (14 Kolom)
      final headers = [
        'No',
        'No rm',
        'Nama',
        'no hp',
        'Tanggal lahir',
        'Jenis kelamin',
        'Berat badan',
        'Tinggi badan',
        'Status gizi',
        'Diagnosis Medis',
        'Terapi Diet',
        'Nama ahli gizi',
        'Rating pemberian pasien',
        'Keterangan'
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

        // Cari rating pasien ini
        String ratingStr = '-';
        try {
          final review = reviews.firstWhere((r) => r['pasienRm'] == rm);
          if (review['rating'] != null) {
            ratingStr = review['rating'].toString();
          }
        } catch (_) {
          // Tidak ada rating dari pasien ini
        }

        final rowData = [
          (i + 1).toString(), // No
          rm, // No rm
          p['name']?.toString() ?? '-', // Nama
          p['phone']?.toString() ?? '-', // no hp
          p['birthdate']?.toString() ?? '-', // Tanggal lahir
          p['gender']?.toString() ?? '-', // Jenis kelamin
          p['weight']?.toString() ?? '-', // Berat badan
          p['height']?.toString() ?? '-', // Tinggi badan
          p['status_gizi']?.toString() ?? '-', // Status gizi
          p['diagnosis']?.toString() ?? '-', // Diagnosis Medis
          dietStr, // Terapi Diet
          ahliGizi['name']?.toString() ?? '-', // Nama ahli gizi
          ratingStr, // Rating
          p['catatan_klinis']?.toString() ?? '-', // Keterangan
        ];

        for (int c = 0; c < rowData.length; c++) {
          var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: i + 1));
          cell.value = TextCellValue(rowData[c]);
        }
      }

      // Simpan File
      final fileBytes = excel.encode();
      if (fileBytes == null) return false;

      final fileName = 'Laporan_Pasien_${ahliGizi['name']?.toString().replaceAll(" ", "_")}_$monthYearStr.xlsx';

      if (kIsWeb) {
        // Untuk web
        await Share.shareXFiles(
          [XFile.fromData(Uint8List.fromList(fileBytes), name: fileName, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
          text: 'Laporan Pasien Bulanan',
        );
      } else {
        // Untuk Android/iOS
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Laporan Pasien',
        );
      }

      return true;
    } catch (e) {
      print('DEBUG: Error exporting excel: $e');
      return false;
    }
  }
}
