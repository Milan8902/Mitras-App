// ignore_for_file: non_constant_identifier_names, avoid_types_as_parameter_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/address.dart';
import '../widgets/progress_bar.dart';
import '../widgets/shipment_address_design.dart';
import '../widgets/status_banner.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String? orderID;

  const OrderDetailsScreen({Key? key, this.orderID}) : super(key: key);

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  String orderStatus = "";
  String orderByUser = "";
  String sellerId = "";

  getOrderInfo() {
    FirebaseFirestore.instance
        .collection("orders")
        .doc(widget.orderID)
        .get()
        .then((DocumentSnapshot) {
      if (DocumentSnapshot.exists && DocumentSnapshot.data() != null) {
        setState(() {
          orderStatus = DocumentSnapshot.data()!["status"]?.toString() ?? "";
          orderByUser = DocumentSnapshot.data()!["orderBy"]?.toString() ?? "";
          sellerId = DocumentSnapshot.data()!["sellerUID"]?.toString() ?? "";
        });
      }
    });
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
              Map<String, dynamic>? dataMap;
              if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                dataMap = snapshot.data!.data() as Map<String, dynamic>?;
                if (dataMap != null) {
                  orderStatus = dataMap["status"]?.toString() ?? "";
                }
              }
              return snapshot.hasData && dataMap != null
                  ? Column(
                      children: [
                        StatusBanner(
                          status: dataMap["isSuccess"] ?? false,
                          orderStatus: orderStatus,
                        ),
                        const SizedBox(
                          height: 10.0,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "RS  ${dataMap["totalAmount"]?.toString() ?? "0"}",
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
                            "Order Id = ${widget.orderID ?? "N/A"}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Order at: ${dataMap["orderTime"] != null ? DateFormat("dd MMMM, yyyy - hh:mm aa").format(
                                DateTime.fromMillisecondsSinceEpoch(
                                    int.parse(dataMap["orderTime"].toString()))) : "N/A"}",
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                        ),
                        const Divider(
                          thickness: 4,
                        ),
                        // User Information Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Customer Information",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection("users")
                                    .doc(orderByUser)
                                    .get(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                                    final userData = snapshot.data!.data() as Map<String, dynamic>?;
                                    if (userData != null) {
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildInfoRow("Name", userData["userName"] ?? "N/A"),
                                          const SizedBox(height: 8),
                                          _buildInfoRow("Email", userData["userEmail"] ?? "N/A"),
                                          const SizedBox(height: 8),
                                          _buildInfoRow("Phone", userData["userPhone"] ?? "N/A"),
                                        ],
                                      );
                                    }
                                  }
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        orderStatus != "ended"
                            ? Image.asset("images/packing.png")
                            : Image.asset("images/delivered.jpg"),
                        const Divider(
                          thickness: 4,
                        ),
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection("users")
                              .doc(orderByUser)
                              .collection("userAddress")
                              .doc(dataMap["addressID"]?.toString())
                              .get(),
                          builder: (c, snapshot) {
                            if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                              final addressData = snapshot.data!.data() as Map<String, dynamic>?;
                              if (addressData != null) {
                                return ShipmentAddressDesign(
                                  model: Address.fromJson(addressData),
                                  orderStatus: orderStatus,
                                  orderId: widget.orderID,
                                  sellerId: sellerId,
                                  orderByUser: orderByUser,
                                );
                              }
                            }
                            return Center(
                              child: circularProgress(),
                            );
                          },
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            "$label:",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
