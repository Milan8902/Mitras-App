import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:users_food_app/models/address.dart';
import 'package:users_food_app/widgets/design/shipment_address_design.dart';
import 'package:users_food_app/widgets/progress_bar.dart';
import 'package:users_food_app/widgets/status_banner.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:users_food_app/assistantMethods/order_status_helper.dart';
import 'package:google_fonts/google_fonts.dart';

import '../global/global.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String? orderID;

  const OrderDetailsScreen({Key? key, this.orderID}) : super(key: key);

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  String orderStatus = "";

  Future<void> _markOrderAsReceived() async {
    if (widget.orderID == null || widget.orderID!.isEmpty) {
      Fluttertoast.showToast(
        msg: "Error: Invalid order ID",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    try {
      await OrderStatusHelper.updateOrderStatus(
        orderId: widget.orderID!,
        status: 'received',
      );
      
      setState(() {
        orderStatus = 'received';
      });

      Fluttertoast.showToast(
        msg: "Order marked as received!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection("orders")
              .doc(widget.orderID)
              .get(),
          builder: (c, snapshot) {
            Map<String, dynamic>? dataMap;
            if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
              dataMap = snapshot.data!.data() as Map<String, dynamic>?;
              if (dataMap != null) {
                orderStatus = dataMap["status"]?.toString() ?? "";
              }
            }
            return snapshot.hasData && dataMap != null
                ? Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: const FractionalOffset(0.0, 0.0),
                        end: const FractionalOffset(1.0, 0.0),
                        colors: [
                          const Color(0xFFFFA53E).withOpacity(0.2),
                          const Color(0xFFFFA53E).withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatusBanner(
                          status: dataMap["isSuccess"] ?? false,
                          orderStatus: orderStatus,
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              "₹ ${dataMap["totalAmount"]}",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Order ID = ${widget.orderID}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            DateFormat("dd MMMM yy \n     hh:mm aa").format(
                              DateTime.fromMillisecondsSinceEpoch(
                                int.parse(dataMap["orderTime"]),
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const Divider(thickness: 4),
                        orderStatus == "ended"
                            ? Image.asset(
                                "images/success.jpg",
                                height: 300,
                                width: 300,
                              )
                            : Image.asset(
                                "images/confirm_pick.png",
                                height: 300,
                                width: 300,
                              ),
                        const Divider(thickness: 4),
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection("users")
                              .doc(dataMap?["orderBy"]?.toString())
                              .collection("userAddress")
                              .doc(dataMap?["addressID"]?.toString())
                              .get(),
                          builder: (c, snapshot) {
                            return snapshot.hasData
                                ? ShipmentAddressDesign(
                                    model: Address.fromJson(
                                      snapshot.data!.data()! as Map<String, dynamic>,
                                    ),
                                    orderStatus: orderStatus,
                                    orderId: widget.orderID,
                                    sellerId: dataMap?["sellerUID"]?.toString(),
                                    orderByUser: dataMap?["orderBy"]?.toString(),
                                  )
                                : Center(
                                    child: circularProgress(),
                                  );
                          },
                        ),
                        if (orderStatus == "ended")
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Divider(thickness: 1, height: 1, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  "Has your order been delivered?",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _markOrderAsReceived,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF57C00),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.check_circle_outline, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Confirm Order Received",
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  )
                : Center(
                    child: circularProgress(),
                  );
          },
        ),
      ),
    );
  }
}
