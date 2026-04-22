import 'package:cloud_firestore/cloud_firestore.dart';

class HomeKpis {
  final int totalCustomers;
  final int customersLast7d;
  final int customersLast30d;
  final int activeStaff;
  final int openTickets;
  final int auditEventsToday;

  const HomeKpis({
    required this.totalCustomers,
    required this.customersLast7d,
    required this.customersLast30d,
    required this.activeStaff,
    required this.openTickets,
    required this.auditEventsToday,
  });
}

class HomeKpiService {
  HomeKpiService._();
  static final instance = HomeKpiService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<HomeKpis> fetch() async {
    final now = DateTime.now().toUtc();
    final startOfDay =
        DateTime.utc(now.year, now.month, now.day);
    final from7d = now.subtract(const Duration(days: 7));
    final from30d = now.subtract(const Duration(days: 30));

    // Run aggregation queries in parallel.
    final results = await Future.wait([
      _db.collection('organizations').count().get(),
      _db
          .collection('organizations')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(from7d))
          .count()
          .get(),
      _db
          .collection('organizations')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(from30d))
          .count()
          .get(),
      _db
          .collection('users')
          .where('isStaff', isEqualTo: true)
          .where('disabled', isEqualTo: false)
          .count()
          .get(),
      _db
          .collection('support_tickets')
          .where('status', whereIn: ['new', 'open'])
          .count()
          .get(),
      _db
          .collection('staff_audit_logs')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .count()
          .get(),
    ]);

    return HomeKpis(
      totalCustomers: results[0].count ?? 0,
      customersLast7d: results[1].count ?? 0,
      customersLast30d: results[2].count ?? 0,
      activeStaff: results[3].count ?? 0,
      openTickets: results[4].count ?? 0,
      auditEventsToday: results[5].count ?? 0,
    );
  }
}
