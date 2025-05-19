import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../assistantMethods/assistant_methods.dart';
import '../global/global.dart';
import '../widgets/order_card_design.dart';
import '../widgets/progress_bar.dart';
import '../widgets/simple_app_bar.dart';

class NewOrdersScreen extends StatefulWidget {
  const NewOrdersScreen({Key? key}) : super(key: key);

  @override
  _NewOrdersScreenState createState() => _NewOrdersScreenState();
}

class _NewOrdersScreenState extends State<NewOrdersScreen> {
  Future<void> processOrder(String orderId, String userId) async {
    try {
      // Get the current order data first
      final orderDoc = await FirebaseFirestore.instance
          .collection("orders")
          .doc(orderId)
          .get();
      
      if (!orderDoc.exists) {
        throw Exception("Order not found");
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      
      // Update order status to picking
      final batch = FirebaseFirestore.instance.batch();
      
      // Update in main orders collection
      final mainOrderRef = FirebaseFirestore.instance
          .collection("orders")
          .doc(orderId);
      
      // Update in user's orders collection
      final userOrderRef = FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("orders")
          .doc(orderId);

      final updateData = {
        'status': 'picking',
        'lastUpdated': FieldValue.serverTimestamp(),
        'sellerUID': sharedPreferences!.getString("uid"),
        'sellerName': sharedPreferences!.getString("name"),
        'orderTime': orderData["orderTime"],
        'totalAmount': orderData["totalAmount"],
        'productIDs': orderData["productIDs"],
        'addressID': orderData["addressID"],
        'orderBy': orderData["orderBy"],
        'paymentDetails': orderData["paymentDetails"],
        'isSuccess': true,
      };

      batch.update(mainOrderRef, updateData);
      batch.update(userOrderRef, updateData);

      await batch.commit();

      if (mounted) {
        Fluttertoast.showToast(
          msg: "Order is now being prepared",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      print("Error processing order: $e");
      if (mounted) {
        Fluttertoast.showToast(
          msg: "Error processing order: $e",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String? sellerUID = sharedPreferences!.getString("uid");
    print("📦 Seller UID for New Orders: $sellerUID");

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: SimpleAppBar(title: "New Orders"),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: FractionalOffset(-2.0, 0.0),
            end: FractionalOffset(5.0, -1.0),
            colors: [Color(0xFFFFFFFF), Color(0xFFFAC898)],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("orders")
              .where("sellerUID", isEqualTo: sellerUID)
              .where("status", whereIn: ["order placed", "picking", "delivering", "ended"])
              .orderBy("orderTime", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              print("📡 Waiting for new orders...");
              return Center(child: circularProgress());
            }

            if (snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 100,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No Active Orders",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "New orders will appear here",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> orderData =
                    snapshot.data!.docs[index].data()! as Map<String, dynamic>;

                List<String> productIDs = separateOrderItemIDs(
                  orderData["productIDs"],
                );
                List<String> quantities = separateOrderItemQuantities(
                  orderData["productIDs"],
                );

                print("🛒 Order ${index + 1} productIDs: $productIDs");

                return FutureBuilder<QuerySnapshot>(
                  future:
                      FirebaseFirestore.instance
                          .collection("items")
                          .where("itemID", whereIn: productIDs)
                          .where("sellerUID", isEqualTo: sellerUID)
                          .orderBy("publishedDate", descending: true)
                          .get(),
                  builder: (context, itemSnapshot) {
                    if (!itemSnapshot.hasData) {
                      return Center(child: circularProgress());
                    }

                    // Get the userId (orderBy) from orderData
                    final userId = orderData["orderBy"] ?? "";
                    final orderId = snapshot.data!.docs[index].id;
                    final orderStatus = orderData["status"] ?? "order placed";

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getStatusColor(orderStatus).withOpacity(0.1),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _getStatusIcon(orderStatus),
                                      color: _getStatusColor(orderStatus),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getStatusText(orderStatus),
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _getStatusColor(orderStatus),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  orderData["orderTime"] != null 
                                      ? DateFormat("dd MMM yyyy, hh:mm a").format(
                                          DateTime.fromMillisecondsSinceEpoch(
                                              int.parse(orderData["orderTime"].toString())))
                                      : "N/A",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OrderCardDesign(
                            itemCount: itemSnapshot.data!.docs.length,    
                            data: itemSnapshot.data!.docs,
                            orderID: orderId,
                            seperateQuantitiesList: quantities,
                            userId: userId,
                          ),
                          if (orderStatus == "order placed")
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: ElevatedButton.icon(
                                onPressed: () => processOrder(orderId, userId),
                                icon: const Icon(Icons.check_circle_outline),
                                label: Text(
                                  "Start Preparing Order",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "order placed":
        return Colors.orange;
      case "picking":
        return Colors.blue;
      case "delivering":
        return Colors.purple;
      case "ended":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case "order placed":
        return Icons.shopping_cart;
      case "picking":
        return Icons.inventory_2;
      case "delivering":
        return Icons.delivery_dining;
      case "ended":
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case "order placed":
        return "New Order";
      case "picking":
        return "Preparing";
      case "delivering":
        return "On the Way";
      case "ended":
        return "Delivered";
      default:
        return "Processing";
    }
  }

  List<String> separateOrderItemIDs(dynamic productIDs) {
    if (productIDs is List) {
      return productIDs.map((e) {
        if (e is String && e.contains(":")) {
          return e.split(":")[0]; // itemID
        }
        return e.toString();
      }).toList();
    }
    return [];
  }

  List<String> separateOrderItemQuantities(dynamic productIDs) {
    if (productIDs is List) {
      return productIDs.map((e) {
        if (e is String && e.contains(":")) {
          return e.split(":")[1]; // quantity
        }
        return "1"; // default quantity
      }).toList();
    }
    return [];
  }
}
