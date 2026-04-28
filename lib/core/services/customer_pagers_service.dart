import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/customer_pagers_models.dart';

/// Read-only access to the customer-app Pagers collections used by the
/// snapshot sub-tabs (Teams, Schedules, Policies). Schedules and Policies
/// are scoped to a team — we resolve the org→team list first then fan out.
class CustomerPagersService {
  CustomerPagersService._();
  static final instance = CustomerPagersService._();

  final _db = FirebaseFirestore.instance;

  /// All teams under an org. Used by the Teams snapshot sub-tab and as the
  /// scope for Schedules/Policies queries.
  Stream<List<CustomerTeam>> watchTeams(String orgId) {
    return _db
        .collection('AllTeams')
        .where('orgId', isEqualTo: orgId)
        .snapshots()
        .map((s) => s.docs.map(CustomerTeam.fromDoc).toList());
  }

  /// Convenience future-form of `watchTeams` — used when callers only need
  /// a single read (e.g. to seed the Schedules query).
  Future<List<CustomerTeam>> getTeams(String orgId) async {
    final s = await _db
        .collection('AllTeams')
        .where('orgId', isEqualTo: orgId)
        .get();
    return s.docs.map(CustomerTeam.fromDoc).toList();
  }

  /// Schedules currently in effect for an org. Returns up to `limit` rows
  /// (Firestore `whereIn` caps team-id batches at 30, so we chunk).
  Future<List<CustomerSchedule>> getSchedulesForOrg({
    required String orgId,
    int limit = 30,
  }) async {
    final teams = await getTeams(orgId);
    if (teams.isEmpty) return const [];
    final teamIds = teams.map((t) => t.id).toList();
    final chunks = <List<String>>[];
    for (var i = 0; i < teamIds.length; i += 30) {
      chunks.add(
          teamIds.sublist(i, i + 30 > teamIds.length ? teamIds.length : i + 30));
    }
    final all = <CustomerSchedule>[];
    for (final chunk in chunks) {
      final s = await _db
          .collection('Oncall_Schedules')
          .where('teamId', whereIn: chunk)
          .limit(limit)
          .get();
      all.addAll(s.docs.map(CustomerSchedule.fromDoc));
      if (all.length >= limit) break;
    }
    return all;
  }

  /// Active escalation policies for an org. Same chunk-by-30 pattern.
  Future<List<CustomerPolicy>> getPoliciesForOrg(String orgId) async {
    final teams = await getTeams(orgId);
    if (teams.isEmpty) return const [];
    final teamIds = teams.map((t) => t.id).toList();
    final chunks = <List<String>>[];
    for (var i = 0; i < teamIds.length; i += 30) {
      chunks.add(
          teamIds.sublist(i, i + 30 > teamIds.length ? teamIds.length : i + 30));
    }
    final all = <CustomerPolicy>[];
    for (final chunk in chunks) {
      final s = await _db
          .collection('escalation_policies')
          .where('teamId', whereIn: chunk)
          .get();
      all.addAll(s.docs.map(CustomerPolicy.fromDoc));
    }
    return all;
  }

