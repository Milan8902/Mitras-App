import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../assistantMethods/assistant_methods.dart';
import '../global/global.dart';
import '../widgets/order_card_design.dart';
import '../widgets/progress_bar.dart';

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
          "Delivery History",
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
          stream:
              FirebaseFirestore.instance
                  .collection("orders")
                  .where("sellerUID", isEqualTo: sellerUID)
                  .where("status", isEqualTo: "ended")
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
                        "No Delivery History",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Completed orders will appear here.",
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
                String buyerUID = orderData["orderBy"];

                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: FutureBuilder<QuerySnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection("items")
                            .where("itemID", whereIn: productIDs)
                            .where("sellerUID", isEqualTo: sellerUID)
                            .orderBy("publishedDate", descending: true)
                            .get(),
                    builder: (context, itemSnapshot) {
                      if (!itemSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final itemData = itemSnapshot.data!;
                      return OrderCardDesign(
                        itemCount: itemData.docs.length,
                        data: itemData.docs,
                        orderID: orders[index].id,
                        seperateQuantitiesList: quantities,
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
}
