/// Conditional export: uses dart:html on web, no-op on other platforms.
export 'web_download_stub.dart'
    if (dart.library.html) 'web_download_web.dart';
