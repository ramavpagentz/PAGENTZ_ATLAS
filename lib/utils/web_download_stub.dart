// Non-web fallback. Atlas is web-only so these are never invoked in practice.

void triggerDownload({
  required String filename,
  required String contents,
  required String mime,
}) {}

void openUrlInNewTab(String url) {}
