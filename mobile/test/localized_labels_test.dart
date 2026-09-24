import 'package:flutter_test/flutter_test.dart';
import 'package:lokal/models/models.dart';

void main() {
  test('order status labels are Estonian', () {
    expect(orderStatusLabel(OrderStatus.pending), 'Ootel');
    expect(orderStatusLabel(OrderStatus.accepted), 'Kinnitatud');
    expect(orderStatusLabel(OrderStatus.rejected), 'Tagasi lükatud');
  });

  test('role labels are Estonian', () {
    expect(roleLabel(UserRole.both), 'Ostja ja tootja');
  });

  test('unit labels are Estonian', () {
    expect(unitLabel(ProductUnit.piece), 'tk');
  });
}
