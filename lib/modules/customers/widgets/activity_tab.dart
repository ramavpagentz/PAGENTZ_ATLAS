import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/activity_log_model.dart';
import '../../../core/services/activity_log_service.dart';
import '../../../theme/atlas_colors.dart';
import '../../../theme/atlas_text.dart';
import '../../../utils/web_download_web.dart';

/// Enhanced Activity tab — adds a filter chip strip (category / module /
/// time window), CSV export, and a tap-to-open detail modal on each row.
/// Supersedes `ActivityTimelineWidget` for the Customer Detail screen.
class ActivityTab extends StatefulWidget {
  final String orgId;
  final String orgName;
  const ActivityTab({super.key, required this.orgId, required this.orgName});

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

enum _TimeWindow {
  last24h('Last 24h', Duration(hours: 24)),
  last7d('Last 7 days', Duration(days: 7)),
  last30d('Last 30 days', Duration(days: 30)),
  all('All', null);

  final String label;
  final Duration? duration;
  const _TimeWindow(this.label, this.duration);
}

class _ActivityTabState extends State<ActivityTab> {
  String? _category; // null = all
  String? _module; // null = all
  _TimeWindow _window = _TimeWindow.last7d;

  bool _matches(ActivityLog log) {
    if (_category != null && log.category != _category) return false;
    if (_module != null && log.module != _module) return false;
    if (_window.duration != null) {
      final cutoff = DateTime.now().subtract(_window.duration!);
      if (log.timestamp.isBefore(cutoff)) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ActivityLog>>(
      stream: ActivityLogService.instance.watchOrgActivity(widget.orgId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final logs = snap.data ?? const [];
        final modules = {for (final l in logs) l.module}
          ..removeWhere((s) => s.isEmpty);
        final categories = {for (final l in logs) l.category}
          ..removeWhere((s) => s.isEmpty);
        final filtered = logs.where(_matches).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FilterBar(
              categories: categories.toList()..sort(),
              modules: modules.toList()..sort(),
              activeCategory: _category,
              activeModule: _module,
              window: _window,
              filteredCount: filtered.length,
              totalCount: logs.length,
              onCategory: (c) => setState(() => _category = c),
              onModule: (m) => setState(() => _module = m),
              onWindow: (w) => setState(() => _window = w),
              onExportCsv: kIsWeb && filtered.isNotEmpty
                  ? () => _exportCsv(filtered, widget.orgName)
                  : null,
            ),
            const SizedBox(height: AtlasSpace.md),
            if (filtered.isEmpty)
              const _Empty()
            else
              Container(
                padding: const EdgeInsets.all(AtlasSpace.lg),
                decoration: BoxDecoration(
                  color: AtlasColors.cardBg,
                  border: Border.all(color: AtlasColors.cardBorder),
                  borderRadius: BorderRadius.circular(AtlasRadius.lg),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < filtered.length; i++)
                      _Row(
                        log: filtered[i],
                        isLast: i == filtered.length - 1,
                        onTap: () => _showDetail(context, filtered[i]),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

void _exportCsv(List<ActivityLog> logs, String orgName) {
  String esc(String s) {
    final needs = s.contains(',') || s.contains('"') || s.contains('\n');
    final body = s.replaceAll('"', '""');
    return needs ? '"$body"' : body;
  }

  final header = [
    'timestamp',
    'category',
    'module',
    'eventType',
    'eventLabel',
    'actorDisplay',
    'actorType',
    'targetType',
    'targetId',
    'targetDisplay',
  ];
  final rows = logs.map((l) => [
        l.timestamp.toIso8601String(),
        l.category,
        l.module,
        l.eventType,
        l.eventLabel,
        l.actorDisplay,
        l.actorType ?? '',
        l.targetType,
        l.targetId,
        l.targetDisplay ?? '',
      ]);
  final csv =
      [header, ...rows].map((r) => r.map(esc).join(',')).join('\n');

  final stamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
  triggerDownload(
    filename: 'activity-${_slug(orgName)}-$stamp.csv',
    contents: csv,
    mime: 'text/csv',
  );
}

String _slug(String s) {
  final lower = s.toLowerCase();
  final buf = StringBuffer();
  for (final c in lower.codeUnits) {
    final isAlnum = (c >= 0x30 && c <= 0x39) || (c >= 0x61 && c <= 0x7a);
    buf.writeCharCode(isAlnum ? c : 0x2d);
  }
  return buf.toString().replaceAll(RegExp(r'-+'), '-').replaceAll(
        RegExp(r'^-|-$'),
        '',
      );
}

void _showDetail(BuildContext context, ActivityLog log) {
  showDialog<void>(
    context: context,
    builder: (_) => _DetailDialog(log: log),
  );
}

class _FilterBar extends StatelessWidget {
  final List<String> categories;
  final List<String> modules;
  final String? activeCategory;
  final String? activeModule;
  final _TimeWindow window;
  final int filteredCount;
  final int totalCount;
  final ValueChanged<String?> onCategory;
  final ValueChanged<String?> onModule;
  final ValueChanged<_TimeWindow> onWindow;
  final VoidCallback? onExportCsv;

  const _FilterBar({
    required this.categories,
    required this.modules,
    required this.activeCategory,
    required this.activeModule,
    required this.window,
    required this.filteredCount,
    required this.totalCount,
    required this.onCategory,
    required this.onModule,
    required this.onWindow,
    this.onExportCsv,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(AtlasRadius.md),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          _PopupFilter<_TimeWindow>(
            label: window.label,
            current: window,
            options: _TimeWindow.values,
            optionLabel: (w) => w.label,
            onSelected: onWindow,
          ),
          if (categories.isNotEmpty)
            _PopupFilter<String?>(
              label: activeCategory ?? 'All categories',
              current: activeCategory,
              options: <String?>[null, ...categories],
              optionLabel: (c) => c ?? 'All categories',
              onSelected: onCategory,
            ),
          if (modules.isNotEmpty)
            _PopupFilter<String?>(
              label: activeModule ?? 'All modules',
              current: activeModule,
              options: <String?>[null, ...modules],
              optionLabel: (m) => m ?? 'All modules',
              onSelected: onModule,
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Showing $filteredCount / $totalCount',
              style: const TextStyle(
                fontSize: 11,
                color: AtlasColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onExportCsv != null)
            OutlinedButton.icon(
              onPressed: onExportCsv,
              icon: const Icon(Icons.download, size: 14),
              label: const Text('Export CSV'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class _PopupFilter<T> extends StatelessWidget {
  final String label;
  final T current;
  final List<T> options;
  final String Function(T) optionLabel;
  final ValueChanged<T> onSelected;

  const _PopupFilter({
    required this.label,
    required this.current,
    required this.options,
    required this.optionLabel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: label,
      onSelected: onSelected,
      itemBuilder: (_) => options
          .map((o) => PopupMenuItem<T>(
                value: o,
                child: Text(optionLabel(o)),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AtlasColors.cardBorder),
          borderRadius: BorderRadius.circular(AtlasRadius.sm),
          color: AtlasColors.cardBg,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AtlasColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down,
                size: 14, color: AtlasColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final ActivityLog log;
  final bool isLast;
  final VoidCallback onTap;

  const _Row({
    required this.log,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d, HH:mm');
    final isStaffAction = log.actorType == 'staff_impersonating';
    final dotColor = switch (log.category) {
      'security' => AtlasColors.danger,
      'config' => AtlasColors.warning,
      'operations' => AtlasColors.info,
      _ => AtlasColors.accent,
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AtlasRadius.sm),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AtlasColors.cardBg, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: dotColor.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AtlasColors.cardBorder,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16, top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            log.eventLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AtlasColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          df.format(log.timestamp),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AtlasColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        _Chip(label: log.eventType),
                        if (log.module.isNotEmpty)
                          _Chip(label: log.module, soft: true),
                        Text(
                          '· by ${log.actorDisplay}',
                          style: const TextStyle(
                            color: AtlasColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        if (isStaffAction)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AtlasColors.dangerSoft,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'STAFF',
                              style: TextStyle(
                                color: AtlasColors.danger,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool soft;
  const _Chip({required this.label, this.soft = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: soft ? const Color(0xFFF1F5F9) : AtlasColors.accentSoft,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: soft ? AtlasColors.textSecondary : AtlasColors.accentHover,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _DetailDialog extends StatelessWidget {
  final ActivityLog log;
  const _DetailDialog({required this.log});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy-MM-dd HH:mm:ss');
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Activity event detail',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AtlasColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _kv('Event ID', log.id, mono: true),
              _kv('Timestamp', fmt.format(log.timestamp)),
              _kv('Category', log.category),
              _kv('Module', log.module),
              _kv('Event type', log.eventType, mono: true),
              _kv('Label', log.eventLabel),
              _kv('Actor', log.actorDisplay),
              if (log.actorType != null) _kv('Actor type', log.actorType!),
              _kv('Target type', log.targetType),
              _kv('Target id', log.targetId, mono: true),
              if (log.targetDisplay != null)
                _kv('Target display', log.targetDisplay!),
              if (log.orgId != null) _kv('Org id', log.orgId!, mono: true),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _kv(String label, String value, {bool mono = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AtlasColors.textMuted,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value.isEmpty ? '—' : value,
            style: TextStyle(
              fontSize: 12.5,
              color: AtlasColors.textPrimary,
              fontFamily: mono ? 'monospace' : null,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(AtlasRadius.lg),
      ),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_outlined, size: 28, color: AtlasColors.textMuted),
          SizedBox(height: 8),
          Text('No activity matches the current filters.',
              style: AtlasText.smallMuted),
        ],
      ),
    );
  }
}
