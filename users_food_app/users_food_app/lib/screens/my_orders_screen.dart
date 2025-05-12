import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:users_food_app/assistantMethods/assistant_methods.dart';
import 'package:users_food_app/global/global.dart';
import 'package:users_food_app/widgets/design/order_card_design.dart';
import 'package:users_food_app/widgets/progress_bar.dart';
import 'package:users_food_app/widgets/simple_app_bar.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({Key? key}) : super(key: key);

  @override
  _MyOrdersScreenState createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: SimpleAppBar(title: "My Orders"),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: FractionalOffset(-2.0, 0.0),
            end: FractionalOffset(5.0, -1.0),
            colors: [Color(0xFFFFFFFF), Color(0xFFFAC898)],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection("users")
                  .doc(sharedPreferences!.getString("uid"))
                  .collection("orders")
                  .where(
                    "status",
                    whereIn: ["normal", "picking", "delivering", "ended"],
                  )
                  .orderBy("orderTime", descending: true)
                  .snapshots(),
          builder: (c, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  "No orders found",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (c, index) {
                final orderData =
                    snapshot.data!.docs[index].data() as Map<String, dynamic>;
                final productIDs =
                    orderData["productIDs"] as List<dynamic>? ?? [];
                final orderStatus = orderData["status"] as String? ?? "normal";
                final orderTime = orderData["orderTime"] as String? ?? "";
                final sellerUID = orderData["sellerUID"] as String? ?? "";

                if (productIDs.isEmpty) {
                  return const SizedBox.shrink();
                }

                return FutureBuilder<QuerySnapshot>(
                  future:
                      FirebaseFirestore.instance
                          .collection("items")
                          .where(
                            "itemID",
                            whereIn: separateOrdesItemIDs(productIDs),
                          )
                          .get(),
                  builder: (c, snap) {
                    if (snap.hasError) {
                      return Center(
                        child: Text(
                          "Error loading items: ${snap.error}",
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snap.data!.docs.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      children: [
                        OrderCard(
                          itemCount: snap.data!.docs.length,
                          data: snap.data!.docs,
                          orderID: snapshot.data!.docs[index].id,
                          seperateQuantitiesList: separateOrderItemQuantities(
                            productIDs,
                          ),
                          sellerUID: sellerUID,
                          orderStatus: orderStatus,
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Order Status",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _buildStatusStep(
                                    "Order Placed",
                                    true,
                                    Icons.shopping_cart,
                                  ),
                                  _buildStatusLine(orderStatus != "normal"),
                                  _buildStatusStep(
                                    "Order Packed",
                                    orderStatus != "normal",
                                    Icons.inventory_2,
                                  ),
                                  _buildStatusLine(
                                    orderStatus == "picking" ||
                                        orderStatus == "delivering" ||
                                        orderStatus == "ended",
                                  ),
                                  _buildStatusStep(
                                    "Rider Picked",
                                    orderStatus == "picking" ||
                                        orderStatus == "delivering" ||
                                        orderStatus == "ended",
                                    Icons.delivery_dining,
                                  ),
                                  _buildStatusLine(
                                    orderStatus == "delivering" ||
                                        orderStatus == "ended",
                                  ),
                                  _buildStatusStep(
                                    "Delivered",
                                    orderStatus == "ended",
                                    Icons.check_circle,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (orderStatus == "delivering")
                                Text(
                                  "Your order is on the way!",
                                  style: GoogleFonts.poppins(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              if (orderStatus == "picking")
                                Text(
                                  "A rider is picking up your order",
                                  style: GoogleFonts.poppins(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              if (orderStatus == "ended")
                                Text(
                                  "Order delivered successfully!",
                                  style: GoogleFonts.poppins(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildStatusStep(String title, bool isCompleted, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isCompleted ? Colors.white : Colors.grey.shade600,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isCompleted ? Colors.green : Colors.grey.shade600,
              fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusLine(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        color: isCompleted ? Colors.green : Colors.grey.shade300,
      ),
    );
  }
}
