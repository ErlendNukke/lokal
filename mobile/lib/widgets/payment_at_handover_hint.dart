import 'package:flutter/material.dart';
import 'package:lokal/theme/app_theme.dart';

/// Muted helper text for the cash-at-handover payment model.
class PaymentAtHandoverHint extends StatelessWidget {
  const PaymentAtHandoverHint({super.key, required this.text});

  final String text;

  static const TextStyle style = TextStyle(
    color: LokalColors.muted,
    fontSize: 13,
    height: 1.35,
  );

  @override
  Widget build(BuildContext context) {
    return Text(text, style: style);
  }
}
