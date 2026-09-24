/// In-app copy for the cash-at-handover payment model (no in-app payments).
abstract final class OrderPaymentCopy {
  static const orderSectionHint =
      'Maksad tootjale kohapeal – järeletulemisel või kohaletoimetamisel.';

  static const orderConfirmation =
      'Tellimus saadetud tootjale. Maksad tootjale kohapeal kättesaamisel.';

  static const buyerOrderPaymentLine = 'Tasumine kohapeal';

  static const producerOrderPaymentHint = 'Ostja maksab kohapeal kättesaamisel.';
}
