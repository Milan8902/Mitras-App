import 'package:esewa_flutter_sdk/esewa_config.dart';
import 'package:esewa_flutter_sdk/esewa_flutter_sdk.dart';
import 'package:esewa_flutter_sdk/esewa_payment.dart';
import 'package:esewa_flutter_sdk/esewa_payment_success_result.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:users_food_app/esewa_id.dart';

class EsewaRepository {
  pay(String id, String name, String price, Function(String, Color) onsucess) {
    try {
      EsewaFlutterSdk.initPayment(
        esewaConfig: EsewaConfig(
          environment: Environment.test,
          clientId: EsewaId.esewaClientId,
          secretId: EsewaId.esewaSecretKey,
        ),
        esewaPayment: EsewaPayment(
          productId: id,
          productName: name,
          productPrice: price,
          callbackUrl: "",
        ),
        onPaymentSuccess: (EsewaPaymentSuccessResult paymentResult) {
          print("Sucess");
          onsucess("payment successful for $name", Colors.green);
          verify(paymentResult);
        },
        onPaymentFailure: () {
          print("transaction failure");
          onsucess("payment failure for $name", Colors.red);
        },
        onPaymentCancellation: () {
          onsucess("payment cancelled for $name", Colors.red);
          print("payment cancelled");
        },
      );
    } catch (e) {}
  }

  verify(EsewaPaymentSuccessResult paymentResult) {
    // after sucess call this function to verify the transction
  }
}
