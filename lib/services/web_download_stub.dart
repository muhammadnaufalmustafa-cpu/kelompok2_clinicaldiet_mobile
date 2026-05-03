/// Stub implementation for non-web platforms.
/// On mobile/desktop, downloading via browser API is not applicable.
void downloadFileOnWeb(String base64Data, String filename) {
  // No-op on non-web platforms.
}

/// Stub: HTML download not applicable on non-web platforms.
void downloadHtmlFileOnWeb(String htmlContent, String filename) {
  // No-op on non-web platforms.
}
