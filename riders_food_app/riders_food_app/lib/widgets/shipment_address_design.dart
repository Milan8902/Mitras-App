import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riders_food_app/assistantMethods/get_current_location.dart';
import 'package:riders_food_app/screens/parcel_picking_screen.dart';
import 'package:riders_food_app/screens/home_screen.dart';

import '../global/global.dart';
import '../models/address.dart';

class ShipmentAddressDesign extends StatelessWidget {
  final Address? model;
  final String? orderStatus;
  final String? orderId;
  final String? sellerId;
  final String? orderByUser;

  const ShipmentAddressDesign({
    Key? key,
    this.model,
    this.orderStatus,
    this.orderId,
    this.sellerId,
    this.orderByUser,
  }) : super(key: key);

  confirmedParcelShipment(BuildContext context, String getOrderID,
      String sellerId, String purchaserId) {
    FirebaseFirestore.instance.collection("orders").doc(getOrderID).update(
      {
        "riderUID": sharedPreferences!.getString("uid"),
        "riderName": sharedPreferences!.getString("name"),
        "status": "picking",
        "lat": position!.latitude,
        "lng": position!.longitude,
        "address": completeAddress,
      },
    );

    // send rider to shipment screen

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: ((context) => ParcelPickingScreen(
              purchaserId: purchaserId,
              purchaserAddress: model!.fullAddress,
              purchaserLat: model!.lat,
              purchaserLng: model!.lng,
              sellerId: sellerId,
              getOrderID: getOrderID,
            )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            "Shipping Details: ",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 90, vertical: 5),
          width: MediaQuery.of(context).size.width,
          child: Table(
            children: [
              TableRow(
                children: [
                  Text(
                    "-Name",
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    model!.name!,
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  Text(
                    "-Phone Number",
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    model!.phoneNumber!,
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            model!.fullAddress!,
            textAlign: TextAlign.justify,
            style: GoogleFonts.poppins(
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ),
        orderStatus == "ended"
            ? Container()
            : Padding(
                padding: const EdgeInsets.all(10.0),
                child: Center(
                  child: InkWell(
                    onTap: () {
                      UserLocation uLocation = UserLocation();
                      uLocation.getCurrenLocation();

                      confirmedParcelShipment(
                        context,
                        orderId!,
                        sellerId!,
                        orderByUser!,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF004B8D),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      width: MediaQuery.of(context).size.width - 40,
                      height: 50,
                      child: Center(
                        child: Text(
                          "Confirm - To Deliver this Parcel",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Center(
            child: InkWell(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF004B8D),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                width: MediaQuery.of(context).size.width - 40,
                height: 50,
                child: Center(
                  child: Text(
                    "Go back",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

