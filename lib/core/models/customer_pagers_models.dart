import 'package:cloud_firestore/cloud_firestore.dart';

/// Slim, read-only views over the customer-app's Pagers domain
/// (`AllTeams`, `Oncall_Schedules`, `escalation_policies`). Atlas only
/// surfaces the fields the support-snapshot UI needs.

class CustomerTeam {
  final String id;
  final String name;
  final String orgId;
  final String inboxAddress;
  final List<String> aliases;
  final List<String> memberIds;
  final String? description;

  CustomerTeam({
    required this.id,
    required this.name,
    required this.orgId,
    required this.inboxAddress,
    required this.aliases,
    required this.memberIds,
    this.description,
  });

  factory CustomerTeam.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return CustomerTeam(
      id: doc.id,
      name: (d['teamName'] as String?) ?? '(unnamed)',
      orgId: (d['orgId'] as String?) ?? '',
      inboxAddress: (d['inboxAddress'] as String?) ?? '',
      aliases:
          (d['aliases'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      memberIds: (d['membersList'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      description: d['description'] as String?,
    );
  }

  int get memberCount => memberIds.length;
}

class CustomerSchedule {
  final String id;
  final String teamId;
  final String teamName;
  final String scheduleName;
  final String date;
  final String startTime;
  final String endTime;
  final String rotation;
  final List<String> primaryNames; // resolved display names of primary on-call

  CustomerSchedule({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.scheduleName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.rotation,
    required this.primaryNames,
  });

  factory CustomerSchedule.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final primary = d['primaryEmpId'];
    final names = <String>[];
    if (primary is List) {
      for (final p in primary) {
        if (p is Map) {
          final name = p['name'] ?? p['fullName'] ?? p['email'];
          if (name != null) names.add(name.toString());
        }
      }
    }
    return CustomerSchedule(
      id: doc.id,
      teamId: (d['teamId'] as String?) ?? '',
      teamName: (d['teamName'] as String?) ?? '',
      scheduleName: (d['scheduleName'] as String?) ?? '',
      date: (d['date'] as String?) ?? '',
      startTime: (d['startTime'] as String?) ?? '',
      endTime: (d['endTime'] as String?) ?? '',
      rotation: (d['rotation'] as String?) ?? '',
      primaryNames: names,
    );
  }
}

class CustomerPolicy {
  final String id;
  final String name;
  final String teamId;
  final String? description;
  final bool isActive;
  final int levelCount;

  CustomerPolicy({
    required this.id,
    required this.name,
    required this.teamId,
    required this.isActive,
    required this.levelCount,
    this.description,
  });

  factory CustomerPolicy.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final levels = d['levels'];
    final levelCount = levels is List ? levels.length : 0;
    return CustomerPolicy(
      id: doc.id,
      name: (d['name'] as String?) ?? '(unnamed)',
      teamId: (d['teamId'] as String?) ?? '',
      isActive: d['isActive'] != false, // default-true if missing
      levelCount: levelCount,
      description: d['description'] as String?,
    );
  }
}