  /// Aggregates the org's notification channels (phone numbers, emails)
  /// from team inboxes / aliases AND escalation-policy NotifyTargets.
  ///
  /// Channels live in two places in the customer-app schema:
  ///   • email inboxes: `AllTeams.inboxAddress` + `AllTeams.aliases[]`
  ///   • per-target email/phone: `escalation_policies.levels[].targets[]`
  /// We resolve both, dedupe, and return one bundle per kind.
  Future<CustomerChannelsBundle> getChannelsForOrg(String orgId) async {
    final teams = await getTeams(orgId);
    if (teams.isEmpty) {
      return const CustomerChannelsBundle(
        inboxes: [],
        phones: [],
        personEmails: [],
      );
    }

    final inboxes = <CustomerInboxChannel>[];
    for (final t in teams) {
      if (t.inboxAddress.isNotEmpty) {
        inboxes.add(CustomerInboxChannel(
          email: t.inboxAddress,
          teamName: t.name,
          isAlias: false,
        ));
      }
      for (final alias in t.aliases) {
        if (alias.isNotEmpty) {
          inboxes.add(CustomerInboxChannel(
            email: alias,
            teamName: t.name,
            isAlias: true,
          ));
        }
      }
    }

    final teamIds = teams.map((t) => t.id).toList();
    final chunks = <List<String>>[];
    for (var i = 0; i < teamIds.length; i += 30) {
      chunks.add(
          teamIds.sublist(i, i + 30 > teamIds.length ? teamIds.length : i + 30));
    }

    final phonesSeen = <String, CustomerPhoneChannel>{};
    final personEmailsSeen = <String, CustomerPersonEmailChannel>{};
    final teamNameById = {for (final t in teams) t.id: t.name};

    for (final chunk in chunks) {
      final snap = await _db
          .collection('escalation_policies')
          .where('teamId', whereIn: chunk)
          .get();

      for (final doc in snap.docs) {
        final d = doc.data();
        final policyName = (d['name'] as String?) ?? '(unnamed policy)';
        final teamId = (d['teamId'] as String?) ?? '';
        final teamName = teamNameById[teamId] ?? teamId;
        final levels = d['levels'];
        if (levels is! List) continue;

        for (var i = 0; i < levels.length; i++) {
          final level = levels[i];
          if (level is! Map) continue;
          final targets = level['targets'];
          if (targets is! List) continue;

          for (final raw in targets) {
            if (raw is! Map) continue;
            final t = Map<String, dynamic>.from(raw);
            final name = (t['name'] as String?) ?? '';
            final email = (t['email'] as String?) ?? '';
            final phone = (t['phone'] as String?) ?? '';
            final cc = (t['countryCode'] as String?) ?? '';
            final fullPhone =
                phone.isEmpty ? '' : (cc.isEmpty ? phone : '$cc $phone');

            if (fullPhone.isNotEmpty) {
              phonesSeen.putIfAbsent(
                fullPhone,
                () => CustomerPhoneChannel(
                  phone: fullPhone,
                  ownerName: name,
                  teamName: teamName,
                  policyName: policyName,
                  level: i + 1,
                ),
              );
            }
            if (email.isNotEmpty) {
              personEmailsSeen.putIfAbsent(
                email,
                () => CustomerPersonEmailChannel(
                  email: email,
                  ownerName: name,
                  teamName: teamName,
                  policyName: policyName,
                  level: i + 1,
                ),
              );
            }
          }
        }
      }
    }

    return CustomerChannelsBundle(
      inboxes: inboxes,
      phones: phonesSeen.values.toList(),
      personEmails: personEmailsSeen.values.toList(),
    );
  }
}

/// Aggregated channel inventory for an org.
class CustomerChannelsBundle {
  final List<CustomerInboxChannel> inboxes;
  final List<CustomerPhoneChannel> phones;
  final List<CustomerPersonEmailChannel> personEmails;
  const CustomerChannelsBundle({
    required this.inboxes,
    required this.phones,
    required this.personEmails,
  });

  bool get isEmpty =>
      inboxes.isEmpty && phones.isEmpty && personEmails.isEmpty;
}

class CustomerInboxChannel {
  final String email;
  final String teamName;
  final bool isAlias;
  const CustomerInboxChannel({
    required this.email,
    required this.teamName,
    required this.isAlias,
  });
}

class CustomerPhoneChannel {
  final String phone;
  final String ownerName;
  final String teamName;
  final String policyName;
  final int level;
  const CustomerPhoneChannel({
    required this.phone,
    required this.ownerName,
    required this.teamName,
    required this.policyName,
    required this.level,
  });
}

class CustomerPersonEmailChannel {
  final String email;
  final String ownerName;
  final String teamName;
  final String policyName;
  final int level;
  const CustomerPersonEmailChannel({
    required this.email,
    required this.ownerName,
    required this.teamName,
    required this.policyName,
    required this.level,
  });
}
