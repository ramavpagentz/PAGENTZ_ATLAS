import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'web_download_stub.dart'
    if (dart.library.html) 'web_download_web.dart';

/// Trigger a CSV file download in the browser.
///
/// Web-only. On other platforms this is a no-op (Atlas is web-only anyway).
void downloadCsv({required String filename, required List<List<dynamic>> rows}) {
  final csv = const ListToCsvConverter().convert(rows);
  if (kIsWeb) {
    triggerDownload(filename: filename, contents: csv, mime: 'text/csv');
  }
}
