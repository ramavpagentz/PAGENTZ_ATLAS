import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Web download helper — creates a hidden anchor element and clicks it to
/// trigger a browser download.
void triggerDownload({
  required String filename,
  required String contents,
  required String mime,
}) {
  final blob = web.Blob(
    [contents.toJS].toJS,
    web.BlobPropertyBag(type: mime),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename
    ..style.display = 'none';
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}

void openUrlInNewTab(String url) {
  web.window.open(url, '_blank');
}
