import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:users_food_app/assistantMethods/assistant_methods.dart';
import 'package:users_food_app/global/global.dart';
import 'package:users_food_app/widgets/design/order_card_design.dart';
import 'package:users_food_app/widgets/progress_bar.dart';
import 'package:users_food_app/widgets/simple_app_bar.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: SimpleAppBar(title: "History"),
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
                  .where("status", isEqualTo: "received")
                  .orderBy("orderTime", descending: true)
                  .snapshots(),
          builder: (context, orderSnapshot) {
            if (!orderSnapshot.hasData) {
              return Center(child: circularProgress());
            }

            if (orderSnapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  "No order history yet.",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              );
            }

            return ListView.builder(
              itemCount: orderSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final orderData =
                    orderSnapshot.data!.docs[index].data()
                        as Map<String, dynamic>;
                final productIDs = orderData["productIDs"] as List<dynamic>? ?? [];
                final sellerUID = orderData["sellerUID"] as String? ?? "";
                final orderStatus = orderData["status"] as String? ?? "received";
                final orderTime = orderData["orderTime"] as String? ?? "";

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
                  builder: (context, itemSnapshot) {
                    if (!itemSnapshot.hasData) {
                      return Center(child: circularProgress());
                    }

                    if (itemSnapshot.data!.docs.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      children: [
                        // Order Card
                        OrderCard(
                          itemCount: itemSnapshot.data!.docs.length,
                          data: itemSnapshot.data!.docs,
                          orderID: orderSnapshot.data!.docs[index].id,
                          seperateQuantitiesList: separateOrderItemQuantities(
                            orderData["productIDs"],
                          ),
                          sellerUID: sellerUID,
                          orderStatus: orderStatus,
                        ),
                        // Order Details
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                "Order Details",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _buildDetailItem(
                                    "Order ID",
                                    orderSnapshot.data!.docs[index].id,
                                    Icons.receipt_long,
                                  ),
                                  const SizedBox(width: 16),
                                  _buildDetailItem(
                                    "Order Time",
                                    _formatOrderTime(orderTime),
                                    Icons.access_time,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildDetailItem(
                                    "Total Items",
                                    itemSnapshot.data!.docs.length.toString(),
                                    Icons.shopping_bag,
                                  ),
                                  const SizedBox(width: 16),
                                  _buildDetailItem(
                                    "Status",
                                    "Received",
                                    Icons.check_circle,
                                    isStatus: true,
                                  ),
                                ],
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

  Widget _buildDetailItem(String label, String value, IconData icon, {bool isStatus = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isStatus ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isStatus ? Colors.green : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isStatus ? Colors.green : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatOrderTime(String timestamp) {
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
      return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "Unknown time";
    }
  }
}
