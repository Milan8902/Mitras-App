import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
    // Log the current rider UID
    print("Rider UID: ${sharedPreferences!.getString("uid")}");
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFAC898), Color(0xFFFFE0B2)],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Colors.amber, Colors.orange]),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Delivery History',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Colors.amber, Colors.orange]),
              ),
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: FractionalOffset(-2.0, 0.0),
            end: FractionalOffset(5.0, -1.0),
            colors: [Color(0xFFFFFFFF), Color(0xFFFAC898)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery History',
                        style: GoogleFonts.pacifico(
                          fontSize: 28,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your completed deliveries',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search history...',
                          hintStyle: GoogleFonts.poppins(color: Colors.black54),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        style: GoogleFonts.poppins(color: Colors.black87),
                        onChanged: (value) {
                          // Add search logic here if needed
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Orders List
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection("orders")
                      .where(
                        "riderUID",
                        isEqualTo: sharedPreferences!.getString("uid"),
                      )
                      .where("status", isEqualTo: "ended")
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverToBoxAdapter(
                    child: Center(child: circularProgress()),
                  );
                }
                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Text(
                        "Error: ${snapshot.error}",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_outlined,
                            size: 80,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Delivery History',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No completed deliveries found.',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final orderDocs = snapshot.data!.docs;
                return SliverToBoxAdapter(
                  child: AnimationLimiter(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: orderDocs.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> orderData =
                            orderDocs[index].data()! as Map<String, dynamic>;
                        List<String> itemIDs = separateOrderItemIDs(
                          orderData["productIDs"],
                        );
                        if (itemIDs.isEmpty) {
                          return const SizedBox();
                        }
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 500),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: FutureBuilder<QuerySnapshot>(
                                  future:
                                      FirebaseFirestore.instance
                                          .collection("items")
                                          .where("itemID", whereIn: itemIDs)
                                          .orderBy(
                                            "publishedDate",
                                            descending: true,
                                          )
                                          .get(),
                                  builder: (context, itemsSnapshot) {
                                    if (itemsSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Center(child: circularProgress());
                                    }
                                    if (itemsSnapshot.hasError) {
                                      return Center(
                                        child: Text(
                                          "Error loading items: ${itemsSnapshot.error}",
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      );
                                    }
                                    if (!itemsSnapshot.hasData ||
                                        itemsSnapshot.data!.docs.isEmpty) {
                                      return Center(
                                        child: Text(
                                          "No item details found for this order.",
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      );
                                    }
                                    return Card(
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.amber.shade100,
                                              Colors.orange.shade100,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: OrderCard(
                                          itemCount:
                                              itemsSnapshot.data!.docs.length,
                                          data: itemsSnapshot.data!.docs,
                                          orderID: orderDocs[index].id,
                                          seperateQuantitiesList:
                                              separateOrderItemQuantities(
                                                orderData["productIDs"],
                                              ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
