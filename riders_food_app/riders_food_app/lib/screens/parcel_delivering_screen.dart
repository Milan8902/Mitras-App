import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:riders_food_app/screens/home_screen.dart';
import 'package:riders_food_app/splash_screen/splash_screen.dart';

import '../assistantMethods/get_current_location.dart';
import '../global/global.dart';
import '../maps/map_utils.dart';

// ignore: must_be_immutable
class ParcelDeliveringScreen extends StatefulWidget {
  String? purchaserId;
  String? purchaserAddress;
  double? purchaserLat;
  double? purchaserLng;
  String? sellerId;
  String? getOrderId;

  ParcelDeliveringScreen({
    Key? key,
    this.purchaserId,
    this.purchaserAddress,
    this.purchaserLat,
    this.purchaserLng,
    this.sellerId,
    this.getOrderId,
  }) : super(key: key);
  @override
  _ParcelDeliveringScreenState createState() => _ParcelDeliveringScreenState();
}

class _ParcelDeliveringScreenState extends State<ParcelDeliveringScreen> {
  String orderTotalAmount = "";

  // updating status and comfirming order has picked
  confirmParcelHasBeenDelivered(
    getOrderId,
    sellerId,
    purchaserId,
    purchaserAddress,
    purchaserLat,
    purchaserLng,
  ) {
    String riderNewTotalEarningAmount =
        ((double.parse(previousRiderEarnings) +
                double.parse(perParcelDeliveryAmount)))
            .toString();

    FirebaseFirestore.instance
        .collection("orders")
        .doc(getOrderId)
        .update({
          "status": "ended",
          "address": completeAddress,
          "lat": position!.latitude,
          "lng": position!.longitude,
          "earnings": perParcelDeliveryAmount, //pay per delivery
        })
        .then((value) {
          FirebaseFirestore.instance
              .collection("riders")
              .doc(sharedPreferences!.getString("uid"))
              .update({
                "earnings":
                    riderNewTotalEarningAmount, //total earnings of rider
              });
        })
        .then((value) {
          FirebaseFirestore.instance
              .collection("sellers")
              .doc(widget.sellerId)
              .update({
                "earnings":
                    (double.parse(orderTotalAmount) +
                            (double.parse(previousEarnings)))
                        .toString(), // total earnings of seller
              });
        })
        .then((value) {
          FirebaseFirestore.instance
              .collection("users")
              .doc(purchaserId)
              .collection("orders")
              .doc(getOrderId)
              .update({
                "status": "ended",
                "riderUID": sharedPreferences!.getString("uid"),
              });
        });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen()),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order has been Delivered'),
        backgroundColor: Colors.green,
      ),
    );
  }

  //retrieve order total amount
  Future<void> getOrderTotalAmount() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection("orders")
          .doc(widget.getOrderId)
          .get();
      
      if (snap.exists && snap.data() != null) {
        setState(() {
          orderTotalAmount = snap.data()!["totalAmount"].toString();
          widget.sellerId = snap.data()!["sellerUID"].toString();
        });
        await getSellerData();
      }
    } catch (e) {
      print("Error getting order total amount: $e");
    }
  }

  Future<void> getSellerData() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection("sellers")
          .doc(widget.sellerId)
          .get();
      
      if (snap.exists && snap.data() != null) {
        setState(() {
          previousEarnings = snap.data()!["earnings"].toString();
        });
      }
    } catch (e) {
      print("Error getting seller data: $e");
    }
  }

  @override
  void initState() {
    super.initState();

    //rider location updates
    UserLocation uLocation = UserLocation();
    uLocation.getCurrenLocation();

    getOrderTotalAmount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset("images/confirm2.png"),
          const SizedBox(height: 5),
          GestureDetector(
            onTap: () {
              // show location from rider current location towards seller location
              MapUtils.launchMapFromSourceToDestination(
                position!.latitude,
                position!.longitude,
                widget.purchaserLat,
                widget.purchaserLng,
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("images/restaurant.png", width: 50),
                const SizedBox(width: 7),
                Column(
                  children: const [
                    SizedBox(height: 12),
                    Text(
                      "Show Drop-off Location",
                      style: TextStyle(
                        fontFamily: "Signatra",
                        fontSize: 20,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Center(
              child: InkWell(
                onTap: () {
                  // confirm that rider has picked order
                  //rider location updates
                  UserLocation uLocation = UserLocation();
                  uLocation.getCurrenLocation();

                  confirmParcelHasBeenDelivered(
                    widget.getOrderId,
                    widget.sellerId,
                    widget.purchaserId,
                    widget.purchaserAddress,
                    widget.purchaserLat,
                    widget.purchaserLng,
                  );
                },
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: FractionalOffset(0.0, 0.0),
                      end: FractionalOffset(3.0, -1.0),
                      colors: [Color(0xFF004B8D), Color(0xFFffffff)],
                    ),
                  ),
                  width: MediaQuery.of(context).size.width - 90,
                  height: 50,
                  child: const Center(
                    child: Text(
                      "Confirmation of delivery",
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
