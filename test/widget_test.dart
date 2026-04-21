import 'package:flutter_test/flutter_test.dart';

import 'package:pagentz_atlas/core/models/staff_user_model.dart';

void main() {
  test('StaffRole round-trips through string form', () {
    for (final role in StaffRole.values) {
      expect(StaffRoleX.fromString(role.value), role);
    }
  });
}
