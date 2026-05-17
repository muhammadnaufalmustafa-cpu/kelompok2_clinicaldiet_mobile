import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

/// Stub implementation for non-web platforms.
/// On mobile/desktop, downloading via browser API is not applicable.
void downloadFileOnWeb(String base64Data, String filename) {
  // No-op on non-web platforms.
}

/// On mobile, we convert HTML to PDF, save it to a temporary file, and share it.
Future<void> downloadHtmlFileOnWeb(String htmlContent, String filename) async {
  try {
    final pdfBytes = await Printing.convertHtml(
      format: PdfPageFormat.a4,
      html: htmlContent,
    );
    
    // Change extension to .pdf if it ends with .html
    String pdfFilename = filename;
    if (filename.toLowerCase().endsWith('.html')) {
      pdfFilename = filename.substring(0, filename.length - 5) + '.pdf';
    } else if (!filename.toLowerCase().endsWith('.pdf')) {
      pdfFilename += '.pdf';
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$pdfFilename');
    await file.writeAsBytes(pdfBytes);
    await Share.shareXFiles([XFile(file.path)], text: 'Dokumen Informed Consent (PDF)');
  } catch (e) {
    throw Exception('Gagal membagikan PDF: $e');
  }
}

