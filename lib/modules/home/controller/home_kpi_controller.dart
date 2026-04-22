import 'package:get/get.dart';

import '../services/home_kpi_service.dart';

class HomeKpiController extends GetxController {
  final _svc = HomeKpiService.instance;

  final Rxn<HomeKpis> kpis = Rxn<HomeKpis>();
  final RxBool loading = false.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload() async {
    loading.value = true;
    error.value = null;
    try {
      kpis.value = await _svc.fetch();
    } catch (e) {
      error.value = 'Failed to load KPIs: $e';
    } finally {
      loading.value = false;
    }
  }
}
