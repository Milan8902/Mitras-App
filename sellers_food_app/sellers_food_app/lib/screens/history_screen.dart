import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../assistantMethods/assistant_methods.dart';
import '../global/global.dart';
import '../widgets/order_card_design.dart';
import '../widgets/progress_bar.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String? sellerUID = sharedPreferences?.getString("uid");

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Order History",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFFFFA726), const Color(0xFFF57C00)],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, const Color(0xFFFFF3E0).withOpacity(0.5)],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("orders")
              .where("sellerUID", isEqualTo: sellerUID)
              .where("status", isEqualTo: "received")
              .orderBy("orderTime", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: circularProgress(),
                ),
              );
            }

            final orders = snapshot.data!.docs;

            if (orders.isEmpty) {
              return Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_toggle_off,
                        size: 100,
                        color: const Color(0xFFFFA726).withOpacity(0.8),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "No Order History",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Completed and confirmed orders will appear here.",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final orderData = orders[index].data()! as Map<String, dynamic>;
                List<String> productIDs = extractItemIDs(
                  orderData["productIDs"],
                );
                List<String> quantities = extractQuantities(
                  orderData["productIDs"],
                );

                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: FutureBuilder<QuerySnapshot?>(
                    future: _getOrderItems(productIDs, sellerUID),
                    builder: (context, itemSnapshot) {
                      if (itemSnapshot.hasError) {
                        return _buildOrderCard(orderData, [], quantities);
                      }

                      if (!itemSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final itemData = itemSnapshot.data;
                      return _buildOrderCard(
                        orderData,
                        itemData?.docs ?? [],
                        quantities,
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<String> extractItemIDs(List<dynamic> productIDs) {
    return productIDs.skip(1).map((e) => e.toString().split(":")[0]).toList();
  }

  List<String> extractQuantities(List<dynamic> productIDs) {
    return productIDs.skip(1).map((e) => e.toString().split(":")[1]).toList();
  }

  Future<QuerySnapshot?> _getOrderItems(List<String> productIDs, String? sellerUID) async {
    if (productIDs.isEmpty || sellerUID == null) {
      // Skip the query if there are no product IDs
      return Future.value(null);
    }

    try {
      return await FirebaseFirestore.instance
          .collection("items")
          .where("itemID", whereIn: productIDs)
          .where("sellerUID", isEqualTo: sellerUID)
          .orderBy("publishedDate", descending: true)
          .get();
    } catch (e) {
      print("Error fetching order items: $e");
      return Future.value(null);
    }
  }

  Widget _buildOrderCard(
    Map<String, dynamic> orderData,
    List<QueryDocumentSnapshot> items,
    List<String> quantities,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderCardHeader(orderData),
          // Order Items
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Order Items:",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  Text(
                    "No items found",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  )
                else
                  ...items.asMap().entries.map((entry) {
                    final item = entry.value.data() as Map<String, dynamic>;
                    final quantity = quantities[entry.key];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "${item["title"]} x$quantity",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          Text(
                            "Rs. ${(double.parse(item["price"].toString()) * int.parse(quantity)).toStringAsFixed(2)}",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                const Divider(height: 24),
                // Order Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total Amount:",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      "Rs. ${orderData["totalAmount"]?.toString() ?? "0.00"}",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCardHeader(Map<String, dynamic> orderData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              Text(
                "Order Confirmed",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade800,
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
    );
  }
}
