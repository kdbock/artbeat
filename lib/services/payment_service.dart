import 'package:stripe_payment/stripe_payment.dart';
import '../core/constants/env.dart';
import 'dart:developer';

class PaymentService {
  PaymentService() {
    StripePayment.setOptions(
      StripeOptions(
        publishableKey: Env.stripePublishableKey,
        androidPayMode: 'test',
        merchantId: 'test',
      ),
    );
  }

  Future<void> processPayment({
    required String amount,
    required String currency,
  }) async {
    try {
      final paymentMethod = await StripePayment.paymentRequestWithCardForm(
        CardFormPaymentRequest(),
      );

      log('Payment method created: ${paymentMethod.id}');

      // Here you would typically send the paymentMethod.id to your backend
      // to create a PaymentIntent and confirm the payment.

      log('Payment processed successfully');
    } catch (e) {
      log('Error processing payment: $e');
      rethrow;
    }
  }
}