import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lokal/copy/order_payment_copy.dart';
import 'package:lokal/widgets/payment_at_handover_hint.dart';

void main() {
  testWidgets('PaymentAtHandoverHint shows order section copy', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PaymentAtHandoverHint(text: OrderPaymentCopy.orderSectionHint),
        ),
      ),
    );

    expect(find.text(OrderPaymentCopy.orderSectionHint), findsOneWidget);
  });
}
