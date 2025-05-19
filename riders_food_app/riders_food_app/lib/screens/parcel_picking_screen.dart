// ignore_for_file: avoid_types_as_parameter_names, must_be_immutable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:riders_food_app/assistantMethods/get_current_location.dart';
import 'package:riders_food_app/global/global.dart';
import 'package:riders_food_app/maps/map_utils.dart';
import 'package:riders_food_app/screens/home_screen.dart';
import 'package:riders_food_app/screens/parcel_delivering_screen.dart';

class ParcelPickingScreen extends StatefulWidget {
  String? purchaserId;
  String? sellerId;
  String? getOrderID;
  String? purchaserAddress;
  double? purchaserLat;
  double? purchaserLng;

  ParcelPickingScreen({
    Key? key,
    this.purchaserId,
    this.sellerId,
    this.getOrderID,
    this.purchaserAddress,
    this.purchaserLat,
    this.purchaserLng,
  }) : super(key: key);

  @override
  _ParcelPickingScreenState createState() => _ParcelPickingScreenState();
}

class _ParcelPickingScreenState extends State<ParcelPickingScreen> {
  double? sellerLat, sellerLng;

  //we get restaurants location by this method
  getSellerData() async {
    FirebaseFirestore.instance.collection("sellers").doc(widget.sellerId).get()
    // ignore: non_constant_identifier_names
    .then((DocumentSnapshot) {
      sellerLat = DocumentSnapshot.data()!["lat"];
      sellerLng = DocumentSnapshot.data()!["lng"];
    });
  }

  @override
  void initState() {
    super.initState();

    getSellerData();
  }

  // updating status and comfirming order has picked
  Future<void> confirmParcelHasBeenPicked(
    getOrderId,
    sellerId,
    purchaserId,
    purchaserAddress,
    purchaserLat,
    purchaserLng,
  ) async {
    try {
      // Get current location first
      UserLocation uLocation = UserLocation();
      await uLocation.getCurrenLocation();

      // Wait for position to be available
      if (position == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait for location to be updated'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Update order status
      await FirebaseFirestore.instance.collection("orders").doc(getOrderId).update({
        "status": "delivering",
        "address": completeAddress,
        "lat": position!.latitude,
        "lng": position!.longitude,
        "riderUID": sharedPreferences!.getString("uid"),
      });

      // Navigate to delivering screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (c) => ParcelDeliveringScreen(
              purchaserId: purchaserId,
              purchaserAddress: purchaserAddress,
              purchaserLat: purchaserLat,
              purchaserLng: purchaserLng,
              sellerId: sellerId,
              getOrderId: getOrderId,
            ),
          ),
        );
      }
    } catch (e) {
      print("Error confirming parcel pickup: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error confirming pickup. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset("images/confirm1.png", width: 350),
          const SizedBox(height: 5),
          GestureDetector(
            onTap: () {
              // show location from rider current location towards seller location
              if (position != null && sellerLat != null && sellerLng != null) {
                MapUtils.launchMapFromSourceToDestination(
                  position!.latitude,
                  position!.longitude,
                  sellerLat,
                  sellerLng,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please wait for location to be updated'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
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
                      "Show Cafe/Restaurant Location",
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
                onTap: () async {
                  // confirm that rider has picked order
                  await confirmParcelHasBeenPicked(
                    widget.getOrderID,
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
                      "Confirmed",
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
