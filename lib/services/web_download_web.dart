// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Triggers a browser download of a base64-encoded PNG file.
void downloadFileOnWeb(String base64Data, String filename) {
  final dataUri = 'data:image/png;base64,$base64Data';
  final anchor = html.AnchorElement(href: dataUri)
    ..setAttribute('download', filename)
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}

/// Triggers a browser download of raw HTML content as an .html file.
void downloadHtmlFileOnWeb(String htmlContent, String filename) {
  final blob = html.Blob([htmlContent], 'text/html;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
