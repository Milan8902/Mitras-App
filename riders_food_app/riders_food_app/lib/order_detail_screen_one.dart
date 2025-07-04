// ignore_for_file: non_constant_identifier_names, avoid_types_as_parameter_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:riders_food_app/shipmentAddressDesignOne.dart';

import '../models/address.dart';
import '../widgets/progress_bar.dart';
import '../widgets/shipment_address_design.dart';
import '../widgets/status_banner.dart';

class OrderDetailScreenOne extends StatefulWidget {
  final String? orderID;

  const OrderDetailScreenOne({Key? key, this.orderID}) : super(key: key);

  @override
  State<OrderDetailScreenOne> createState() => _OrderDetailScreenOneState();
}

class _OrderDetailScreenOneState extends State<OrderDetailScreenOne> {
  String orderStatus = "";
  String orderByUser = "";
  String sellerId = "";

  Future<void> getOrderInfo() async {
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .collection("orders")
        .doc(widget.orderID)
        .get();
    
    if (mounted) {
      setState(() {
        Map<String, dynamic> data = documentSnapshot.data()! as Map<String, dynamic>;
        orderStatus = data["status"].toString();
        orderByUser = data["orderBy"].toString();
        sellerId = data["sellerUID"].toString();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getOrderInfo();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection("orders")
                .doc(widget.orderID)
                .get(),
            builder: (c, snapshot) {
              Map? dataMap;
              if (snapshot.hasData) {
                dataMap = snapshot.data!.data()! as Map<String, dynamic>;
                orderStatus = dataMap["status"].toString();
                orderByUser = dataMap["orderBy"].toString();
                sellerId = dataMap["sellerUID"].toString();
              }
              return snapshot.hasData
                  ? Column(
                      children: [
                        StatusBanner(
                          status: dataMap!["isSuccess"],
                          orderStatus: orderStatus,
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Total Amount: "
                                      "\$ " +
                                  dataMap["totalAmount"].toString(),
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
                            "Order ID: " + widget.orderID!,
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
                        orderByUser.isNotEmpty
                            ? FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection("users")
                                    .doc(orderByUser)
                                    .collection("userAddress")
                                    .doc(dataMap["addressID"])
                                    .get(),
                                builder: (c, snapshot) {
                                  return snapshot.hasData
                                      ? ShipmentaddressdesignOne(
                                          model: Address.fromJson(snapshot.data!
                                              .data()! as Map<String, dynamic>),
                                          orderStatus: orderStatus,
                                          orderId: widget.orderID,
                                          sellerId: sellerId,
                                          orderByUser: orderByUser,
                                        )
                                      : Center(
                                          child: circularProgress(),
                                        );
                                },
                              )
                            : const Center(
                                child: Text("Loading address information..."),
                              ),
                      ],
                    )
                  : Center(
                      child: circularProgress(),
                    );
            },
          ),
        ),
      ),
    );
  }
}
