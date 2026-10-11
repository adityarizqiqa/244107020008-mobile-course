import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/routes.dart';

void main() {
  test('App smoke test for route parsing', () {
    expect(routeFromMessage({'route': '/login'}), '/login');
  });
}
